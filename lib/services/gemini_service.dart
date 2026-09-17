import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class GeminiService {
  static String apiKey = '';
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  // Verified working production key from Firebase Remote Config as guaranteed fallback
  static const String _fallbackGeminiApiKey =
      '';

  /// Guaranteed non-empty API key: checks memory, then Remote Config, then verified fallback
  static String get effectiveApiKey {
    if (apiKey.trim().isNotEmpty) return apiKey.trim();
    try {
      final fromConfig = _remoteConfig.getString('gemini_api_key').trim();
      if (fromConfig.isNotEmpty) {
        apiKey = fromConfig;
        return apiKey;
      }
    } catch (_) {}
    return _fallbackGeminiApiKey;
  }

  /// Initialize Gemini Service with API key from Firebase Remote Config
  static Future<void> initialize() async {
    debugLog('🔍 Starting Gemini Service initialization...');
    try {
      debugLog('🚀 Initializing Gemini Service...');

      // Set default values with fallback to prevent empty key errors
      await _remoteConfig.setDefaults({
        'gemini_api_key': _fallbackGeminiApiKey,
      });

      // Fetch remote config with timeout
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugLog(
            '⚠️ Remote Config fetch timed out after 10s, using fallback/cached key',
          );
          return false;
        },
      );

      // Get API key from remote config
      final remoteKey = _remoteConfig.getString('gemini_api_key').trim();
      if (remoteKey.isNotEmpty) {
        apiKey = remoteKey;
      } else {
        apiKey = _fallbackGeminiApiKey;
      }

      debugLog('🔑 Gemini API key ready (${effectiveApiKey.length} chars)');
      debugLog('✅ Gemini Service initialized successfully');
    } catch (e) {
      apiKey = _fallbackGeminiApiKey;
      debugLog(
        '⚠️ Notice during Gemini Service initialization, using fallback key: $e',
      );
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
    final outfitTrim = outfit.trim();
    final outfitLower = outfitTrim.toLowerCase();
    final isAsInPhoto = outfitLower.contains('photo');
    final isFollowPrompt = outfitLower.contains('follow');

    final String outfitDirective;
    if (isAsInPhoto) {
      outfitDirective =
          'Keep the person\'s outfit and clothing style exactly as seen in the reference photo.';
    } else if (isFollowPrompt) {
      outfitDirective =
          'Dress the person in the exact outfit described in the custom prompt instructions.';
    } else {
      outfitDirective =
          'MANDATORY CLOTHING TRANSFORMATION: The person MUST be wearing: $outfitTrim. Do NOT keep the clothing or garments from the reference photo. Completely replace whatever clothes they wore in their photo with an authentic, stylish, high-fashion $outfitTrim featuring realistic fabric textures, natural draping, seams, and high-fashion tailoring.';
    }

    final cleanLocation = (location.contains('Follow'))
        ? 'As specified in custom prompt or reference scene'
        : location;
    final cleanHairstyle =
        (hairstyle.contains('Follow') ||
            hairstyle.toLowerCase().contains('photo'))
        ? 'As in photo or custom prompt'
        : hairstyle;
    final cleanMakeup =
        (makeup.contains('Follow') || makeup.toLowerCase().contains('photo'))
        ? 'As in photo or custom prompt'
        : makeup;
    final cleanMood = (mood.contains('Follow'))
        ? 'As specified in custom prompt'
        : mood;

    final String skinDirective;
    if (skin.contains('Airbrushed') || skin.contains('Glamorous Flawless')) {
      skinDirective =
          'Skin: Soft, glamorous editorial finish with subtle glow, while maintaining natural facial identity.';
    } else {
      String extraSkinNote = '';
      if (skin.contains('Glossy') || skin.contains('Dewy')) {
        extraSkinNote =
            '\nFinish: Glossy, dewy natural skin radiance with realistic specular highlights.';
      } else if (skin.contains('Matte')) {
        extraSkinNote =
            '\nFinish: Soft matte skin finish with controlled natural shine.';
      } else if (skin.contains('Sunkissed')) {
        extraSkinNote =
            '\nFinish: Warm sunkissed natural daylight illumination.';
      }

      skinDirective = '''REAL SKIN LOCK, MAXIMUM PHOTOREALISM:
Use the uploaded selfie as the absolute and only source of truth for the person’s identity. Preserve the exact face, facial anatomy, proportions, natural asymmetry, age, complexion, skin tone and all recognizable features completely unchanged.
Render the skin with maximum true to life photographic detail. Show clearly visible, naturally irregular pores, authentic epidermal microtexture, fine vellus hairs and peach fuzz, subtle fine lines, natural under eye creases, realistic eyelid texture, individual eyebrow hairs, detailed lip lines, delicate facial creases, slight tonal variation, natural redness and believable variations in texture across different areas of the face.
Reproduce realistic skin behaviour under the lighting of the requested scene, including natural translucency, subtle subsurface light scattering, restrained oil and moisture, realistic specular highlights, gentle colour transitions and dimensional shadows. Preserve texture inside both highlights and shadows. The forehead, cheeks, nose, eye area, lips, chin, neck, hands and fingers must all retain authentic human texture.
Skin texture must follow the person’s facial anatomy and vary naturally by area. Do not apply a repetitive, uniform or artificial pore pattern. Do not paste texture over the face. Do not invent heavy freckles, acne, scars, deep wrinkles or blemishes that are not supported by the uploaded selfie.
Absolutely no skin smoothing, airbrushing, beauty filters, digital retouching, frequency separation, artificial blur, waxy skin, plastic skin, porcelain skin, doll like skin, painted texture, CGI texture, excessive glow, fake wetness, oversharpening or artificial clarity. Do not beautify, perfect, reshape, idealize, age or de age the person.
The final result must remain unmistakably identical to the uploaded selfie and look like a genuine, completely unretouched high resolution photograph. When viewed closely or zoomed in, the skin must retain authentic pores, microtexture, fine hairs, lip detail and natural imperfections rather than becoming smooth, blurred, painted or artificially generated.$extraSkinNote''';
    }

    String prompt =
        '''$skinDirective

SCENE & COMPOSITION:
Editorial Lifestyle Shoot.
Scene: $cleanMood at $cleanLocation.
Outfit & Clothing: $outfitDirective
Details: Hairstyle is $cleanHairstyle, Makeup/Grooming is $cleanMakeup.
Physical: Height $height, Bust/Chest $bust, Waist $waist, Hips/Physique $hips.
Camera: $angle. Frame: $aspectRatio — compose the shot so the face is prominent and fully visible.
Style: High-end lifestyle photograph, realistic raw photo textures, cinematic lighting, 8k resolution. Sharp identity details and organic skin tones.${!isAsInPhoto && !isFollowPrompt ? '\n\nCRITICAL ATTIRE REQUIREMENT: The subject must be visibly and unmistakably wearing: $outfitTrim.' : ''}''';

    if (propEnhancers.isNotEmpty) {
      prompt +=
          '\nAdditional Details / Follow Prompt Instructions: $propEnhancers';
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

  /// Generate images using Gemini 2.5 Flash Image model via HTTP (in parallel)
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
      debugLog(
        '🎨 Parameters: $numberOfImages images, aspect ratio: $aspectRatio',
      );

      // Convert reference image to base64
      debugLog('🔄 Converting image to base64...');
      final base64Image = await _fileToBase64(referenceImage);
      debugLog('✅ Base64 conversion complete (${base64Image.length} chars)');

      // Use custom prompt if provided, otherwise generate one
      String detailedPrompt;
      final outfitTrim = outfit.trim();
      final outfitLower = outfitTrim.toLowerCase();
      final isSpecificOutfit =
          outfitTrim.isNotEmpty &&
          !outfitLower.contains('photo') &&
          !outfitLower.contains('follow');

      if (customPrompt != null && customPrompt.isNotEmpty) {
        debugLog('📝 Using custom prompt with outfit parameters...');
        detailedPrompt = customPrompt;
        if (isSpecificOutfit) {
          detailedPrompt +=
              '\n\nMANDATORY OUTFIT OVERRIDE: The person in the image MUST be wearing: $outfitTrim. Completely replace whatever clothes or outfit are mentioned in the prompt or shown in the reference photo with an authentic, stylish $outfitTrim.';
        }
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

      // Execute all image generation requests in parallel with auto-retry
      debugLog(
        '🚀 Firing $numberOfImages image generation requests in parallel...',
      );
      final futures = List.generate(numberOfImages, (i) async {
        try {
          debugLog('🖼️ Generating image ${i + 1}/$numberOfImages...');
          final imageData = await _generateSingleImage(
            base64Image,
            detailedPrompt,
            aspectRatio,
          );
          debugLog('✅ Image ${i + 1} generated successfully');
          return imageData;
        } catch (e) {
          debugLog(
            '⚠️ Image ${i + 1} initial attempt failed: $e. Retrying in 1.5s...',
          );
          await Future.delayed(const Duration(milliseconds: 1500));
          try {
            final retryImageData = await _generateSingleImage(
              base64Image,
              detailedPrompt,
              aspectRatio,
            );
            debugLog('✅ Image ${i + 1} generated successfully on retry');
            return retryImageData;
          } catch (retryError) {
            debugLog('❌ Error generating image ${i + 1} on retry: $retryError');
            return 'error';
          }
        }
      });

      final generatedImages = await Future.wait(futures);

      debugLog(
        '🎉 Image generation complete! Success: ${generatedImages.where((img) => img != 'error').length}/$numberOfImages',
      );
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

      // 2. Extract pose details only if no description was supplied
      String templateAnalysis = '';
      if (customDescription.trim().isEmpty) {
        templateAnalysis = await analyzeTemplateForPose(templateBase64);
        debugLog('📋 Template analysis: $templateAnalysis');
      }

      final outfitTrim = outfit.trim();
      final outfitLower = outfitTrim.toLowerCase();
      final isSpecificOutfit =
          outfitTrim.isNotEmpty &&
          !outfitLower.contains('photo') &&
          !outfitLower.contains('follow');

      final outfitInstruction = isSpecificOutfit
          ? 'OUTFIT OVERRIDE (MANDATORY): The person MUST be wearing: $outfitTrim. Replace the clothing from IMAGE 2 with $outfitTrim while preserving the scene background, lighting, and composition.'
          : 'Strictly preserve the exact scene, location, background, outfit, styling, posture, and lighting from IMAGE 2 or specified below:';

      // 3. Construct a detailed prompt using the analysis & custom description
      final prompt =
          '''MANDATORY DUAL-REFERENCE MULTIMODAL FACE REPLACEMENT & SCENE PRESERVATION:

INPUT REFERENCES:
- IMAGE 1 is the SOURCE USER PHOTO containing their exact face, eyes, natural skin tone, facial features, and true personal identity.
- IMAGE 2 is the TARGET TEMPLATE IMAGE providing the background environment, setting, lighting, posture, outfit, and visual composition.

STRICT INSTRUCTIONS:
1. FACE REPLACEMENT & REAL SKIN LOCK: Replace the face of the character in IMAGE 2 with the EXACT face, facial anatomy, proportions, natural asymmetry, and complexion of the user from IMAGE 1. Render true to life skin texture with natural pores, peach fuzz, subtle expression lines, and lifelike skin behavior under scene lighting.
2. ENVIRONMENT & OUTFIT: $outfitInstruction
${customDescription.isNotEmpty ? customDescription : (templateAnalysis.isNotEmpty ? templateAnalysis : 'Apply user face onto template image layout while preserving the scene background and composition.')}

3. Output the synthesized photorealistic image seamlessly integrating the user face from IMAGE 1 onto the template scene from IMAGE 2.''';

      // 4. Generate images passing both user and template image references
      List<String> generatedImages = [];

      for (int i = 0; i < batch; i++) {
        try {
          final imageData = await _generateImageWithUserAndTemplate(
            userBase64,
            templateBase64,
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
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$effectiveApiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': templateBase64,
                },
              },
              {
                'text':
                    '''Analyze this image in extreme detail and describe EXACTLY what you see:

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

IMPORTANT: Be EXTREMELY detailed and specific about every person's pose, position, and what they're doing. This will be used to recreate the EXACT scene composition with different people. Include all details - poses, positions, interactions, backgrounds, lighting, everything you notice.''',
              },
            ],
          },
        ],
      };

      debugLog('📋 Analyzing template for scene details...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Template analysis timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
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
  Future<String> generateImageWithUserAndPrompt(
    String userBase64,
    String prompt,
    String aspectRatio,
  ) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$effectiveApiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'SOURCE IDENTITY IMAGE (USER REFERENCE): Use this person as the absolute identity reference. Preserve their exact face, facial structure, skin tone, natural pores, and personal identity completely unchanged.',
              },
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': userBase64},
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'imageConfig': {'aspectRatio': _mapAspectRatio(aspectRatio)},
        },
      };

      debugLog('📤 Sending image generation request...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 180),
            onTimeout: () => throw Exception('Generation timeout'),
          );

      debugLog('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
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

  /// Generate image using user face photo + template image layout + prompt
  Future<String> _generateImageWithUserAndTemplate(
    String userBase64,
    String templateBase64,
    String prompt,
    String aspectRatio,
  ) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$effectiveApiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'THIS IS THE PERSON (USE THEIR FACE):'},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': userBase64},
              },
              {
                'text':
                    'THIS IS THE TEMPLATE LAYOUT (REPLACE THE FACE ON THIS TEMPLATE WITH THE PERSON\'S FACE ABOVE):',
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': templateBase64,
                },
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'imageConfig': {'aspectRatio': _mapAspectRatio(aspectRatio)},
        },
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () =>
                throw Exception('Image generation request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }
        throw Exception('No image data returned from generation');
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugLog('❌ Error in _generateImageWithUserAndTemplate: $e');
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
      final currentKey = effectiveApiKey;
      final keyPreview = currentKey.length >= 8
          ? '${currentKey.substring(0, 8)}...'
          : 'valid';
      debugLog('🔧 Preparing request for single image...');
      debugLog(
        '📏 Aspect ratio: $aspectRatio -> ${_mapAspectRatio(aspectRatio)}',
      );
      debugLog('🔑 API Key: $keyPreview');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$currentKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'SOURCE IDENTITY IMAGE (USER REFERENCE): Use this person as the absolute identity reference. Preserve their exact face, facial structure, skin tone, natural pores, and personal identity completely unchanged.',
              },
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'imageConfig': {'aspectRatio': _mapAspectRatio(aspectRatio)},
        },
      };

      debugLog('📤 Sending image generation request to Gemini API...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
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

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
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
      final currentKey = effectiveApiKey;
      final keyPreview = currentKey.length >= 8
          ? '${currentKey.substring(0, 8)}...'
          : 'valid';
      debugLog('🔧 Preparing text-based image request...');
      debugLog(
        '📏 Aspect ratio: $aspectRatio -> ${_mapAspectRatio(aspectRatio)}',
      );
      debugLog('🔑 API Key: $keyPreview');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$currentKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'imageConfig': {'aspectRatio': _mapAspectRatio(aspectRatio)},
        },
      };

      debugLog('📤 Sending text-based request to: ${url.scheme}://${url.host}');
      debugLog('📊 Request body size: ${jsonEncode(requestBody).length} bytes');
      debugLog('📝 Prompt length: ${prompt.length} characters');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
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
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog(
                  '✅ Text-based image generated (${imageData.length} bytes)',
                );
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
        throw Exception(
          'API returned status ${response.statusCode}: $errorBody',
        );
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

      String prompt =
          '''Generate a magazine cover. This is the person whose face MUST be on the cover. Copy their exact face, skin tone, facial features, and identity onto the magazine cover shown in the next image. The magazine cover is just a layout template - replace any face on it with this person's face. Make it look like this person is the cover star of this magazine. Keep their face sharp, clear, and recognizable. Do not change their facial features.''';

      if (imagePrompt.isNotEmpty) {
        prompt += '\n\nAdditional style: $imagePrompt';
      }

      if (overlayPrompt.isNotEmpty) {
        prompt += '\n\nText overlays: $overlayPrompt';
      }

      debugLog('📝 Magazine prompt ready');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$effectiveApiKey',
      );

      // User photo FIRST with label, then template with label
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'THIS IS THE PERSON - USE THEIR FACE:'},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': userBase64},
              },
              {
                'text':
                    'THIS IS THE MAGAZINE TEMPLATE LAYOUT - USE ONLY THE DESIGN:',
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': templateBase64,
                },
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'imageConfig': {'aspectRatio': _mapAspectRatio(aspectRatio)},
        },
      };

      debugLog('📤 Sending magazine generation request...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
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

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
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

  /// Generate Carousel slide by performing face replacement onto selected template image
  Future<String> generateCarouselFromTemplate({
    required String templateImageUrl,
    required File userPhoto,
    String userTopic = '',
  }) async {
    try {
      debugLog('🎨 Starting Carousel Template Face Swap generation...');

      final userBytes = await userPhoto.readAsBytes();
      final userBase64 = base64Encode(userBytes);

      // Fetch template image bytes
      Uint8List templateBytes;
      if (templateImageUrl.startsWith('http')) {
        final resp = await http
            .get(Uri.parse(templateImageUrl))
            .timeout(const Duration(seconds: 30));
        templateBytes = resp.bodyBytes;
      } else if (templateImageUrl.startsWith('data:image')) {
        templateBytes = base64Decode(templateImageUrl.split(',')[1]);
      } else {
        templateBytes = await File(templateImageUrl).readAsBytes();
      }
      final templateBase64 = base64Encode(templateBytes);

      String prompt = '''Generate a carousel template slide image. 
THIS IS A FACE REPLACEMENT TASK.
IMAGE 1 contains the user's face and true identity. 
IMAGE 2 contains the carousel template image with layout, framing, background, graphic design, and style.
INSTRUCTIONS:
1. Replace any face in the template image (IMAGE 2) with the exact face, skin tone, facial features, and identity of the person in IMAGE 1.
2. Keep the template background, layout structure, graphic elements, text positioning, outfit style, and visual framing of IMAGE 2 completely intact.
3. Make the face swap seamless, sharp, photorealistic, and natural.''';

      if (userTopic.isNotEmpty) {
        prompt += '\n\nTopic / Text context: "$userTopic"';
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$effectiveApiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'IMAGE 1 (USER FACE TO USE):'},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': userBase64},
              },
              {'text': 'IMAGE 2 (CAROUSEL TEMPLATE TO KEEP DESIGN):'},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': templateBase64,
                },
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'imageConfig': {'aspectRatio': '3:4'},
        },
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                debugLog(
                  '✅ Carousel template face swap generated successfully',
                );
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }
      }
      throw Exception(
        'Carousel template generation returned status ${response.statusCode}',
      );
    } catch (e) {
      debugLog('❌ Error in generateCarouselFromTemplate: $e');
      rethrow;
    }
  }
}
