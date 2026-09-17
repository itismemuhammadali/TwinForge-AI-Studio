import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;
  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((user) async {
      _currentUser = user;
      if (user != null) {
        await _checkAdminRole(user.uid);
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkAdminRole(String uid) async {
    try {
      final profile = await _firebaseService.getUserProfile(uid);
      _isAdmin = profile?['role'] == 'admin';
    } catch (_) {
      _isAdmin = false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName, String gender) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.signUp(email, password).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Connection timeout. Please check your internet or Firebase configuration.'),
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      // Create user profile in Firestore with gender
      try {
        await _firebaseService.createUserProfile(userCredential.user!.uid, {
          'uid': userCredential.user!.uid,
          'email': email,
          'name': displayName,
          'displayName': displayName,
          'gender': gender,
          'createdAt': DateTime.now().toIso8601String(),
          'credits': 4,              // Free trial: 4 image generations
          'totalCredits': 4,
          'subscription': 'free_trial',
          'imagesUsedToday': 0,
          'usageDate': DateTime.now().toIso8601String().split('T')[0],
        }).timeout(const Duration(seconds: 15));
      } catch (firestoreError) {
        debugPrint('Firestore: Profile creation failed: $firestoreError');
        // Firestore write failed but auth succeeded — not fatal, continue
      }

      // Send verification email
      try {
        await userCredential.user?.sendEmailVerification().timeout(const Duration(seconds: 10));
      } catch (_) {}
      
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Sign up failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().contains('timeout')
          ? 'Connection timed out. Please try again.'
          : 'Sign up failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.signIn(email, password).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Connection timeout. Please check your internet or Firebase configuration.'),
      );
      _currentUser = userCredential.user;
      await _checkAdminRole(userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();

      // Save FCM token after login
      try {
        await FCMService().onUserLogin().timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('FCM: Token update failed: $e');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          (e.message != null && (e.message!.contains('user-not-found') || e.message!.contains('no user record')))) {
        _errorMessage = 'This account does not exist anymore. Please sign up or check your credentials.';
      } else {
        _errorMessage = e.message ?? 'Sign in failed';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().contains('timeout') 
          ? 'Connection timed out. Please try again.' 
          : 'Sign in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.sendPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Password reset failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await FCMService().onUserLogout();
    await _firebaseService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Permanently deletes all generated content, library items, notifications,
  /// and activity history for the current user while preserving their login account.
  Future<bool> deleteUserData() async {
    final uid = _currentUser?.uid;
    if (uid == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.deleteUserData(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete user data: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Permanently deletes the account and all associated data.
  Future<bool> deleteAccount() async {
    try {
      await FCMService().onUserLogout();
      await _firebaseService.deleteAccount();
      _currentUser = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _errorMessage = 'requires-recent-login';
      } else {
        _errorMessage = e.message ?? 'Failed to delete account';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> sendEmailVerification() async {
    await _firebaseService.sendEmailVerification();
  }
}
