import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:ai_video_image_generation_app/services/seedance_ai_service.dart';

class FalAiService {
  static late String apiKey;
  static String klingApiKey = '';
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

      // Get API keys from remote config
      apiKey = _remoteConfig.getString('fal_ai_api_key');
      klingApiKey = _remoteConfig.getString('kling_api_key');

      debugLog('🔍 Fetching fal_ai_api_key from Remote Config...');
      debugLog('📊 FAL API Key value: ${apiKey.isNotEmpty ? "✅ Found (${apiKey.length} chars)" : "❌ Empty"}');
      if (klingApiKey.isNotEmpty) {
        debugLog('✅ Kling API Key loaded from Remote Config (${klingApiKey.length} chars)');
      }

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
    // debugPrint('[FalAiService] $message');
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

  /// Generate cinematic B-Roll using Video Face Swap (Asynchronous)
  Future<String> generateBRoll({
    required String faceImageUrl,
    required String templateVideoUrl,
  }) async {
    try {
      debugLog('👤 Starting High-Quality Video Face Swap (PixVerse)...');
      
      if (apiKey.isEmpty) throw Exception('FAL AI API key is empty');

      // 1. Submit the task to the PixVerse swap queue
      final modelId = 'fal-ai/pixverse/swap';
      final submitUrl = Uri.parse('https://queue.fal.run/$modelId');
      
      final requestBody = {
        'video_url': templateVideoUrl,
        'image_url': faceImageUrl,
      };

      debugLog('📤 Submitting task to $modelId...');
      final submitResponse = await http.post(
        submitUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugLog('📥 Submit Response Code: ${submitResponse.statusCode}');
      debugLog('📥 Submit Response Body: ${submitResponse.body}');

      if (submitResponse.statusCode != 200 && submitResponse.statusCode != 201) {
        throw Exception('Failed to submit task: ${submitResponse.body}');
      }

      final submitData = jsonDecode(submitResponse.body);
      final requestId = submitData['request_id'];
      final statusUrlFromApi = submitData['status_url'];
      final responseUrlFromApi = submitData['response_url']; // Use this for final fetch
      
      debugLog('🆔 Task submitted! Request ID: $requestId');
      debugLog('📋 Status URL: $statusUrlFromApi');
      debugLog('📋 Response URL: $responseUrlFromApi');

      // 2. Poll for status using the URL provided by the API, or construct it
      final statusUrl = statusUrlFromApi != null 
          ? Uri.parse(statusUrlFromApi)
          : Uri.parse('https://queue.fal.run/$modelId/requests/$requestId/status');
      
      debugLog('⏳ Polling via: $statusUrl');
      
      int attempts = 0;
      const maxAttempts = 120; // 10 minutes max (5s * 120)
      String finalStatus = '';

      while (attempts < maxAttempts) {
        attempts++;
        debugLog('⏳ Polling status (Attempt $attempts/$maxAttempts)...');
        
        try {
          final statusResponse = await http.get(
            statusUrl,
            headers: {'Authorization': 'Key $apiKey'},
          ).timeout(const Duration(seconds: 10));

          debugLog('📊 Status Response Code: ${statusResponse.statusCode}');

          if (statusResponse.statusCode == 200 || statusResponse.statusCode == 202) {
            final statusData = jsonDecode(statusResponse.body);
            final status = statusData['status'];
            finalStatus = status;
            debugLog('📊 Current Status: $status');

            if (status == 'COMPLETED') {
              debugLog('✅ Seedance task COMPLETED!');
              final bodyPreview = statusResponse.body.length > 1000
                  ? statusResponse.body.substring(0, 1000)
                  : statusResponse.body;
              debugLog('📊 Full COMPLETED response: $bodyPreview');

              // The Fal queue API returns the full result in the final status poll
              // Try to extract video directly from status response
              final response = statusData['response'] ?? statusData;
              if (response is Map<String, dynamic>) {
                debugLog('📋 Status response keys: ${response.keys}');
                if (response['video'] != null) {
                  final video = response['video'];
                  if (video is Map && video['url'] != null) {
                    debugLog('✅ Video URL from status response: ${video['url']}');
                    return video['url'];
                  } else if (video is String) {
                    debugLog('✅ Video URL from status response: $video');
                    return video;
                  }
                }
                if (response['video_url'] != null) {
                  debugLog('✅ Video URL from status response: ${response['video_url']}');
                  return response['video_url'];
                }
              }

              // If not in status response, proceed to result URL fetch
              break;
            } else if (status == 'FAILED') {
              throw Exception('Seedance task failed: ${statusData['error'] ?? 'Unknown error'}');
            } else {
              debugLog('⏳ Task still in progress ($status)...');
            }
          } else if (statusResponse.statusCode == 404) {
            debugLog('⚠️ Result not found yet (404). Request may still be processing...');
            // Don't throw, just retry
          } else {
            debugLog('⚠️ Unexpected status response: ${statusResponse.statusCode}');
            // Allow transient errors during polling
          }
        } catch (e) {
          debugLog('⚠️ Polling error (attempt $attempts): $e');
          // Continue polling on transient errors
        }

        await Future.delayed(const Duration(seconds: 5));
      }

      debugLog('📊 Final status after polling: $finalStatus');

      // 3. Fetch the final result - Use the response_url which is the correct endpoint
      final responseUrl = responseUrlFromApi;
      final finalResultUrl = responseUrl != null 
          ? Uri.parse(responseUrl)
          : Uri.parse('https://queue.fal.run/$modelId/requests/$requestId');
      
      debugLog('📥 Fetching final result from $finalResultUrl...');
      
      final resultResponse = await http.get(
        finalResultUrl,
        headers: {'Authorization': 'Key $apiKey'},
      );

      debugLog('📥 Result Response Code: ${resultResponse.statusCode}');
      final resultBodyPreview = resultResponse.body.length > 300 
          ? resultResponse.body.substring(0, 300) 
          : resultResponse.body;
      debugLog('📥 Result Response: $resultBodyPreview');

      if (resultResponse.statusCode == 200) {
        final resultData = jsonDecode(resultResponse.body);
        final response = resultData['response'] ?? resultData;
        
        debugLog('📋 Response keys: ${response.keys}');
        
        if (response['video'] != null) {
          final video = response['video'];
          if (video is Map && video['url'] != null) {
            final videoUrl = video['url'];
            debugLog('✅ Face swap completed: $videoUrl');
            return videoUrl;
          } else if (video is String) {
            debugLog('✅ Face swap completed: $video');
            return video;
          }
        }
        
        if (response['video_url'] != null) {
          final videoUrl = response['video_url'];
          debugLog('✅ Face swap completed: $videoUrl');
          return videoUrl;
        }
        
        if (response['output'] != null) {
          final output = response['output'];
          if (output is Map && output['video'] != null) {
            debugLog('✅ Face swap completed: ${output['video']}');
            return output['video'].toString();
          }
        }
        
        debugLog('❌ Response structure: ${jsonEncode(response).substring(0, 200)}');
        throw Exception('No video URL found in response. Keys: ${response.keys}');
      } else if (resultResponse.statusCode == 202) {
        // Still processing
        debugLog('⏳ Task still processing. Max attempts reached.');
        throw Exception('Task still processing after max polling attempts');
      } else {
        throw Exception('Failed to fetch final result: ${resultResponse.statusCode} - ${resultResponse.body.substring(0, 200)}');
      }
    } catch (e) {
      debugLog('❌ Face Swap Error: $e');
      rethrow;
    }
  }

  /// Generate video from a single image with a prompt (image-to-video)
  /// Tries Seedance 2.0 first, then falls back to Kling, then MiniMax
  Future<String> generateVideoFromImage({
    required String imageUrl,
    required String prompt,
    int? durationSeconds,
  }) async {
    // Try Seedance 2.0 first (primary)
    try {
      debugLog('🎬 Trying Seedance 2.0 first...');
      return await generateVideoFromSeedance(
        imageUrl: imageUrl,
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugLog('⚠️ Seedance failed, trying Kling v3: $e');
    }

    // Fallback to Kling v3
    try {
      return await generateVideoFromKling(
        imageUrl: imageUrl,
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugLog('⚠️ Kling failed, trying MiniMax: $e');
    }

    // Fallback to MiniMax
    return _generateVideoMiniMax(imageUrl: imageUrl, prompt: prompt);
  }

  /// Public Kling 3.0 Pro video generation via FAL AI API (fal-ai/kling-video/v3/pro/image-to-video)
  Future<String> generateVideoFromKling({
    required String imageUrl,
    required String prompt,
    int? durationSeconds,
    String? model,
  }) async {
    try {
      final modelId = model ?? 'fal-ai/kling-video/v3/pro/image-to-video';
      debugLog('🎬 Calling FAL AI Kling API ($modelId)...');

      if (apiKey.isEmpty) throw Exception('FAL AI API key is empty');

      final submitUrl = Uri.parse('https://queue.fal.run/$modelId');

      final requestBody = {
        'prompt': prompt,
        'image_url': imageUrl,
        'duration': (durationSeconds ?? 5).toString(),
        'negative_prompt':
            'plastic skin, CGI, 3D render, cartoon, airbrushed, oversaturated, morphing, rubbery face, distorted eyes, extra limbs, blurry, jitter, robotic motion, unnatural physics, synthetic, video game, low quality, artifacts, watermark',
        'generate_audio': false,
      };

      debugLog('📤 Submitting Kling task to FAL AI...');
      final submitResponse = await http.post(
        submitUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugLog('📥 Submit Response Code: ${submitResponse.statusCode}');
      debugLog('📥 Submit Response Body: ${submitResponse.body}');

      if (submitResponse.statusCode != 200 && submitResponse.statusCode != 201) {
        final body = jsonDecode(submitResponse.body);
        final errorMsg = body['detail'] != null && body['detail'] is List && (body['detail'] as List).isNotEmpty
            ? body['detail'][0]['msg']
            : (body['message'] ?? submitResponse.body);
        throw Exception('FAL AI Kling error (${submitResponse.statusCode}): $errorMsg');
      }

      final submitData = jsonDecode(submitResponse.body);
      final requestId = submitData['request_id'];
      final statusUrlFromApi = submitData['status_url'];
      final responseUrlFromApi = submitData['response_url'];

      debugLog('🆔 Kling Task submitted to FAL AI! Request ID: $requestId');

      final statusUrl = statusUrlFromApi != null
          ? Uri.parse(statusUrlFromApi)
          : Uri.parse('https://queue.fal.run/$modelId/requests/$requestId/status');

      int attempts = 0;
      const maxAttempts = 120; // 10 minutes max

      while (attempts < maxAttempts) {
        attempts++;
        debugLog('⏳ Polling FAL AI Kling status (Attempt $attempts/$maxAttempts)...');

        try {
          final statusResponse = await http.get(
            statusUrl,
            headers: {'Authorization': 'Key $apiKey'},
          ).timeout(const Duration(seconds: 10));

          if (statusResponse.statusCode == 200 || statusResponse.statusCode == 202) {
            final statusData = jsonDecode(statusResponse.body);
            final status = statusData['status'];

            if (status == 'COMPLETED') {
              debugLog('✅ FAL AI Kling task COMPLETED!');
              final response = statusData['response'] ?? statusData;
              if (response is Map<String, dynamic>) {
                if (response['video'] != null) {
                  final video = response['video'];
                  if (video is Map && video['url'] != null) return video['url'].toString();
                  if (video is String) return video;
                }
                if (response['video_url'] != null) return response['video_url'].toString();
              }
              break;
            } else if (status == 'FAILED') {
              final errorMsg = statusData['error'] ?? 'Unknown error';
              throw Exception('FAL AI Kling task failed: $errorMsg');
            }
          }
        } catch (e) {
          debugLog('⚠️ Polling error: $e');
        }

        await Future.delayed(const Duration(seconds: 5));
      }

      final responseUrl = responseUrlFromApi != null
          ? Uri.parse(responseUrlFromApi)
          : Uri.parse('https://queue.fal.run/$modelId/requests/$requestId');

      final resultResponse = await http.get(
        responseUrl,
        headers: {'Authorization': 'Key $apiKey'},
      );

      if (resultResponse.statusCode == 200) {
        final resultData = jsonDecode(resultResponse.body);
        final response = resultData['response'] ?? resultData;
        if (response['video'] != null) {
          final video = response['video'];
          if (video is Map && video['url'] != null) return video['url'].toString();
          if (video is String) return video;
        }
        if (response['video_url'] != null) return response['video_url'].toString();
      }

      throw Exception('FAL AI Kling error: Failed to retrieve video URL from result endpoint');
    } catch (e) {
      debugLog('❌ FAL AI Kling Error: $e');
      rethrow;
    }
  }

  /// Generate video from image using Direct Seedance 2.0 with automatic Kling 3.0 Pro fallback
  Future<String> generateVideoFromSeedance({
    required String imageUrl,
    required String prompt,
    int? durationSeconds,
  }) async {
    try {
      debugLog('🎬 Calling Direct Seedance 2.0 API (ByteDance ModelArk)...');
      return await SeedanceAiService.generateVideoFromImage(
        imageUrl: imageUrl,
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugLog('⚠️ Seedance failed ($e). Falling back to Kling 3.0 Pro...');
      return await generateVideoFromKling(
        imageUrl: imageUrl,
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
    }
  }

  /// Fallback video generation using MiniMax
  Future<String> _generateVideoMiniMax({
    required String imageUrl,
    required String prompt,
  }) async {
    final url = Uri.parse('https://queue.fal.run/fal-ai/minimax-video');

    final requestBody = {
      'prompt': prompt,
      'image_url': imageUrl,
    };

    debugLog('📤 Submitting to MiniMax...');

    final submitResponse = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (submitResponse.statusCode != 200 && submitResponse.statusCode != 201) {
      throw Exception('Failed to submit task: ${submitResponse.body}');
    }

    final submitData = jsonDecode(submitResponse.body);
    final requestId = submitData['request_id'];
    final statusUrl = submitData['status_url'];
    final responseUrl = submitData['response_url'];

    // Poll for completion
    final pollUrl = statusUrl != null
        ? Uri.parse(statusUrl)
        : Uri.parse('https://queue.fal.run/fal-ai/minimax-video/requests/$requestId/status');

    int attempts = 0;
    const maxAttempts = 120;

    while (attempts < maxAttempts) {
      attempts++;

      try {
        final statusResponse = await http.get(
          pollUrl,
          headers: {'Authorization': 'Key $apiKey'},
        ).timeout(const Duration(seconds: 10));

        if (statusResponse.statusCode == 200 || statusResponse.statusCode == 202) {
          final statusData = jsonDecode(statusResponse.body);
          final status = statusData['status'];

          if (status == 'COMPLETED') {
            break;
          } else if (status == 'FAILED') {
            throw Exception('Video generation failed');
          }
        }
      } catch (e) {
        debugLog('⚠️ Polling error: $e');
      }

      await Future.delayed(const Duration(seconds: 5));
    }

    // Fetch final result
    final finalUrl = responseUrl != null
        ? Uri.parse(responseUrl)
        : Uri.parse('https://queue.fal.run/fal-ai/minimax-video/requests/$requestId');

    final resultResponse = await http.get(
      finalUrl,
      headers: {'Authorization': 'Key $apiKey'},
    );

    if (resultResponse.statusCode == 200) {
      final resultData = jsonDecode(resultResponse.body);
      final response = resultData['response'] ?? resultData;

      if (response['video'] != null) {
        final video = response['video'];
        if (video is Map && video['url'] != null) {
          return video['url'];
        } else if (video is String) {
          return video;
        }
      }

      if (response['video_url'] != null) {
        return response['video_url'];
      }

      throw Exception('No video URL in response');
    } else {
      throw Exception('Failed to fetch result');
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

  /// Clone a voice from a sample audio and generate speech from text
  /// Uses Dia TTS voice clone endpoint (synchronous with long timeout)
  Future<String> cloneAndGenerateSpeech({
    required String voiceSampleUrl,
    required String script,
  }) async {
    try {
      debugLog('🎤 Starting voice clone + speech generation with Fal AI...');

      if (apiKey.isEmpty) {
        throw Exception('FAL AI API key is empty');
      }

      final url = Uri.parse('https://fal.run/fal-ai/dia-tts/voice-clone');
      final requestBody = {
        'ref_audio_url': voiceSampleUrl,
        'ref_text': script,
        'text': script,
      };

      debugLog('📤 Sending voice clone request to Fal AI...');
      debugLog('📊 Endpoint: $url');
      debugLog('📊 Script length: ${script.length} chars');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $apiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          throw Exception('Fal AI voice clone request timeout (10 minutes)');
        },
      );

      debugLog('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugLog('📊 Response keys: ${data.keys.toList()}');
        final audioUrl = data['audio_url'] ?? data['url'] ?? data['audio']?['url'];
        if (audioUrl != null) {
          debugLog('✅ Voice cloned and speech generated: $audioUrl');
          return audioUrl.toString();
        }
        throw Exception('No audio URL in response: ${response.body}');
      } else {
        throw Exception('Fal AI voice clone error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugLog('❌ Error in cloneAndGenerateSpeech: $e');
      rethrow;
    }
  }
}
