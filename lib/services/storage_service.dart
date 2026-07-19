import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
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

  /// Upload a video to Firebase Storage
  static Future<String> uploadVideo(Uint8List data, String path) async {
    try {
      final sizeInMb = data.lengthInBytes / (1024 * 1024);
      
      _log('🚀 Uploading video...');
      _log('📦 Size: ${sizeInMb.toStringAsFixed(2)} MB');
      
      final ref = _storage.ref().child(path);
      
      final uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: 'video/mp4'),
      );

      final snapshot = await uploadTask;
      _log('🏁 Video upload finished.');
      
      final url = await snapshot.ref.getDownloadURL();
      _log('🔗 URL: $url');
      return url;
    } catch (e) {
      _log('❌ Video upload error: $e');
      rethrow;
    }
  }

  /// Download video from URL and upload to Firebase Storage
  static Future<String> downloadAndSaveVideo(String videoUrl, String path) async {
    try {
      _log('📥 Downloading video from: $videoUrl');
      
      final response = await http.get(Uri.parse(videoUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }
      
      final videoBytes = response.bodyBytes;
      _log('📦 Downloaded ${videoBytes.lengthInBytes / 1024 / 1024} MB');
      
      return await uploadVideo(videoBytes, path);
    } catch (e) {
      _log('❌ Download and save error: $e');
      rethrow;
    }
  }

  /// Upload image bytes to Firebase Storage
  static Future<String> uploadImageBytes(Uint8List data, String path) async {
    try {
      final sizeInMb = data.lengthInBytes / (1024 * 1024);
      _log('🚀 Uploading image bytes... ${sizeInMb.toStringAsFixed(2)} MB');

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      _log('🔗 Image URL: $url');
      return url;
    } catch (e) {
      _log('❌ Image bytes upload error: $e');
      rethrow;
    }
  }

  /// Upload audio bytes to Firebase Storage
  static Future<String> uploadAudioBytes(Uint8List data, String path) async {
    try {
      final sizeInKb = data.lengthInBytes / 1024;
      _log('🚀 Uploading audio bytes... ${sizeInKb.toStringAsFixed(1)} KB');

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data, SettableMetadata(contentType: 'audio/mpeg'));
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      _log('🔗 Audio URL: $url');
      return url;
    } catch (e) {
      _log('❌ Audio bytes upload error: $e');
      rethrow;
    }
  }
}
