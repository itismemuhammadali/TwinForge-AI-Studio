import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Image Generation API
  Future<Map<String, dynamic>> generateImage({
    required String prompt,
    required String model,
    String? apiKey,
  }) async {
    try {
      // TODO: Replace with your actual image generation API
      // Example: Replicate, Stability AI, or custom backend
      final response = await http.post(
        Uri.parse('https://your-api.com/generate-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'model': model,
        }),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Image generation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Image generation error: $e');
    }
  }

  // B-Roll Video Generation (Kling API)
  Future<Map<String, dynamic>> generateBRollVideo({
    required String imageUrl,
    required String motionStyle,
    String? apiKey,
  }) async {
    try {
      // TODO: Integrate Kling API
      final response = await http.post(
        Uri.parse('https://api.klingai.com/v1/videos/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'image_url': imageUrl,
          'motion_style': motionStyle, // slow_push, side_pan, cinematic_reveal
        }),
      ).timeout(const Duration(minutes: 10));

      if (response.statusCode == 200 || response.statusCode == 202) {
        return jsonDecode(response.body);
      } else {
        throw Exception('B-Roll generation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('B-Roll generation error: $e');
    }
  }

  // Voice Generation (ElevenLabs)
  Future<String> generateVoice({
    required String text,
    required String voiceId,
    String? apiKey,
  }) async {
    try {
      // TODO: Integrate ElevenLabs API
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
        headers: {
          'xi-api-key': apiKey ?? '',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
        }),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        // Return audio URL or base64
        return response.body;
      } else {
        throw Exception('Voice generation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Voice generation error: $e');
    }
  }

  // Carousel Generation
  Future<Map<String, dynamic>> generateCarousel({
    required List<String> imageUrls,
    required String templateId,
    String? apiKey,
  }) async {
    try {
      // TODO: Integrate Creatomate API
      final response = await http.post(
        Uri.parse('https://api.creatomate.com/v1/renders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'template_id': templateId,
          'modifications': {
            'images': imageUrls,
          },
        }),
      ).timeout(const Duration(minutes: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Carousel generation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Carousel generation error: $e');
    }
  }

  // Lip Sync (Sync.so)
  Future<Map<String, dynamic>> generateLipSync({
    required String videoUrl,
    required String audioUrl,
    String? apiKey,
  }) async {
    try {
      // TODO: Integrate Sync.so API
      final response = await http.post(
        Uri.parse('https://api.sync.so/v1/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'video_url': videoUrl,
          'audio_url': audioUrl,
        }),
      ).timeout(const Duration(minutes: 15));

      if (response.statusCode == 200 || response.statusCode == 202) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lip sync failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lip sync error: $e');
    }
  }

  // Check generation status
  Future<Map<String, dynamic>> checkStatus({
    required String jobId,
    required String service, // 'kling', 'creatomate', 'sync'
    String? apiKey,
  }) async {
    try {
      final url = switch (service) {
        'kling' => 'https://api.klingai.com/v1/videos/$jobId',
        'creatomate' => 'https://api.creatomate.com/v1/renders/$jobId',
        'sync' => 'https://api.sync.so/v1/sync/$jobId',
        _ => throw Exception('Unknown service: $service'),
      };

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Status check error: $e');
    }
  }
}
