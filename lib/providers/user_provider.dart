import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  String? _userGender;
  String? _displayName;
  String? _email;
  String? _bio;
  String? _profileImageUrl;
  String? _subscription;
  int? _credits;
  int? _imagesUsedToday;
  bool _aiDataConsentGranted = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? get userGender => _userGender;
  String? get displayName => _displayName;
  String? get email => _email;
  String? get bio => _bio;
  String? get profileImageUrl => _profileImageUrl;
  String? get subscription => _subscription;
  int? get credits => _credits;
  int? get imagesUsedToday => _imagesUsedToday;
  bool get aiDataConsentGranted => _aiDataConsentGranted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      _userDocSubscription?.cancel();
      if (user != null) {
        _listenToUserData(user.uid);
      } else {
        _userGender = null;
        _displayName = null;
        _email = null;
        _bio = null;
        _profileImageUrl = null;
        _subscription = null;
        _credits = null;
        _imagesUsedToday = null;
        _aiDataConsentGranted = false;
        notifyListeners();
      }
    });
  }

  void _listenToUserData(String uid) {
    if (_displayName == null) {
      _isLoading = true;
    }
    _errorMessage = null;

    _userDocSubscription = _firestore.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        _userGender = data?['gender'] ?? 'Female';
        _displayName = data?['displayName'] ?? _auth.currentUser?.displayName ?? 'User';
        _email = data?['email'] ?? _auth.currentUser?.email ?? '';
        _bio = data?['bio'] ?? '';
        _profileImageUrl = data?['profileImage'] ?? '';
        _subscription = data?['subscription'] ?? 'free_trial';
        _credits = data?['credits'] as int? ?? 0;
        _imagesUsedToday = data?['imagesUsedToday'] as int? ?? 0;
        _aiDataConsentGranted = data?['aiDataConsentGranted'] as bool? ?? false;
      } else {
        _userGender = 'Female';
        _displayName = _auth.currentUser?.displayName ?? 'User';
        _email = _auth.currentUser?.email ?? '';
        _bio = '';
        _subscription = 'free_trial';
        _credits = 0;
        _aiDataConsentGranted = false;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Failed to fetch user data: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> setAiDataConsent(bool granted) async {
    _aiDataConsentGranted = granted;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'aiDataConsentGranted': granted,
          'aiDataConsentTimestamp': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error writing AI consent to Firestore: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_data_consent_granted', granted);
    } catch (_) {}
  }

  Future<void> fetchUserData(String uid) async {
    _listenToUserData(uid);
  }

  void updateProfileImageUrl(String url) {
    _profileImageUrl = url;
    notifyListeners();
  }

  Future<void> refreshCredits() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _credits = doc.data()?['credits'] as int? ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Deduct credits safely. Allows credits to go below 0.
  Future<bool> deductCredits(int amount) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final current = _credits ?? 0;
    final newCredits = current - amount;

    try {
      await _firestore.collection('users').doc(uid).update({
        'credits': newCredits,
        'imagesUsedToday': FieldValue.increment(amount),
        'usageDate': DateTime.now().toIso8601String().split('T')[0],
      });
      _credits = newCredits;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deducting credits: $e');
      return false;
    }
  }

  Future<void> updateUserGender(String gender) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'gender': gender,
      });
      _userGender = gender;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update gender: $e';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String displayName,
    required String email,
    required String bio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _displayName = displayName;
      _email = email;
      _bio = bio;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
