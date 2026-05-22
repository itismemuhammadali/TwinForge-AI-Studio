import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ContentProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Map<String, dynamic>> _contentList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get contentList => _contentList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadUserContent(String uid) {
    _isLoading = true;
    notifyListeners();

    _firebaseService.getUserContent(uid).listen(
      (snapshot) {
        _contentList = snapshot.docs
            .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
            .toList();
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

  Future<bool> saveContent(String uid, Map<String, dynamic> content) async {
    try {
      await _firebaseService.saveGeneratedContent(uid, content);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContent(String uid, String contentId) async {
    try {
      await _firebaseService.deleteContent(uid, contentId);
      _contentList.removeWhere((item) => item['id'] == contentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
