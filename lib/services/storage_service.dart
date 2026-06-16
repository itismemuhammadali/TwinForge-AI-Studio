import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static void _log(String message) {
    developer.log('[StorageService] $message');
    print('[StorageService] $message'); 
  }

  /// Upload an image to Firebase Storage using direct data transfer to avoid retry loops
  static Future<String> uploadImage(File file, String path) async {
    try {
      final Uint8List data = await file.readAsBytes();
      final sizeInMb = data.lengthInBytes / (1024 * 1024);
      
      _log('🚀 Forcing Direct Data Upload...');
      _log('📦 Size: ${sizeInMb.toStringAsFixed(2)} MB');
      
      final ref = _storage.ref().child(path);
      
      // Use putData instead of putFile to bypass stream-based retry loops
      final uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      _log('🏁 Data Upload Finished.');
      
      final url = await snapshot.ref.getDownloadURL();
      _log('🔗 URL: $url');
      return url;
    } catch (e) {
      _log('❌ Storage Exception: $e');
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
      _log('⚠️ Deletion error: $e');
    }
  }
}
