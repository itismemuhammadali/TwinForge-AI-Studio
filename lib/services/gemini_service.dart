import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class GeminiService {
  static String apiKey = '';
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize Gemini Service with API key from Firebase Remote Config
  static Future<void> initialize() async {
    debugLog('🔍 Starting Gemini Service initialization...');
    try {
      debugLog('🚀 Initializing Gemini Service...');
      
      // Set default values
      debugLog('📋 Setting default remote config values...');
      await _remoteConfig.setDefaults({
        'gemini_api_key': '', // Empty default - must be set in Firebase Console
      });
      debugLog('✅ Defaults set');

      debugLog('⏳ Fetching Remote Config...');
      // Fetch remote config with 1 hour cache and a timeout
      final fetchResult = await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugLog('⚠️ Remote Config fetch timed out after 10s');
          return false;
        },
      );
      
      debugLog('✅ Remote Config fetch result: $fetchResult');

      // Get API key from remote config
      apiKey = _remoteConfig.getString('gemini_api_key');
      
      debugLog('🔑 Gemini API key from Remote Config: ${apiKey.isEmpty ? "EMPTY" : "✅ Found (${apiKey.length} chars)"}');

      if (apiKey.isEmpty) {
        final errorMsg = 'Gemini API key not configured in Firebase Remote Config';
        debugLog('❌ CRITICAL: $errorMsg');
        throw Exception(errorMsg);
      }

      debugLog('✅ Gemini Service initialized successfully');
    } catch (e) {
      debugLog('❌ Error initializing Gemini Service: $e');
      debugLog('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Debug logging helper
  static void debugLog(String message) {
    debugPrint('[GeminiService] $message');
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
    String? customPrompt,
    String propEnhancers = '',
  }) async {
    try {
      debugLog('🎬 Starting image generation with reference...');
      debugLog('📸 Reference image: ${referenceImage.path}');
      debugLog('🎨 Parameters: $numberOfImages images, aspect ratio: $aspectRatio');
      
      // Convert reference image to base64
      debugLog('🔄 Converting image to base64...');
      final base64Image = await _fileToBase64(referenceImage);
      debugLog('✅ Base64 conversion complete (${base64Image.length} chars)');

      // Use custom prompt if provided, otherwise generate one
      String detailedPrompt;
      if (customPrompt != null && customPrompt.isNotEmpty) {
        debugLog('📝 Using custom prompt from admin...');
        detailedPrompt = customPrompt;
      } else {
        debugLog('📝 Generating detailed prompt...');
        detailedPrompt = await generateImagePrompt(
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
          propEnhancers: propEnhancers,
        );
      }
      debugLog('✅ Prompt ready: ${detailedPrompt.substring(0, 100)}...');

      // Generate images in parallel
      List<String> generatedImages = [];

      for (int i = 0; i < numberOfImages; i++) {
        try {
          debugLog('🖼️ Generating image ${i + 1}/$numberOfImages...');
          final imageData = await _generateSingleImage(
            base64Image,
            detailedPrompt,
            aspectRatio,
          );
          generatedImages.add(imageData);
          debugLog('✅ Image ${i + 1} generated successfully');
        } catch (e) {
          debugLog('❌ Error generating image ${i + 1}: $e');
          generatedImages.add('error');
        }
      }

      debugLog('🎉 Image generation complete! Success: ${generatedImages.where((img) => img != 'error').length}/$numberOfImages');
      return generatedImages;
    } catch (e) {
      debugLog('❌ Fatal error in generateImagesWithReference: $e');
      throw Exception('Failed to generate images: $e');
    }
  }

  /// Download image from URL to base64 string
  static Future<String> _urlToBase64(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      } else {
        throw Exception('Failed to download image from $url');
      }
    } catch (e) {
      throw Exception('Error downloading image: $e');
    }
  }

  /// Generate personalized image using template + filters + user photo
  Future<List<String>> generateImageWithTemplateAndReference({
    required String templateImageUrl,
    required File userImageFile,
    required String mood,
    required String location,
    required String outfit,
    required String hairstyle,
    required String makeup,
    required String skin,
    required String height,
    required String bust,
    required String waist,
    required String hips,
    required String angle,
    required String ratio,
    required int batch,
    String customDescription = '',
  }) async {
    try {
      debugLog('🎨 Preparing template-based generation...');
      
      // 1. Prepare images
      final templateBase64 = await _urlToBase64(templateImageUrl);
      final userBase64 = await _fileToBase64(userImageFile);

      // 2. First, ask Gemini to analyze the template and extract pose details
      final templateAnalysis = await analyzeTemplateForPose(templateBase64);
      debugLog('📋 Template analysis: $templateAnalysis');

      // 3. Construct a detailed prompt using the analysis
      final prompt = '''You are an expert photorealistic image generation AI.

TASK: Generate a photorealistic image of the person in IMAGE 1, repositioned to match the exact pose and composition described below.

IMAGE 1 - USER PHOTO:
The person in this image should be used as the subject.
Their face, identity, and appearance should be preserved exactly.

POSE & COMPOSITION TO REPLICATE:
$templateAnalysis

APPEARANCE & STYLE CUSTOMIZATIONS:
- Vibe/Mood: $mood
- Location/Setting: $location
- Outfit: $outfit
- Hair Style: $hairstyle
- Makeup: $makeup
- Skin Style: $skin
- Height: $height
- Bust: $bust
- Waist: $waist
- Hips: $hips
- Camera Angle: $angle
- Aspect Ratio: $ratio
${customDescription.isNotEmpty ? '\n- Custom Details: $customDescription' : ''}

GENERATION INSTRUCTIONS:
1. Take the person from IMAGE 1 - keep their face and identity
2. Reposition their body to exactly match the pose described above
3. Apply the customization filters
4. Generate a NEW, photorealistic image
5. Do NOT return the original image unchanged

OUTPUT MUST:
✅ Show the same person (recognizable face from IMAGE 1)
✅ In the exact pose described
✅ With all customizations applied
✅ Professional and high-quality
✅ Be a GENERATED image (not the original)

Generate now.''';

      // 4. Generate images
      List<String> generatedImages = [];

      for (int i = 0; i < batch; i++) {
        try {
          final imageData = await _generateImageWithUserAndPrompt(
            userBase64,
            prompt,
            ratio,
          );
          generatedImages.add(imageData);
        } catch (e) {
          debugLog('Error generating image $i: $e');
          generatedImages.add('error');
        }
      }

      return generatedImages;
    } catch (e) {
      throw Exception('Failed to generate template-based images: $e');
    }
  }

  /// Analyze template image to extract pose and composition details  
  Future<String> analyzeTemplateForPose(String templateBase64) async {
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
                  'data': templateBase64,
                }
              },
              {
                'text': '''Analyze this image in extreme detail and describe EXACTLY what you see:

1. **SCENE & SETTING**: Describe the location, room, environment, background. What space is this? Any furniture, props, or surroundings?

2. **NUMBER & POSITIONING OF PEOPLE**: 
   - How many people are visible?
   - Where is each person positioned? (left, right, center, background, foreground, seated, standing)

3. **EACH PERSON - DETAILED DESCRIPTION**:
   For every person you can see:
   - Their exact pose and body posture (standing, sitting, leaning, etc.)
   - Body position and limb positions (where are arms, hands, legs positioned)
   - Which direction they're facing (towards camera, away, side profile, angle)
   - What are they doing? (working, talking, gesturing, holding something)
   - Head angle and where they're looking
   - Clothing and appearance
   - Body language and stance

4. **CAMERA & COMPOSITION**:
   - Camera angle and view (eye level, overhead, low angle, wide shot, medium, close-up)
   - What's in focus vs background blur
   - How people are framed in the shot
   - Overall composition style

5. **LIGHTING**:
   - Light direction and type (natural window light, artificial, mixed)
   - Shadows and highlights on faces/bodies
   - Mood created by lighting
   - Color tones and atmosphere

6. **OVERALL AESTHETIC**:
   - Professional/casual/formal/creative style
   - Mood and feeling of the scene
   - Any distinctive elements or details that stand out

IMPORTANT: Be EXTREMELY detailed and specific about every person's pose, position, and what they're doing. This will be used to recreate the EXACT scene composition with different people. Include all details - poses, positions, interactions, backgrounds, lighting, everything you notice.'''
              }
            ]
          }
        ]
      };

      debugLog('📋 Analyzing template for scene details...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Template analysis timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['text'] != null) {
                final analysis = part['text'];
                debugLog('✅ Template analysis complete');
                return analysis;
              }
            }
          }
        }
        throw Exception('No text response from template analysis');
      } else {
        throw Exception('Template analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error analyzing template: $e');
      return 'A person in a stylized pose with professional lighting';
    }
  }

  /// Generate image using user photo + detailed text prompt
  Future<String> _generateImageWithUserAndPrompt(
    String userBase64,
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
                  'data': userBase64,
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

      debugLog('📤 Sending image generation request...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 180),
        onTimeout: () => throw Exception('Generation timeout'),
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
                debugLog('✅ Image generated successfully');
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
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error in generation: $e');
      rethrow;
    }
  }

  /// Generate a single image using Gemini 2.5 Flash Image
  Future<String> _generateSingleImage(
    String base64Image,
    String prompt,
    String aspectRatio,
  ) async {
    try {
      debugLog('🔧 Preparing request for single image...');
      debugLog('📏 Aspect ratio: $aspectRatio -> ${_mapAspectRatio(aspectRatio)}');
      debugLog('🔑 API Key: ${apiKey.substring(0, 10)}...');

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

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          debugLog('⏱️ Request timeout after 120 seconds');
          throw Exception('API request timeout after 120 seconds');
        },
      );

      debugLog('📥 Response received with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'];
            
            for (int i = 0; i < parts.length; i++) {
              final part = parts[i];
              
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog('✅ Image generated successfully');
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        debugLog('❌ No image data found in response');
        throw Exception('No image data in response');
      } else {
        final errorBody = response.body;
        debugLog('❌ API Error: ${response.statusCode}: $errorBody');
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Exception in _generateSingleImage: $e');
      debugLog('❌ Stack trace: ${StackTrace.current}');
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
      debugLog('🔧 Preparing text-based image request...');
      debugLog('📏 Aspect ratio: $aspectRatio -> ${_mapAspectRatio(aspectRatio)}');
      debugLog('🔑 API Key: ${apiKey.substring(0, 10)}...');

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

      debugLog('📤 Sending text-based request to: ${url.scheme}://${url.host}');
      debugLog('📊 Request body size: ${jsonEncode(requestBody).length} bytes');
      debugLog('📝 Prompt length: ${prompt.length} characters');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          debugLog('⏱️ Text-based request timeout after 120 seconds');
          throw Exception('API request timeout after 120 seconds');
        },
      );

      debugLog('📥 Text-based response status: ${response.statusCode}');
      debugLog('📥 Response size: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugLog('✅ Text-based response parsed');

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog('✅ Text-based image generated (${imageData.length} bytes)');
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        debugLog('❌ No image data in text-based response');
        throw Exception('No image data in response');
      } else {
        final errorBody = response.body;
        debugLog('❌ Text-based API Error: ${response.statusCode}');
        debugLog('❌ Error: $errorBody');
        throw Exception('API returned status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugLog('❌ Exception in _generateSingleImageFromPrompt: $e');
      rethrow;
    }
  }

  /// Generate magazine cover using template and user's photo
  Future<String> generateMagazineCover({
    required File templateImage,
    required File userPhoto,
    String imagePrompt = '',
    String overlayPrompt = '',
    String aspectRatio = '3:4',
  }) async {
    try {
      debugLog(' magazine: Starting magazine generation...');

      final templateBase64 = await _fileToBase64(templateImage);
      final userBase64 = await _fileToBase64(userPhoto);

      String prompt = '''Generate a magazine cover. This is the person whose face MUST be on the cover. Copy their exact face, skin tone, facial features, and identity onto the magazine cover shown in the next image. The magazine cover is just a layout template - replace any face on it with this person's face. Make it look like this person is the cover star of this magazine. Keep their face sharp, clear, and recognizable. Do not change their facial features.''';

      if (imagePrompt.isNotEmpty) {
        prompt += '\n\nAdditional style: $imagePrompt';
      }

      if (overlayPrompt.isNotEmpty) {
        prompt += '\n\nText overlays: $overlayPrompt';
      }

      debugLog('📝 Magazine prompt ready');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$apiKey',
      );

      // User photo FIRST with label, then template with label
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'THIS IS THE PERSON - USE THEIR FACE:'},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': userBase64,
                }
              },
              {'text': 'THIS IS THE MAGAZINE TEMPLATE LAYOUT - USE ONLY THE DESIGN:'},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': templateBase64,
                }
              },
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'imageConfig': {
            'aspectRatio': _mapAspectRatio(aspectRatio),
          }
        }
      };

      debugLog('📤 Sending magazine generation request...');

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

      debugLog('📥 Response received with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'];
            
            for (int i = 0; i < parts.length; i++) {
              final part = parts[i];
              
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog('✅ Magazine cover generated successfully');
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        throw Exception('No image data in response');
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Exception in generateMagazineCover: $e');
      rethrow;
    }
  }
}
