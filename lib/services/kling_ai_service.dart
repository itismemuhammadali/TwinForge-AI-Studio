import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Direct Kling AI API Service (https://api.klingai.com)
class KlingAiService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static String get _apiKey {
    final key = _remoteConfig.getString('kling_api_key');
    if (key.isNotEmpty) return key;
    return 'api-key-kling-WEOS-jl-ceruTx3ZUnChsr6g8MoxkQQLcgJkaQRdzRU';
  }

  static void _log(String msg) {
    debugPrint('[KlingAiService] $msg');
  }

  /// Generate video directly using Kling AI API (https://api.klingai.com/v1/videos/image2video)
  static Future<String> generateVideoFromImage({
    required String imageUrl,
    required String prompt,
    int? durationSeconds,
  }) async {
    final apiKey = _apiKey;
    _log('📤 Submitting image2video task directly to Kling AI API...');

    final submitUrl = Uri.parse('https://api.klingai.com/v1/videos/image2video');
    final payload = {
      'model_name': 'kling-v1-6',
      'image': imageUrl,
      'prompt': prompt,
      'negative_prompt':
          'plastic skin, CGI, 3D render, cartoon, airbrushed, oversaturated, morphing, rubbery face, distorted eyes, extra limbs, blurry, jitter, robotic motion, unnatural physics, synthetic, video game, low quality, artifacts, watermark',
      'duration': (durationSeconds ?? 5).toString(),
      'mode': 'pro',
      'sound': 'off',
    };

    final submitResponse = await http.post(
      submitUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(payload),
    );

    _log('📥 Kling Direct Submit Code: ${submitResponse.statusCode}');
    _log('📥 Kling Direct Submit Body: ${submitResponse.body}');

    if (submitResponse.statusCode != 200 && submitResponse.statusCode != 201) {
      final body = jsonDecode(submitResponse.body);
      if (body['code'] == 1102 || (body['message'] ?? '').contains('balance')) {
        throw Exception('Kling AI API balance is exhausted (Code 1102). Please add credits to your Kling AI account or switch to Seedance 2.0.');
      }
      throw Exception('Kling AI Submit Error (${submitResponse.statusCode}): ${body['message'] ?? submitResponse.body}');
    }

    final submitData = jsonDecode(submitResponse.body);
    if (submitData['code'] != 0 && submitData['code'] != null) {
      if (submitData['code'] == 1102) {
        throw Exception('Kling AI API balance is exhausted (Code 1102). Please add credits to your Kling AI account or switch to Seedance 2.0.');
      }
      throw Exception('Kling AI Submit Error: ${submitData['message']}');
    }

    final taskId = submitData['data']?['task_id'];
    if (taskId == null || taskId.toString().isEmpty) {
      throw Exception('Kling AI did not return a valid task_id.');
    }

    _log('🆔 Task created successfully! Task ID: $taskId');

    // Poll Task Status
    final pollUrl = Uri.parse('https://api.klingai.com/v1/videos/image2video/$taskId');
    int attempts = 0;
    const maxAttempts = 120;

    while (attempts < maxAttempts) {
      attempts++;
      await Future.delayed(const Duration(seconds: 4));

      try {
        final pollResponse = await http.get(
          pollUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ).timeout(const Duration(seconds: 10));

        if (pollResponse.statusCode == 200) {
          final pollData = jsonDecode(pollResponse.body);
          final data = pollData['data'];
          final status = data?['task_status'];

          _log('📊 Kling Task Status: $status (Attempt $attempts)');

          if (status == 'succeed') {
            final videos = data['task_result']?['videos'] as List?;
            if (videos != null && videos.isNotEmpty) {
              final videoUrl = videos[0]['url'];
              if (videoUrl != null && videoUrl.toString().isNotEmpty) {
                _log('🎉 Kling Video Generation Succeeded: $videoUrl');
                return videoUrl.toString();
              }
            }
            throw Exception('Kling task succeeded but video URL was empty.');
          }

          if (status == 'failed') {
            final msg = data?['task_status_msg'] ?? 'Unknown error';
            throw Exception('Kling video generation failed: $msg');
          }
        }
      } catch (e) {
        if (e.toString().contains('balance') || e.toString().contains('succeeded')) {
          rethrow;
        }
        _log('⚠️ Polling retry attempt $attempts: $e');
      }
    }

    throw Exception('Kling video generation timed out after 8 minutes.');
  }
}
