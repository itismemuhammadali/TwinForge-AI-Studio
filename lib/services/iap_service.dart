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
          try {
            await _grantPurchaseCredits(purchaseDetails);
            _errorMessage = null;
            _isLoading = false;
            notifyListeners();

            // Crucial: Only finalize purchase with the store AFTER user credits are securely written
            if (purchaseDetails.pendingCompletePurchase) {
              await _iap.completePurchase(purchaseDetails);
            }
          } catch (e) {
            _isLoading = false;
            _errorMessage = 'Could not sync credits to account: $e. Please tap Restore Purchases or reopen the app.';
            notifyListeners();
            // Do NOT complete purchase if credit grant failed, allowing store retry
            continue;
          }
        }

        if (purchaseDetails.pendingCompletePurchase &&
            purchaseDetails.status != PurchaseStatus.purchased &&
            purchaseDetails.status != PurchaseStatus.restored) {
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
      throw Exception('User is not authenticated.');
    }

    final rawProductId = purchaseDetails.productID;
    // Strip Google Play base plan / offer ID suffixes (e.g. "twinora_starter_27:p1m" -> "twinora_starter_27")
    final productId = rawProductId.split(':').first.trim().toLowerCase();
    final txId = purchaseDetails.purchaseID;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final purchasesCol = FirebaseFirestore.instance.collection('purchases');

    // 1. Resolve credit amount and subscription plan with robust fallback matching
    int creditsToAdd = 0;
    String? subscriptionPlan;
    bool isSubscription = false;

    if (CreditConfig.subscriptionCreditsMap.containsKey(productId)) {
      creditsToAdd = CreditConfig.subscriptionCreditsMap[productId]!;
      subscriptionPlan = productId.replaceAll('twinora_', '');
      isSubscription = true;
    } else if (productId == CreditConfig.subPlusAlt || productId == 'twinora_plus_47') {
      creditsToAdd = 1200;
      subscriptionPlan = 'plus';
      isSubscription = true;
    } else if (CreditConfig.topUpCreditsMap.containsKey(productId)) {
      creditsToAdd = CreditConfig.topUpCreditsMap[productId]!;
      subscriptionPlan = null;
      isSubscription = false;
    } else {
      // Fuzzy fallback for store product IDs (handles store variants across iOS & Android)
      if (productId.contains('starter')) {
        creditsToAdd = 600;
        subscriptionPlan = 'starter';
        isSubscription = true;
      } else if (productId.contains('plus')) {
        creditsToAdd = 1200;
        subscriptionPlan = 'plus';
        isSubscription = true;
      } else if (productId.contains('pro')) {
        creditsToAdd = 3000;
        subscriptionPlan = 'pro';
        isSubscription = true;
      } else if (productId.contains('business')) {
        creditsToAdd = 6000;
        subscriptionPlan = 'business';
        isSubscription = true;
      } else if (productId.contains('4000')) {
        creditsToAdd = 4000;
      } else if (productId.contains('2000')) {
        creditsToAdd = 2000;
      } else if (productId.contains('1000')) {
        creditsToAdd = 1000;
      } else if (productId.contains('500')) {
        creditsToAdd = 500;
      } else if (productId.contains('250')) {
        creditsToAdd = 250;
      } else {
        debugPrint('⚠️ Unrecognized product ID: $productId (raw: $rawProductId)');
        return;
      }
    }

    // 2. Safe idempotency check (isolated in try/catch so rule/read errors never block credits)
    bool alreadyProcessed = false;
    if (txId != null && txId.isNotEmpty) {
      try {
        final existingDoc = await purchasesCol.doc(txId).get();
        if (existingDoc.exists) {
          final data = existingDoc.data();
          if (data != null && data['status'] == 'completed') {
            alreadyProcessed = true;
            debugPrint('ℹ️ Transaction $txId was already processed.');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Non-fatal idempotency check warning: $e');
      }
    }

    if (alreadyProcessed) {
      // Ensure user subscription status is kept in sync even if duplicate event
      if (isSubscription && subscriptionPlan != null) {
        try {
          await userRef.set({
            'subscription': subscriptionPlan,
          }, SetOptions(merge: true));
        } catch (_) {}
      }
      return;
    }

    // 3. PRIMARY ACTION: Credit the user's account in Firestore
    try {
      final Map<String, dynamic> updateData = {
        'credits': FieldValue.increment(creditsToAdd),
        'lastCreditUpdate': FieldValue.serverTimestamp(),
      };
      if (isSubscription && subscriptionPlan != null) {
        updateData['subscription'] = subscriptionPlan;
        updateData['lastSubscribedAt'] = FieldValue.serverTimestamp();
      }

      await userRef.set(updateData, SetOptions(merge: true));
      _lastPurchasedCredits = creditsToAdd;
      debugPrint('✅ Granted $creditsToAdd credits to user $uid (Plan: $subscriptionPlan, tx: $txId)');
    } catch (e) {
      debugPrint('❌ Failed to update user credits in Firestore: $e');
      rethrow;
    }

    // 4. SECONDARY ACTION: Record transaction record in purchases collection (non-blocking)
    try {
      final docRef = (txId != null && txId.isNotEmpty) ? purchasesCol.doc(txId) : purchasesCol.doc();
      await docRef.set({
        'uid': uid,
        'productId': productId,
        'rawProductId': rawProductId,
        'type': isSubscription ? 'subscription' : 'topup',
        'creditsAdded': creditsToAdd,
        'subscriptionPlan': subscriptionPlan,
        'transactionId': txId ?? docRef.id,
        'status': 'completed',
        'storeStatus': purchaseDetails.status.name,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (logErr) {
      debugPrint('⚠️ Non-fatal: Failed to log purchase record: $logErr');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
