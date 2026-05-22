import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userGender;
  String? _displayName;
  String? _email;
  String? _bio;
  String? _profileImageUrl;
  String? _subscription;
  int? _credits;
  int? _imagesUsedToday;
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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _userGender = null;
        _displayName = null;
        _email = null;
        _bio = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
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
      } else {
        _userGender = 'Female';
        _displayName = _auth.currentUser?.displayName ?? 'User';
        _email = _auth.currentUser?.email ?? '';
        _bio = '';
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch user data: $e';
      _userGender = 'Female';
      _displayName = _auth.currentUser?.displayName ?? 'User';
      _email = _auth.currentUser?.email ?? '';
      _bio = '';
      _isLoading = false;
      notifyListeners();
    }
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
}
