import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class HeyGenService {
  static late String apiKey;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize HeyGen Service with API key from Firebase Remote Config
  static Future<void> initialize() async {
    try {
      // Fetch remote config WITHOUT setting defaults (to preserve existing values)
      await _remoteConfig.fetchAndActivate();

      // Get API key from remote config
      apiKey = _remoteConfig.getString('heygen_api_key');

      debugLog('🔍 Fetching heygen_api_key from Remote Config...');
      debugLog('📊 API Key value: ${apiKey.isNotEmpty ? "✅ Found" : "❌ Empty"}');
      debugLog('📊 API Key length: ${apiKey.length} characters');

      if (apiKey.isEmpty) {
        throw Exception('HeyGen API key not configured in Firebase Remote Config. Please add "heygen_api_key" parameter in Firebase Console.');
      }

      debugLog('✅ HeyGen API key loaded successfully from Firebase Remote Config');
    } catch (e) {
      debugLog('❌ Error initializing HeyGen Service: $e');
      rethrow;
    }
  }

  /// Debug logging helper
  static void debugLog(String message) {
    developer.log('[HeyGenService] $message');
  }

  /// Create talking head video from image
  Future<String> createTalkingHeadVideo({
    required String imageUrl,
    required String scriptText,
    required String avatarId,
    required String voiceId,
  }) async {
    try {
      debugLog('🎬 Starting talking head video creation...');
      debugLog('📸 Image: $imageUrl, Avatar: $avatarId');

      final url = Uri.parse('https://api.heygen.com/v1/video/generate');

      final requestBody = {
        'video_inputs': [
          {
            'character': {
              'type': 'avatar',
              'avatar_id': avatarId,
            },
            'voice': {
              'type': 'text',
              'input_text': scriptText,
              'voice_id': voiceId,
            },
            'background': {
              'type': 'image',
              'image_url': imageUrl,
            },
          }
        ],
      };

      debugLog('📤 Sending talking head request to HeyGen API...');
      debugLog('📊 Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': apiKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw Exception('HeyGen API request timeout after 180 seconds');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugLog('✅ Response data: ${jsonEncode(data)}');

        if (data['video_id'] != null) {
          final videoId = data['video_id'];
          debugLog('✅ Talking head video created successfully: $videoId');
          return videoId;
        } else {
          throw Exception('No video ID in response: ${jsonEncode(data)}');
        }
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('HeyGen API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in createTalkingHeadVideo: $e');
      rethrow;
    }
  }

  /// Get video status and download URL
  Future<Map<String, dynamic>> getVideoStatus({
    required String videoId,
  }) async {
    try {
      debugLog('🔍 Checking video status: $videoId');

      final url = Uri.parse('https://api.heygen.com/v1/video/$videoId');

      final response = await http.get(
        url,
        headers: {
          'X-Api-Key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('HeyGen API request timeout');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugLog('✅ Video status: ${data['status']}');
        return data;
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('HeyGen API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in getVideoStatus: $e');
      rethrow;
    }
  }

  /// List available avatars
  Future<List<Map<String, dynamic>>> listAvatars() async {
    try {
      debugLog('👥 Fetching available avatars...');

      final url = Uri.parse('https://api.heygen.com/v1/avatars');

      final response = await http.get(
        url,
        headers: {
          'X-Api-Key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('HeyGen API request timeout');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final avatars = List<Map<String, dynamic>>.from(data['avatars'] ?? []);
        debugLog('✅ Found ${avatars.length} avatars');
        return avatars;
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('HeyGen API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in listAvatars: $e');
      rethrow;
    }
  }

  /// Check API key validity
  static Future<bool> verifyApiKey() async {
    try {
      debugLog('🔐 Verifying HeyGen API key...');

      final url = Uri.parse('https://api.heygen.com/v1/user/info');

      final response = await http.get(
        url,
        headers: {
          'X-Api-Key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API verification timeout');
        },
      );

      if (response.statusCode == 200) {
        debugLog('✅ HeyGen API key is valid');
        return true;
      } else {
        debugLog('❌ HeyGen API key verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugLog('❌ Error verifying API key: $e');
      return false;
    }
  }
}
