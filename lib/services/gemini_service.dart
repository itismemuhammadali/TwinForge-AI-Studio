import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class GeminiService {
  static late String apiKey;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize Gemini Service with API key from Firebase Remote Config
  static Future<void> initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults({
        'gemini_api_key': '', // Empty default - must be set in Firebase Console
      });

      // Fetch remote config with 1 hour cache
      await _remoteConfig.fetchAndActivate();

      // Get API key from remote config
      apiKey = _remoteConfig.getString('gemini_api_key');

      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not configured in Firebase Remote Config');
      }

      debugLog('✅ Gemini API key loaded successfully from Firebase Remote Config');
    } catch (e) {
      debugLog('❌ Error initializing Gemini Service: $e');
      rethrow;
    }
  }

  /// Debug logging helper
  static void debugLog(String message) {
    // Use developer.log instead of print for production
    developer.log('[GeminiService] $message');
  }

  /// Convert image file to base64 string
  Future<String> _fileToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Generate detailed prompt for image generation
  Future<String> generateImagePrompt({
    required String outfit,
    required String location,
    required String hairstyle,
    required String makeup,
    required String angle,
    required String skin,
    required String mood,
    required String height,
    required String bust,
    required String waist,
    required String hips,
    required String aspectRatio,
    String propEnhancers = '',
  }) async {
    String prompt = '''Editorial Lifestyle Shoot. 
Subject: Exact facial features, bone structure, and identity from the reference image. IMPORTANT: The subject's face must always be clearly visible, well-lit, and centered in the frame regardless of aspect ratio.
Scene: $mood at $location.
Outfit: $outfit.
Details: Hairstyle is $hairstyle, Makeup/Grooming is $makeup, Skin is $skin.
Physical: Height $height, Bust/Chest $bust, Waist $waist, Hips/Physique $hips.
Camera: $angle. Frame: $aspectRatio — compose the shot so the face is always prominent and fully visible within the frame.
Style: High-end fashion magazine, realistic textures, cinematic lighting, 8k resolution. Face must be sharp, recognizable, and unobstructed.''';

    if (propEnhancers.isNotEmpty) {
      prompt += '\nAdditional Details: $propEnhancers';
    }

    return prompt;
  }

  /// Map aspect ratio to Gemini format
  String _mapAspectRatio(String ratio) {
    if (ratio.contains('9:16')) return '9:16';
    if (ratio.contains('16:9')) return '16:9';
    if (ratio.contains('4:3')) return '4:3';
    if (ratio.contains('3:4') || ratio.contains('2:3')) return '3:4';
    if (ratio.contains('4:5')) return '4:5';
    if (ratio.contains('3:2')) return '3:2';
    return '1:1';
  }

  /// Get display aspect ratio as double (width / height) for UI rendering
  static double getDisplayRatio(String ratio) {
    if (ratio.contains('9:16')) return 9 / 16;
    if (ratio.contains('16:9')) return 16 / 9;
    if (ratio.contains('4:3')) return 4 / 3;
    if (ratio.contains('4:5')) return 4 / 5;
    if (ratio.contains('3:4') || ratio.contains('2:3')) return 3 / 4;
    if (ratio.contains('3:2')) return 3 / 2;
    return 1.0; // square default
  }

  /// Generate images using Gemini 2.5 Flash Image model via HTTP
  Future<List<String>> generateImagesWithReference({
    required File referenceImage,
    required String outfit,
    required String location,
    required String hairstyle,
    required String makeup,
    required String angle,
    required String skin,
    required String mood,
    required String height,
    required String bust,
    required String waist,
    required String hips,
    required String aspectRatio,
    required int numberOfImages,
  }) async {
    try {
      // Convert reference image to base64
      final base64Image = await _fileToBase64(referenceImage);

      // Generate detailed prompt
      final detailedPrompt = await generateImagePrompt(
        outfit: outfit,
        location: location,
        hairstyle: hairstyle,
        makeup: makeup,
        angle: angle,
        skin: skin,
        mood: mood,
        height: height,
        bust: bust,
        waist: waist,
        hips: hips,
        aspectRatio: aspectRatio,
      );

      // Generate images in parallel
      List<String> generatedImages = [];

      for (int i = 0; i < numberOfImages; i++) {
        try {
          final imageData = await _generateSingleImage(
            base64Image,
            detailedPrompt,
            aspectRatio,
          );
          generatedImages.add(imageData);
        } catch (e) {
          debugLog('Error generating image $i: $e');
          generatedImages.add('error');
        }
      }

      return generatedImages;
    } catch (e) {
      throw Exception('Failed to generate images: $e');
    }
  }

  /// Generate a single image using Gemini 2.5 Flash Image
  Future<String> _generateSingleImage(
    String base64Image,
    String prompt,
    String aspectRatio,
  ) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              },
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'imageConfig': {
            'aspectRatio': _mapAspectRatio(aspectRatio),
          }
        }
      };

      debugLog('📤 Sending image generation request to Gemini API...');
      debugLog('📊 Request size: ${jsonEncode(requestBody).length} bytes');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('API request timeout after 120 seconds');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract image data from response
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog('✅ Image generated successfully (${imageData.length} bytes)');
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        throw Exception('No image data in response');
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in _generateSingleImage: $e');
      rethrow;
    }
  }

  /// Alternative: Generate images using text-only prompt
  Future<List<String>> generateImagesWithPrompt({
    required String outfit,
    required String location,
    required String hairstyle,
    required String makeup,
    required String angle,
    required String skin,
    required String mood,
    required String height,
    required String bust,
    required String waist,
    required String hips,
    required String aspectRatio,
    required int numberOfImages,
  }) async {
    try {
      final detailedPrompt = await generateImagePrompt(
        outfit: outfit,
        location: location,
        hairstyle: hairstyle,
        makeup: makeup,
        angle: angle,
        skin: skin,
        mood: mood,
        height: height,
        bust: bust,
        waist: waist,
        hips: hips,
        aspectRatio: aspectRatio,
      );

      List<String> generatedImages = [];

      for (int i = 0; i < numberOfImages; i++) {
        try {
          final imageData = await _generateSingleImageFromPrompt(
            detailedPrompt,
            aspectRatio,
          );
          generatedImages.add(imageData);
        } catch (e) {
          debugLog('Error generating image $i: $e');
          generatedImages.add('error');
        }
      }

      return generatedImages;
    } catch (e) {
      throw Exception('Failed to generate images: $e');
    }
  }

  /// Generate a single image from text prompt only
  Future<String> _generateSingleImageFromPrompt(
    String prompt,
    String aspectRatio,
  ) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'imageConfig': {
            'aspectRatio': _mapAspectRatio(aspectRatio),
          }
        }
      };

      debugLog('📤 Sending text-based image generation request to Gemini API...');
      debugLog('📊 Prompt length: ${prompt.length} characters');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('API request timeout after 120 seconds');
        },
      );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog('✅ Image generated successfully from prompt (${imageData.length} bytes)');
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        throw Exception('No image data in response');
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}');
        debugLog('❌ Error details: $errorBody');
        throw Exception('API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Error in _generateSingleImageFromPrompt: $e');
      rethrow;
    }
  }
}
