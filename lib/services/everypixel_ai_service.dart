import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service for Everypixel Labs Lip-Sync AI Engine (labs.everypixel.com)
/// High-efficiency, ultra low-cost ($0.30 / 60s) neural lip-sync generation.
class EverypixelAiService {
  static const String _defaultEndpoint = 'https://api.everypixel.com/v1/lipsync';

  static void _log(String msg) {
    debugPrint('[EverypixelAiService] $msg');
  }

  /// Generates a lip-synced talking head video by mapping audio to a source video.
  static Future<String> generateLipSyncVideo({
    required String videoUrl,
    required String audioUrl,
    Function(String progressMessage)? onProgress,
  }) async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();

    final clientId = remoteConfig.getString('everypixel_client_id').trim();
    final secretKey = remoteConfig.getString('everypixel_secret_key').trim();
    final endpoint = remoteConfig.getString('everypixel_api_endpoint').trim().isNotEmpty
        ? remoteConfig.getString('everypixel_api_endpoint').trim()
        : _defaultEndpoint;

    if (clientId.isEmpty || secretKey.isEmpty) {
      throw Exception(
        'Everypixel Labs credentials not configured. Please add everypixel_client_id and everypixel_secret_key in Firebase Remote Config.',
      );
    }

    _log('🎬 Submitting Lip-Sync job to Everypixel Labs ($endpoint)...');
    onProgress?.call('Submitting audio & video to Everypixel Labs...');

    final basicAuth = base64Encode(utf8.encode('$clientId:$secretKey'));
    final headers = {
      'Authorization': 'Basic $basicAuth',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final requestBody = jsonEncode({
      'video_url': videoUrl,
      'audio_url': audioUrl,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: requestBody,
    );

    _log('📥 Everypixel submit response status: ${response.statusCode}');
    _log('📥 Everypixel submit response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 202) {
      throw Exception('Everypixel API error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);

    // Direct result if returned synchronously
    if (data is Map<String, dynamic>) {
      final directVideoUrl = data['result']?['video_url'] ?? data['video_url'] ?? data['output_url'];
      if (directVideoUrl != null && directVideoUrl.toString().isNotEmpty) {
        _log('✅ Everypixel Lip-Sync finished synchronously: $directVideoUrl');
        return directVideoUrl.toString();
      }

      // Asynchronous task ID
      final taskId = data['id'] ?? data['task_id'] ?? data['job_id'] ?? data['request_id'];
      if (taskId == null) {
        // Some endpoints return the status URL directly
        final statusUrl = data['status_url'] ?? data['url'];
        if (statusUrl != null) {
          return await _pollStatusUrl(statusUrl.toString(), headers, onProgress);
        }
        throw Exception('No Task ID or Output Video received in Everypixel response.');
      }

      _log('🆔 Everypixel Task ID: $taskId. Polling for completion...');
      return await _pollTaskId(taskId.toString(), endpoint, headers, onProgress);
    }

    throw Exception('Unexpected response format from Everypixel Labs.');
  }

  /// Polls Everypixel status by Task ID
  static Future<String> _pollTaskId(
    String taskId,
    String baseEndpoint,
    Map<String, String> headers,
    Function(String progressMessage)? onProgress,
  ) async {
    final statusUri = Uri.parse('$baseEndpoint/$taskId');
    int attempts = 0;
    const maxAttempts = 120; // 10 minutes max (5s intervals)

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;

      try {
        final res = await http.get(statusUri, headers: headers);
        _log('⏳ Everypixel Polling ($attempts/$maxAttempts): status ${res.statusCode}');

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final status = (data['status'] ?? data['state'] ?? '').toString().toUpperCase();

          _log('📊 Everypixel Task Status: $status');
          onProgress?.call('Everypixel AI Lip-Sync in progress... ($status)');

          if (status == 'COMPLETED' || status == 'SUCCESS' || status == 'DONE') {
            final outputUrl = data['result']?['video_url'] ??
                data['video_url'] ??
                data['output_url'] ??
                data['result_url'] ??
                data['url'];
            if (outputUrl != null && outputUrl.toString().isNotEmpty) {
              _log('✅ Everypixel Lip-Sync completed: $outputUrl');
              return outputUrl.toString();
            }
          }

          if (status == 'FAILED' || status == 'ERROR' || status == 'REJECTED') {
            final errorMsg = data['error'] ?? data['message'] ?? 'Task processing failed';
            throw Exception('Everypixel processing error: $errorMsg');
          }
        }
      } catch (e) {
        _log('⚠️ Polling attempt $attempts error: $e');
        if (e.toString().contains('Everypixel processing error')) rethrow;
      }
    }

    throw Exception('Everypixel Lip-Sync timed out after 10 minutes.');
  }

  /// Polls status URL directly
  static Future<String> _pollStatusUrl(
    String statusUrl,
    Map<String, String> headers,
    Function(String progressMessage)? onProgress,
  ) async {
    int attempts = 0;
    const maxAttempts = 120;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;

      try {
        final res = await http.get(Uri.parse(statusUrl), headers: headers);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final status = (data['status'] ?? data['state'] ?? '').toString().toUpperCase();

          onProgress?.call('Everypixel AI Lip-Sync in progress... ($status)');

          if (status == 'COMPLETED' || status == 'SUCCESS' || status == 'DONE') {
            final outputUrl = data['result']?['video_url'] ?? data['video_url'] ?? data['output_url'] ?? data['url'];
            if (outputUrl != null) return outputUrl.toString();
          }

          if (status == 'FAILED' || status == 'ERROR') {
            throw Exception('Everypixel processing failed: ${data['error'] ?? data['message']}');
          }
        }
      } catch (e) {
        if (e.toString().contains('Everypixel processing failed')) rethrow;
      }
    }

    throw Exception('Everypixel Lip-Sync timed out.');
  }
}
