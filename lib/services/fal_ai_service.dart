import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FalAiService {
  static late String apiKey;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize FAL AI Service with API key from Firebase Remote Config
  static Future<void> initialize() async {
    try {
      debugLog('🔍 Initializing FAL AI Service...');
      
      // Set cache expiration to 0 for immediate fetch
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );

      // Fetch remote config - force refresh from server with a timeout
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugLog('⚠️ Remote Config fetch timed out for FAL AI');
          return false;
        },
      );

      debugLog('📊 Remote Config fetched. Keys: ${_remoteConfig.getAll().keys}');

      // Get API key from remote config
      apiKey = _remoteConfig.getString('fal_ai_api_key');

      debugLog('🔍 Fetching fal_ai_api_key from Remote Config...');
      debugLog('📊 API Key value: ${apiKey.isNotEmpty ? "✅ Found (${apiKey.length} chars)" : "❌ Empty"}');

      if (apiKey.isEmpty) {
        final allKeys = _remoteConfig.getAll().keys.toList();
        debugLog('❌ Available keys in Remote Config: $allKeys');
        // Don't throw exception, just log it. Features using this service will check for apiKey.isEmpty
      } else {
        debugLog('✅ FAL AI API key loaded successfully');
      }
    } catch (e) {
      debugLog('❌ Error initializing FAL AI Service: $e');
      // Don't rethrow to avoid blocking app initialization
    }
  }

  /// Debug logging helper
  static void debugLog(String message) {
    developer.log('[FalAiService] $message');
    print('[FalAiService] $message');
  }

  /// Generate carousel image from multiple images and template
  /// Uses FLUX.2 [pro] Edit - multi-reference image composition
  Future<String> generateCarousel({
    required List<String> imageUrls,
    required String template,
    required String textOverlay,
  }) async {
    try {
      debugLog('🎨 Starting carousel generation with FLUX.2 [pro] Edit...');
      debugLog('📸 Images: ${imageUrls.length}, Template: $template');
      debugLog('✍️ Text overlay: $textOverlay');
      
      if (apiKey.isEmpty) {
        throw Exception('FAL AI API key is empty');
      }
      debugLog('🔑 API Key loaded: ${apiKey.length} characters');

      // Use FLUX.2 [pro] Edit endpoint - multi-reference composition
      final url = Uri.parse('https://fal.run/fal-ai/flux-2-pro/edit');

      // Build image reference string like @image1 @image2 @image3 @image4
      final imageReferences = List.generate(
        imageUrls.length,
        (i) => '@image${i + 1}',
      ).join(' ');

      final prompt = textOverlay.isNotEmpty
          ? '$textOverlay. Arrange these images in a beautiful carousel layout with $template styling. Images: $imageReferences'
          : 'Create a professional carousel by arranging these images in a grid layout with $template template styling. Images: $imageReferences';

      final requestBody = {
        'prompt': prompt,
        'image_urls': imageUrls,
      };

      debugLog('📤 Sending request to FLUX.2 [pro] Edit (synchronous)...');
      debugLog('📊 Endpoint: $url');
      debugLog('📊 Prompt: $prompt');
      debugLog('🔑 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 300), // 5 minutes for sync request
        onTimeout: () {
          throw Exception('FAL AI request timeout (5 minutes)');
        },
      );

      debugLog('📥 Response status: ${response.statusCode}');
      final bodyPreview = response.body.length > 200 
          ? response.body.substring(0, 200) 
          : response.body;
      debugLog('📥 Response: $bodyPreview');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['image'] != null) {
          final imageUrl = data['image'] is Map ? data['image']['url'] : data['image'];
          debugLog('✅ Carousel generated: $imageUrl');
          return imageUrl.toString();
        } else if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          final imageUrl = data['images'][0] is Map ? data['images'][0]['url'] : data['images'][0];
          debugLog('✅ Carousel generated: $imageUrl');
          return imageUrl.toString();
        } else if (data['url'] != null) {
          debugLog('✅ Carousel generated: ${data['url']}');
          return data['url'].toString();
        } else {
          throw Exception('No image URL in response');
        }
      } else {
        throw Exception('FAL AI error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugLog('❌ Error: $e');
      rethrow;
    }
  }

  /// Generate video from images and template
  Future<String> generateVideo({
    required List<String> imageUrls,
    required String template,
    required String customPrompt,
    required String filter,
  }) async {
    try {
      debugLog('🎬 Starting video generation...');
      debugLog('📸 Images: ${imageUrls.length}, Template: $template');

      final url = Uri.parse('https://fal.run/fal-ai/video-gen');

      final requestBody = {
        'images': imageUrls,
        'template': template,
        'custom_prompt': customPrompt,
        'filter': filter,
      };

      debugLog('📤 Sending video request...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          throw Exception('FAL AI API request timeout');
        },
      );

      debugLog('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['video_url'] != null) {
          final videoUrl = data['video_url'];
          debugLog('✅ Video generated: $videoUrl');
          return videoUrl;
        } else {
          throw Exception('No video URL in response');
        }
      } else {
        throw Exception('FAL AI error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugLog('❌ Error: $e');
      rethrow;
    }
  }

  /// Enhance image (upscale and refine) using Clarity Upscaler
  /// Accepts either a public [imageUrl] or a [base64Image] (data:image/jpeg;base64,...)
  Future<String> enhanceImage({
    String? imageUrl,
    String? base64Image,
    double creativity = 0.35,
    double reshaping = 0.15,
  }) async {
    try {
      debugLog('✨ Starting image enhancement...');
      
      if (apiKey.isEmpty) {
        throw Exception('FAL AI API key is empty');
      }

      final url = Uri.parse('https://fal.run/fal-ai/clarity-upscaler');

      final requestBody = {
        'image_url': imageUrl ?? base64Image,
        'creativity': creativity,
        'reshaping': reshaping,
        'upscale_factor': 2.0,
      };

      debugLog('📤 Sending enhancement request to Clarity Upscaler...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Enhancement request timeout');
        },
      );

      debugLog('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['image'] != null) {
          final enhancedUrl = data['image'] is Map ? data['image']['url'] : data['image'];
          debugLog('✅ Image enhanced: $enhancedUrl');
          return enhancedUrl.toString();
        } else {
          throw Exception('No enhanced image URL in response');
        }
      } else {
        throw Exception('FAL AI error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugLog('❌ Enhancement Error: $e');
      rethrow;
    }
  }

  /// Check API key validity
  static Future<bool> verifyApiKey() async {
    try {
      debugLog('🔐 Verifying FAL AI API key...');

      final url = Uri.parse('https://fal.run/fal-ai/flux-pro/v1.1');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode({'prompt': 'test'}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Verification timeout');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugLog('✅ API key is valid');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugLog('❌ API key verification failed: ${response.statusCode}');
        return false;
      } else {
        debugLog('⚠️ Verification response: ${response.statusCode}');
        return true;
      }
    } catch (e) {
      debugLog('❌ Verification error: $e');
      return false;
    }
  }
}
