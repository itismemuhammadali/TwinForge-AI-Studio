import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/credit_config.dart';

class IapService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isLoading = false;
  List<ProductDetails> _products = [];
  String? _errorMessage;
  int? _lastPurchasedCredits;

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;
  String? get errorMessage => _errorMessage;
  int? get lastPurchasedCredits => _lastPurchasedCredits;

  void clearLastPurchasedCredits() {
    _lastPurchasedCredits = null;
  }

  IapService() {
    _initialize();
  }

  void _initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseDetails,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          _errorMessage = 'In-App Purchase Stream Error: $error';
          notifyListeners();
        },
      );
      await loadProducts();
    } else {
      _errorMessage = 'Store billing is unavailable on this device.';
      notifyListeners();
    }
  }

  /// Query registered Product IDs from Apple / Google stores
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(CreditConfig.allProductIds);
      if (response.error != null) {
        _errorMessage = response.error!.message;
      }
      _products = response.productDetails;
      debugPrint('🛒 Loaded ${_products.length} products from store.');
    } catch (e) {
      _errorMessage = 'Failed to load store products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Find ProductDetails by Product ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      if (productId == CreditConfig.subPlus) {
        try {
          return _products.firstWhere((p) => p.id == CreditConfig.subPlusAlt);
        } catch (_) {}
      } else if (productId == CreditConfig.subPlusAlt) {
        try {
          return _products.firstWhere((p) => p.id == CreditConfig.subPlus);
        } catch (_) {}
      }
      return null;
    }
  }

  /// Get localized price for a product ID (fallback to spec default if store not connected yet)
  String getLocalizedPrice(String productId, String fallbackPrice) {
    final p = getProduct(productId);
    return p != null ? p.price : fallbackPrice;
  }

  /// Purchase auto-renewable subscription or consumable via StoreKit / Google Play Billing
  Future<bool> buyProduct(String productId) async {
    final product = getProduct(productId);
    if (product == null) {
      _errorMessage =
          'Store product is currently unavailable. Please verify your internet connection and App Store / Google Play account.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      final bool launched;
      if (CreditConfig.subscriptionCreditsMap.containsKey(productId)) {
        launched = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        launched = await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
      }

      if (!launched) {
        _isLoading = false;
        _errorMessage = 'Could not launch store purchase sheet. Please try again.';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Purchase failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Restore Purchases (required for iOS App Store Review)
  Future<void> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = 'Failed to restore purchases: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle incoming purchase stream updates from StoreKit / Google Play
  Future<void> _onPurchaseDetails(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _isLoading = false;
          final error = purchaseDetails.error;
          final code = error?.code.toLowerCase() ?? '';
          final message = error?.message.toLowerCase() ?? '';
          // Cleanly handle voluntary cancellations without red alert
          if (code.contains('cancel') || message.contains('cancel')) {
            _errorMessage = null;
          } else {
            _errorMessage = error?.message ?? 'Purchase error occurred.';
          }
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _grantPurchaseCredits(purchaseDetails);
          _isLoading = false;
          notifyListeners();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Grant credits and update subscription tier in Firestore upon successful purchase
  Future<void> _grantPurchaseCredits(PurchaseDetails purchaseDetails) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ Cannot grant purchase credits: No authenticated user.');
      return;
    }

    final productId = purchaseDetails.productID;
    final txId = purchaseDetails.purchaseID;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final purchasesCol = FirebaseFirestore.instance.collection('purchases');

    try {
      // Idempotency check: prevent duplicate credit granting on restored purchases
      if (txId != null && txId.isNotEmpty) {
        final existingDoc = await purchasesCol.doc(txId).get();
        if (existingDoc.exists) {
          debugPrint('ℹ️ Transaction $txId was already processed. Skipping duplicate credit grant.');
          // Ensure active subscription tier on user doc is maintained
          if (CreditConfig.subscriptionCreditsMap.containsKey(productId)) {
            final planName = productId.replaceAll('twinora_', '');
            await userRef.set({
              'subscription': planName,
            }, SetOptions(merge: true));
          }
          return;
        }
      }

      if (CreditConfig.subscriptionCreditsMap.containsKey(productId)) {
        final creditsToAdd = CreditConfig.subscriptionCreditsMap[productId] ?? 600;
        final planName = productId.replaceAll('twinora_', '');

        await userRef.set({
          'credits': FieldValue.increment(creditsToAdd),
          'subscription': planName,
          'lastSubscribedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Record transaction document with txId as key
        final docRef = (txId != null && txId.isNotEmpty) ? purchasesCol.doc(txId) : purchasesCol.doc();
        await docRef.set({
          'uid': uid,
          'productId': productId,
          'type': 'subscription',
          'creditsAdded': creditsToAdd,
          'transactionId': txId ?? docRef.id,
          'status': purchaseDetails.status.name,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _lastPurchasedCredits = creditsToAdd;
        debugPrint('✅ Granted $creditsToAdd subscription credits for $planName ($txId)');
      } else if (CreditConfig.topUpCreditsMap.containsKey(productId)) {
        final creditsToAdd = CreditConfig.topUpCreditsMap[productId] ?? 250;

        await userRef.set({
          'credits': FieldValue.increment(creditsToAdd),
        }, SetOptions(merge: true));

        // Record transaction document with txId as key
        final docRef = (txId != null && txId.isNotEmpty) ? purchasesCol.doc(txId) : purchasesCol.doc();
        await docRef.set({
          'uid': uid,
          'productId': productId,
          'type': 'topup',
          'creditsAdded': creditsToAdd,
          'transactionId': txId ?? docRef.id,
          'status': purchaseDetails.status.name,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _lastPurchasedCredits = creditsToAdd;
        debugPrint('✅ Granted $creditsToAdd top-up credits ($txId)');
      }
    } catch (e) {
      debugPrint('❌ Error granting purchase credits: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
