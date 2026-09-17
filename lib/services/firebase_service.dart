import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase already initialized, ignore the error
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
  }

  // Auth Methods
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Permanently deletes all generated content, library items, notifications,
  /// and activity records for a user while preserving their initial sign-up profile.
  Future<void> deleteUserData(String uid) async {
    // 1. Delete all subcollections under users/{uid}
    final subcollections = ['content', 'generatedImages', 'library', 'notifications'];
    for (final sub in subcollections) {
      try {
        final snap = await _firestore.collection('users').doc(uid).collection(sub).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        // Continue cleaning other collections if one fails
      }
    }

    // 2. Delete from top-level collections associated with this user
    final topLevelQueries = [
      _firestore.collection('usage_logs').where('uid', isEqualTo: uid),
      _firestore.collection('usage_logs').where('userId', isEqualTo: uid),
      _firestore.collection('generated_manifestations').where('userId', isEqualTo: uid),
      _firestore.collection('generated_manifestations').where('uid', isEqualTo: uid),
      _firestore.collection('generated_magazines').where('userId', isEqualTo: uid),
      _firestore.collection('generated_magazines').where('uid', isEqualTo: uid),
      _firestore.collection('generated_holiday').where('userId', isEqualTo: uid),
      _firestore.collection('generated_holiday').where('uid', isEqualTo: uid),
    ];

    for (final query in topLevelQueries) {
      try {
        final snap = await query.get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }

    // 3. Reset user profile document while strictly keeping initial signup details
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': data['email'] ?? '',
        'name': data['name'] ?? data['displayName'] ?? 'User',
        'displayName': data['displayName'] ?? data['name'] ?? 'User',
        'gender': data['gender'] ?? 'Female',
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'credits': 0,
        'imagesUsedToday': 0,
        'subscription': 'free_trial',
        'profileImage': '',
        'bio': '',
      });
    } catch (_) {}
  }

  /// Permanently deletes all user data and the Firebase Auth account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      // Wipe all user data and collections first
      await deleteUserData(uid);
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (_) {}
      // Delete the Firebase Auth user record
      await user.delete();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore Methods
  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Content Library
  Future<void> saveGeneratedContent(String uid, Map<String, dynamic> content) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('content')
        .add({
      ...content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserContent(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('content')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteContent(String uid, String contentId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('content')
        .doc(contentId)
        .delete();
  }
}
