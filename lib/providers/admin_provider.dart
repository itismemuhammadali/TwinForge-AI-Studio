import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminContent {
  final String id;
  final String imageUrl;
  final String category;
  final String? prompt;
  final DateTime createdAt;
  final String uploadedBy;

  AdminContent({
    required this.id,
    required this.imageUrl,
    required this.category,
    this.prompt,
    required this.createdAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imageUrl': imageUrl,
        'category': category,
        'prompt': prompt,
        'createdAt': createdAt.toIso8601String(),
        'uploadedBy': uploadedBy,
      };

  factory AdminContent.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    DateTime created;
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is String) {
      created = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return AdminContent(
      id: map['id'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      prompt: map['prompt'],
      createdAt: created,
      uploadedBy: map['uploadedBy'] ?? '',
    );
  }
}

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<AdminContent> _contentList = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  List<AdminContent> get contentList => _contentList;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  static const List<String> categories = [
    'Podcast',
    'Trending',
    'B-Roll',
    'Carousel',
    'Luxury Lifestyle',
    'Luxury Office',
    'Luxury Car',
    'Seaside Work',
  ];

  void loadAdminContent() {
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('admin_content')
        .snapshots()
        .listen(
      (snapshot) {
        _contentList = snapshot.docs
            .map((doc) => AdminContent.fromMap({'id': doc.id, ...doc.data()}))
            .toList();
        _contentList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> uploadContent({
    required File imageFile,
    required String category,
    String? prompt,
    required String uploadedBy,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'admin_content/${category.toLowerCase()}/$timestamp.jpg';

      final ref = _storage.ref().child(fileName);
      final data = await imageFile.readAsBytes();
      final uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('admin_content').add({
        'imageUrl': imageUrl,
        'category': category,
        'prompt': prompt,
        'createdAt': FieldValue.serverTimestamp(),
        'uploadedBy': uploadedBy,
      });

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Upload failed: $e';
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContent(String contentId) async {
    try {
      await _firestore.collection('admin_content').doc(contentId).delete();
      return true;
    } catch (e) {
      _errorMessage = 'Delete failed: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getContentByCategory(String category) {
    return _firestore
        .collection('admin_content')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}
