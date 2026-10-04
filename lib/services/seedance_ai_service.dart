import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'fal_ai_service.dart';

/// Direct Seedance 2.0 API Service (ByteDance Volcengine Ark API)
class SeedanceAiService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static String get _apiKey {
    return _remoteConfig.getString('seedance_api_key').trim();
  }

  static String get _endpointId25 {
    return _remoteConfig.getString('seedance_25_endpoint_id').trim();
  }

  static String get _endpointId20 {
    return _remoteConfig.getString('seedance_20_endpoint_id').trim();
  }

  static void _log(String msg) {
    debugPrint('[SeedanceAiService] $msg');
  }

  /// Direct Seedance 2.5/2.0 Image-to-Video generation using BytePlus ModelArk API
  static Future<String> generateVideoFromImage({
    required String imageUrl,
    required String prompt,
    int? durationSeconds,
  }) async {
    final apiKey = _apiKey;
    
    // Priority 1: Try Seedance 2.5 Endpoint
    try {
      _log('🎬 Priority 1: Trying Seedance 2.5 Endpoint ($_endpointId25)...');
      return await _submitBytePlusTask(
        apiKey: apiKey,
        modelId: _endpointId25,
        imageUrl: imageUrl,
        prompt: prompt,
      );
    } catch (e25) {
      _log('⚠️ Seedance 2.5 failed ($e25). Priority 2: Trying Seedance 2.0 Endpoint ($_endpointId20)...');
    }

    // Priority 2: Try Seedance 2.0 Endpoint
    try {
      return await _submitBytePlusTask(
        apiKey: apiKey,
        modelId: _endpointId20,
        imageUrl: imageUrl,
        prompt: prompt,
      );
    } catch (e20) {
      _log('⚠️ Seedance 2.0 failed ($e20). Priority 3: Falling back to FAL AI Seedance Engine...');
    }

    // Priority 3: Fallback to FAL AI Seedance Engine
    try {
      return await _generateViaFalAi(imageUrl: imageUrl, prompt: prompt, durationSeconds: durationSeconds);
    } catch (eFal) {
      _log('⚠️ Seedance failed ($eFal). Priority 4: Falling back to Kling 3.0 Pro...');
      return await FalAiService().generateVideoFromKling(
        imageUrl: imageUrl,
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
    }
  }

  static Future<String> _submitBytePlusTask({
    required String apiKey,
    required String modelId,
    required String imageUrl,
    required String prompt,
  }) async {
    final submitUrl = Uri.parse('https://ark.ap-southeast.bytepluses.com/api/v3/contents/generations/tasks');
    final payload = {
      'model': modelId,
      'content': [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image_url',
          'image_url': {'url': imageUrl},
        },
      ],
    };

    final submitResponse = await http.post(
      submitUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    _log('📥 BytePlus ($modelId) Response: ${submitResponse.statusCode}');
    if (submitResponse.statusCode == 200 || submitResponse.statusCode == 201) {
      final data = jsonDecode(submitResponse.body);
      if (data['video_url'] != null) return data['video_url'];
      if (data['content']?['video_url'] != null) return data['content']['video_url'];
      if (data['data']?['video_url'] != null) return data['data']['video_url'];

      final taskId = data['id'] ?? data['task_id'] ?? data['data']?['id'] ?? data['data']?['task_id'];
      if (taskId != null) {
        _log('⏳ Seedance Task ID created: $taskId. Polling status...');
        return _pollTaskStatus(taskId.toString(), apiKey);
      }
    }
    throw Exception('BytePlus $modelId failed with status ${submitResponse.statusCode}: ${submitResponse.body}');
  }

  static Future<String> _pollTaskStatus(String taskId, String apiKey) async {
    final pollUrl = Uri.parse('https://ark.ap-southeast.bytepluses.com/api/v3/contents/generations/tasks/$taskId');
    int attempts = 0;
    const maxAttempts = 120; // 120 * 4 seconds = 8 minutes max

    while (attempts < maxAttempts) {
      attempts++;
      await Future.delayed(const Duration(seconds: 4));

      try {
        final resp = await http.get(
          pollUrl,
          headers: {'Authorization': 'Bearer $apiKey'},
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          _log('⏳ Seedance Polling [$attempts/$maxAttempts]: Status = ${data['status']}');

          final status = data['status'] ?? data['data']?['status'];
          if (status == 'succeeded' || status == 'succeed' || status == 'completed') {
            // Find video URL in content/results
            final content = data['content'] ?? data['data']?['content'] ?? data['results'];
            if (content is List && content.isNotEmpty) {
              for (var item in content) {
                if (item['type'] == 'video_url' && item['video_url']?['url'] != null) {
                  return item['video_url']['url'];
                }
                if (item['url'] != null) return item['url'];
              }
            }
            if (data['video_url'] != null) return data['video_url'];
          }
          if (status == 'failed') {
            final errorReason = data['error']?['message'] ?? data['message'] ?? 'Task failed';
            throw Exception('Seedance task failed: $errorReason');
          }
        }
      } catch (e) {
        _log('⚠️ Seedance polling attempt $attempts error: $e');
        if (e.toString().contains('Seedance task failed')) rethrow;
      }
    }
    throw Exception('Seedance 2.0 video generation timed out after 8 minutes.');
  }

  /// Fallback generator via FAL AI Seedance 2.0 endpoint
  static Future<String> _generateViaFalAi({
    required String imageUrl,
    required String prompt,
    int? durationSeconds,
  }) async {
    final falKey = _remoteConfig.getString('fal_ai_api_key');
    if (falKey.isEmpty) {
      throw Exception('Direct Seedance key is invalid and fal_ai_api_key is empty.');
    }

    _log('🎬 Generating Seedance 2.0 video via FAL AI endpoint...');
    final url = Uri.parse('https://fal.run/fal-ai/seedance-2/image-to-video');
    final payload = {
      'prompt': prompt,
      'image_url': imageUrl,
      'resolution': '720p',
      'duration': durationSeconds != null ? durationSeconds.toString() : '5',
      'generate_audio': false,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Key $falKey',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(minutes: 5));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['video'] != null) {
        final video = data['video'];
        if (video is Map && video['url'] != null) return video['url'].toString();
        if (video is String) return video;
      }
      if (data['video_url'] != null) return data['video_url'].toString();
    }
    throw Exception('FAL AI Seedance error (${response.statusCode}): ${response.body}');
  }
}
