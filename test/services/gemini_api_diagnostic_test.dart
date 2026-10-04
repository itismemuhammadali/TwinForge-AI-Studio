import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ai_video_image_generation_app/services/gemini_service.dart';

import 'dart:io';

void main() {
  HttpOverrides.global = null;


  group('Gemini API Diagnostic Test', () {
    test('Verifies live Gemini API key connectivity against Google API', () async {
      final envKey = const String.fromEnvironment('GEMINI_API_KEY');
      if (envKey.isNotEmpty) {
        GeminiService.apiKey = envKey;
      }
      final key = GeminiService.effectiveApiKey;
      if (key.isEmpty) {
        print('[Diagnostic] Skipping test: No GEMINI_API_KEY provided in env and Remote Config not initialized in CLI test runner');
        return;
      }

      print('\n[Diagnostic] Testing Gemini API Key (${key.length} chars)');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
      );

      final response = await http.get(url);
      print('[Diagnostic] Status Code: ${response.statusCode}');
      print('[Diagnostic] Response Body:\n${response.body}\n');

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final error = body['error'] as Map<String, dynamic>?;
        final message = error?['message'] ?? 'Unknown error';
        final status = error?['status'] ?? 'Unknown status';
        print('[Diagnostic Alert] Google rejected key with Status: $status, Message: $message');
      }

      // Assert whether key is active (200 OK)
      expect(
        response.statusCode,
        equals(200),
        reason: 'Gemini API returned status ${response.statusCode}: ${response.body}',
      );
    });
  });
}
