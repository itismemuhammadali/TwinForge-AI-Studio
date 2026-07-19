import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class ElevenLabsService {
  static late String apiKey;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize 11 Labs Service with API key from Firebase Remote Config
  static Future<void> initialize() async {
    try {
      // Fetch remote config WITHOUT setting defaults (to preserve existing values)
      await _remoteConfig.fetchAndActivate();

      // Get API key from remote config
      apiKey = _remoteConfig.getString('eleven_labs_api_key');

      debugLog('🔍 Fetching eleven_labs_api_key from Remote Config...');
      debugLog('📊 API Key value: ${apiKey.isNotEmpty ? "✅ Found" : "❌ Empty"}');
      debugLog('📊 API Key length: ${apiKey.length} characters');

      if (apiKey.isEmpty) {
        throw Exception('11 Labs API key not configured in Firebase Remote Config. Please add "eleven_labs_api_key" parameter in Firebase Console.');
      }

      debugLog('✅ 11 Labs API key loaded successfully from Firebase Remote Config');
    } catch (e) {
      debugLog('❌ Error initializing 11 Labs Service: $e');
      rethrow;
    }
  }

  /// Debug logging helper
  static void debugLog(String message) {
    developer.log('[ElevenLabsService] $message');
  }

  /// Generate speech from text
  Future<String> generateSpeech({
    required String text,
    required String voiceId,
    required double stabilityLevel,
    required double similarityBoost,
  }) async {
    try {
      debugLog('🎙️ Starting speech generation...');
      debugLog('📝 Text length: ${text.length}, Voice: $voiceId');

      final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');

      final requestBody = {
        'text': text,
        'model_id': 'eleven_monolingual_v1',
        'voice_settings': {
          'stability': stabilityLevel,
          'similarity_boost': similarityBoost,
        },
      };

      debugLog('📤 Sending speech request to 11 Labs API...');
      debugLog('📊 Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('11 Labs API request timeout after 120 seconds');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Response is audio/mpeg bytes, convert to base64
        final base64Audio = base64Encode(response.bodyBytes);
        debugLog('✅ Speech generated successfully (${base64Audio.length} bytes)');
        return 'data:audio/mpeg;base64,$base64Audio';
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('11 Labs API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in generateSpeech: $e');
      rethrow;
    }
  }

  /// List available voices
  Future<List<Map<String, dynamic>>> listVoices() async {
    try {
      debugLog('🎤 Fetching available voices...');

      final url = Uri.parse('https://api.elevenlabs.io/v1/voices');

      final response = await http.get(
        url,
        headers: {
          'xi-api-key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('11 Labs API request timeout');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final voices = List<Map<String, dynamic>>.from(data['voices'] ?? []);
        debugLog('✅ Found ${voices.length} voices');
        return voices;
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('11 Labs API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in listVoices: $e');
      rethrow;
    }
  }

  /// Get voice details
  Future<Map<String, dynamic>> getVoiceDetails({
    required String voiceId,
  }) async {
    try {
      debugLog('🔍 Fetching voice details: $voiceId');

      final url = Uri.parse('https://api.elevenlabs.io/v1/voices/$voiceId');

      final response = await http.get(
        url,
        headers: {
          'xi-api-key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('11 Labs API request timeout');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugLog('✅ Voice details retrieved');
        return data;
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('11 Labs API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in getVoiceDetails: $e');
      rethrow;
    }
  }

  /// Get account info and usage
  Future<Map<String, dynamic>> getAccountInfo() async {
    try {
      debugLog('👤 Fetching account information...');

      final url = Uri.parse('https://api.elevenlabs.io/v1/user');

      final response = await http.get(
        url,
        headers: {
          'xi-api-key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('11 Labs API request timeout');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugLog('✅ Account info retrieved');
        return data;
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('11 Labs API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in getAccountInfo: $e');
      rethrow;
    }
  }

  /// Check API key validity
  static Future<bool> verifyApiKey() async {
    try {
      debugLog('🔐 Verifying 11 Labs API key...');

      final url = Uri.parse('https://api.elevenlabs.io/v1/user');

      final response = await http.get(
        url,
        headers: {
          'xi-api-key': apiKey,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API verification timeout');
        },
      );

      if (response.statusCode == 200) {
        debugLog('✅ 11 Labs API key is valid');
        return true;
      } else {
        debugLog('❌ 11 Labs API key verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugLog('❌ Error verifying API key: $e');
      return false;
    }
  }

  /// Clone a voice from audio samples
  Future<String> cloneVoice({
    required String name,
    required List<int> audioBytes,
    String description = 'User recorded voice clone',
  }) async {
    try {
      debugLog('🎤 Cloning voice: $name');

      final url = Uri.parse('https://api.elevenlabs.io/v1/voices/add');

      final request = http.MultipartRequest('POST', url);
      request.headers['xi-api-key'] = apiKey;
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          audioBytes,
          filename: 'voice_sample.mp3',
        ),
      );

      debugLog('📤 Sending voice clone request...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Voice clone request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final voiceId = data['voice_id'] ?? '';
        debugLog('✅ Voice cloned successfully: $voiceId');
        return voiceId;
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('Voice clone failed: ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in cloneVoice: $e');
      rethrow;
    }
  }
}
