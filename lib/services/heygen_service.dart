import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class HeyGenService {
  static late String apiKey;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      await _remoteConfig.fetchAndActivate();
      apiKey = _remoteConfig.getString('heygen_api_key');
      debugLog('📊 API Key value: ${apiKey.isNotEmpty ? "Found" : "Empty"}');
      if (apiKey.isEmpty) {
        throw Exception('HeyGen API key not configured in Firebase Remote Config.');
      }
      debugLog('✅ HeyGen API key loaded successfully');
    } catch (e) {
      debugLog('❌ Error initializing HeyGen Service: $e');
      rethrow;
    }
  }

  static void debugLog(String message) {
    developer.log('[HeyGenService] $message');
  }

  /// Create talking head video using HeyGen v3 Image-to-Video API
  /// Passes image URL and audio URL directly — no photo upload needed
  Future<String> createPhotoTalkingHeadVideo({
    required String imageUrl,
    required String audioUrl,
  }) async {
    try {
      debugLog('🎬 Creating talking head video with HeyGen v3 API...');
      debugLog('📸 Image: $imageUrl');
      debugLog('🔊 Audio: $audioUrl');

      final url = Uri.parse('https://api.heygen.com/v3/videos');

      final requestBody = {
        'type': 'image',
        'image': {
          'type': 'url',
          'url': imageUrl,
        },
        'audio_url': audioUrl,
        'title': 'Twinora Talking Head',
        'resolution': '1080p',
        'aspect_ratio': 'auto',
      };

      debugLog('📤 Sending request to HeyGen v3 API...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 180),
        onTimeout: () => throw Exception('HeyGen API request timeout after 180 seconds'),
      );

      debugLog('📥 Response status: ${response.statusCode}');
      debugLog('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final videoId = data['data']?['video_id'];
        if (videoId != null) {
          debugLog('✅ Video creation started: $videoId');
          return videoId.toString();
        }
        throw Exception('No video_id in response: ${response.body}');
      } else {
        throw Exception('HeyGen API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugLog('❌ Error creating video: $e');
      rethrow;
    }
  }

  /// Get video status using HeyGen v3 API
  Future<Map<String, dynamic>> getVideoStatus({
    required String videoId,
  }) async {
    try {
      debugLog('🔍 Checking video status: $videoId');

      final url = Uri.parse('https://api.heygen.com/v3/videos/$videoId');

      final response = await http.get(
        url,
        headers: {
          'x-api-key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('HeyGen status check timeout'),
      );

      debugLog('📥 Status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugLog('📊 Status: ${data['data']?['status']}');
        return data;
      } else {
        throw Exception('HeyGen status error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugLog('❌ Error checking status: $e');
      rethrow;
    }
  }
}
