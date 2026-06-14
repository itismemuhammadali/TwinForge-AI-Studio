import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static void _log(String message) {
    developer.log('[StorageService] $message');
  }

  /// Upload an image to Firebase Storage and return the download URL
  static Future<String> uploadImage(File file, String path) async {
    try {
      _log('📤 Uploading image to: $path');
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final url = await uploadTask.ref.getDownloadURL();
      _log('✅ Upload successful. URL: $url');
      return url;
    } catch (e) {
      _log('❌ Upload error: $e');
      rethrow;
    }
  }

  /// Delete an image from Firebase Storage
  static Future<void> deleteImage(String url) async {
    try {
      _log('🗑️ Deleting image: $url');
      final ref = _storage.refFromURL(url);
      await ref.delete();
      _log('✅ Deletion successful');
    } catch (e) {
      _log('⚠️ Deletion error (might already be gone): $e');
    }
  }
}
