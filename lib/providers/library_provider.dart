import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

/// Provider that manages in-memory caching of user's library items (Images, Carousels, Videos).
/// Prevents repetitive Firestore queries and eliminates loading flicker on navigation.
class LibraryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _subscription;
  String? _activeUid;

  List<Map<String, dynamic>> _allDocs = [];
  List<Map<String, dynamic>> _imageDocs = [];
  List<Map<String, dynamic>> _carouselDocs = [];
  List<Map<String, dynamic>> _videoDocs = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get allDocs => List.unmodifiable(_allDocs);
  List<Map<String, dynamic>> get imageDocs => List.unmodifiable(_imageDocs);
  List<Map<String, dynamic>> get carouselDocs => List.unmodifiable(_carouselDocs);
  List<Map<String, dynamic>> get videoDocs => List.unmodifiable(_videoDocs);

  LibraryProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        if (_activeUid != user.uid) {
          _initListener(user.uid);
        }
      } else {
        _clear();
      }
    });
  }

  void _clear() {
    _subscription?.cancel();
    _subscription = null;
    _activeUid = null;
    _allDocs = [];
    _imageDocs = [];
    _carouselDocs = [];
    _videoDocs = [];
    _isLoading = true;
    notifyListeners();
  }

  void refresh() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _initListener(uid);
    }
  }

  void _initListener(String uid) {
    _subscription?.cancel();
    _activeUid = uid;

    final contentStream = _firestore.collection('users').doc(uid).collection('content').snapshots();
    final imagesStream = _firestore.collection('users').doc(uid).collection('generatedImages').snapshots();

    _subscription = Rx.combineLatest2(contentStream, imagesStream, (a, b) => [a, b]).listen((snapshots) {
      final List<Map<String, dynamic>> rawList = [];

      for (var snap in snapshots) {
        for (var doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['docId'] = doc.id;

          final type = (data['type'] as String? ?? 'image').toLowerCase();
          if (data['imageUrl'] == null) {
            if (type == 'video') {
              data['imageUrl'] = data['editedImageUrl'] ?? data['videoUrl'];
            } else if (data['originalImageUrl'] != null) {
              data['imageUrl'] = data['originalImageUrl'];
            }
          }
          rawList.add(data);
        }
      }

      // Sort by createdAt descending
      rawList.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      _allDocs = rawList;

      _imageDocs = rawList.where((d) {
        final type = (d['type'] as String? ?? 'image').toLowerCase();
        final videoUrl = d['videoUrl'] as String?;
        return type == 'image' && (videoUrl == null || videoUrl.isEmpty);
      }).toList();

      _carouselDocs = rawList.where((d) {
        final type = (d['type'] as String? ?? '').toLowerCase();
        return type == 'carousel';
      }).toList();

      _videoDocs = rawList.where((d) {
        final type = (d['type'] as String? ?? '').toLowerCase();
        final videoUrl = d['videoUrl'] as String?;
        return type == 'video' || (videoUrl != null && videoUrl.isNotEmpty);
      }).toList();

      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('LibraryProvider listener error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
