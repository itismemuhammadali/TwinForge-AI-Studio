import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password, String displayName, String gender) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseService.signUp(email, password);
      
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
        });
      } catch (firestoreError) {
        // Firestore write failed but auth succeeded — not fatal, continue
      }

      // Send verification email directly on the new user object
      try {
        await userCredential.user?.sendEmailVerification();
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
      _errorMessage = 'Sign up failed. Please try again.';
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
      final userCredential = await _firebaseService.signIn(email, password);
      _currentUser = userCredential.user;
      _isLoading = false;
      notifyListeners();

      // Save FCM token after login
      await FCMService().onUserLogin();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Sign in failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Sign in failed. Please try again.';
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

  Future<void> sendEmailVerification() async {
    await _firebaseService.sendEmailVerification();
  }
}
