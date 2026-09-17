import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static void _log(String message) {
    developer.log('[StorageService] $message');
    // print('[StorageService] $message'); 
  }

  static String detectImageContentType(Uint8List data) {
    if (data.length >= 4 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return 'image/png';
    }
    if (data.length >= 3 &&
        data[0] == 0xFF &&
        data[1] == 0xD8 &&
        data[2] == 0xFF) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }

  static String fixImagePathExtension(String path, String contentType) {
    if (contentType == 'image/png') {
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return path.replaceAll(RegExp(r'\.jpe?g$', caseSensitive: false), '.png');
      }
    } else if (contentType == 'image/jpeg') {
      if (path.endsWith('.png')) {
        return path.replaceAll(RegExp(r'\.png$', caseSensitive: false), '.jpg');
      }
    }
    return path;
  }

  /// Upload an image to Firebase Storage using direct data transfer to avoid retry loops
  static Future<String> uploadImage(File file, String path) async {
    try {
      final Uint8List data = await file.readAsBytes();
      return await uploadImageBytes(data, path);
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
      final contentType = detectImageContentType(data);
      final finalPath = fixImagePathExtension(path, contentType);
      _log('🚀 Uploading image bytes... ${sizeInMb.toStringAsFixed(2)} MB ($contentType -> $finalPath)');

      final ref = _storage.ref().child(finalPath);
      final uploadTask = ref.putData(data, SettableMetadata(contentType: contentType));
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

  /// Download video from URL and upload to Firebase Storage
  static Future<String> uploadVideoFromUrl(String videoUrl, String path) async {
    try {
      _log('📥 Downloading video from: $videoUrl');

      final response = await http.get(Uri.parse(videoUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      final videoBytes = response.bodyBytes;
      _log('📦 Downloaded ${(videoBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB');

      return await uploadVideo(videoBytes, path);
    } catch (e) {
      _log('❌ Upload from URL error: $e');
      rethrow;
    }
  }
}
