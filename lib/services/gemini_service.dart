import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyDC7nOubuGl7BbmmJUaMlfpA9d7cbyl-mQ';

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
          print('Error generating image $i: $e');
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

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

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
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        throw Exception('No image data in response');
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _generateSingleImage: $e');
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
          print('Error generating image $i: $e');
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

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (final part in candidate['content']['parts']) {
              if (part['inlineData'] != null) {
                final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
                final imageData = part['inlineData']['data'];
                return 'data:$mimeType;base64,$imageData';
              }
            }
          }
        }

        throw Exception('No image data in response');
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _generateSingleImageFromPrompt: $e');
      rethrow;
    }
  }
}
