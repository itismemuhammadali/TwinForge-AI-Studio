import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class HiggsfieldService {
  static final HiggsfieldService _instance = HiggsfieldService._internal();
  factory HiggsfieldService() => _instance;
  HiggsfieldService._internal();

  static const String _baseUrl = 'https://platform.higgsfield.ai';
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String? _apiKey;
  String? _apiSecret;

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _apiSecret != null && _apiSecret!.isNotEmpty;

  /// Initialize Higgsfield Service with API keys from Firebase Remote Config
  static Future<void> initialize() async {
    try {
      _log('Initializing Higgsfield Service...');

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );

      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('Remote Config fetch timed out');
          return false;
        },
      );

      final apiKey = _remoteConfig.getString('higgsfield_api_key');
      final apiSecret = _remoteConfig.getString('higgsfield_api_secret');

      _instance._apiKey = apiKey;
      _instance._apiSecret = apiSecret;

      if (apiKey.isNotEmpty && apiSecret.isNotEmpty) {
        _log('Higgsfield API keys loaded successfully');
      } else {
        _log('Higgsfield API keys missing in Remote Config');
      }
    } catch (e) {
      _log('Error initializing Higgsfield Service: $e');
    }
  }

  String get _authHeader => 'Key $_apiKey:$_apiSecret';

  Map<String, String> get _headers => {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static void _log(String message) {
    developer.log('[Higgsfield] $message');
  }

  /// Generate image from text prompt
  Future<HiggsfieldImageResult> generateImage({
    required String prompt,
    String model = 'higgsfield-ai/soul/standard',
    String aspectRatio = '1:1',
    String resolution = '720p',
    bool cameraFixed = false,
  }) async {
    if (!isConfigured) throw Exception('Higgsfield service not configured');

    _log('Generating image with model: $model');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/$model'),
          headers: _headers,
          body: jsonEncode({
            'prompt': prompt,
            'aspect_ratio': aspectRatio,
            'resolution': resolution,
            'camera_fixed': cameraFixed,
          }),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _log('Image generation queued: ${data['request_id']}');
      return HiggsfieldImageResult.fromJson(data);
    } else {
      _log('Image generation failed: ${response.statusCode} ${response.body}');
      throw Exception('Image generation failed: ${response.statusCode}');
    }
  }

  /// Generate video from image
  Future<HiggsfieldVideoResult> generateVideo({
    required String imageUrl,
    required String model,
    String? prompt,
    int duration = 5,
  }) async {
    if (!isConfigured) throw Exception('Higgsfield service not configured');

    _log('Generating video with model: $model');

    final body = <String, dynamic>{
      'image_url': imageUrl,
      'duration': duration,
    };
    if (prompt != null) body['prompt'] = prompt;

    final response = await http
        .post(
          Uri.parse('$_baseUrl/$model'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(minutes: 10));

    if (response.statusCode == 200 || response.statusCode == 202) {
      final data = jsonDecode(response.body);
      _log('Video generation queued: ${data['request_id']}');
      return HiggsfieldVideoResult.fromJson(data);
    } else {
      _log('Video generation failed: ${response.statusCode} ${response.body}');
      throw Exception('Video generation failed: ${response.statusCode}');
    }
  }

  /// Check request status
  Future<HiggsfieldStatus> checkStatus(String requestId) async {
    if (!isConfigured) throw Exception('Higgsfield service not configured');

    final response = await http.get(
      Uri.parse('$_baseUrl/requests/$requestId/status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return HiggsfieldStatus.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Status check failed: ${response.statusCode}');
    }
  }

  /// Poll until request completes
  Future<HiggsfieldStatus> waitForCompletion(
    String requestId, {
    Duration pollInterval = const Duration(seconds: 5),
    Duration maxWait = const Duration(minutes: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < maxWait) {
      final status = await checkStatus(requestId);

      if (status.isCompleted || status.isFailed || status.isNsfw) {
        return status;
      }

      await Future.delayed(pollInterval);
    }

    throw Exception('Request timed out after $maxWait');
  }

  /// Cancel a queued request
  Future<void> cancelRequest(String requestId) async {
    if (!isConfigured) throw Exception('Higgsfield service not configured');

    final response = await http.post(
      Uri.parse('$_baseUrl/requests/$requestId/cancel'),
      headers: _headers,
    );

    if (response.statusCode != 202) {
      throw Exception('Cancel failed: ${response.statusCode}');
    }
    _log('Request cancelled: $requestId');
  }
}

class HiggsfieldImageResult {
  final String status;
  final String requestId;
  final String statusUrl;
  final String cancelUrl;

  HiggsfieldImageResult({
    required this.status,
    required this.requestId,
    required this.statusUrl,
    required this.cancelUrl,
  });

  factory HiggsfieldImageResult.fromJson(Map<String, dynamic> json) {
    return HiggsfieldImageResult(
      status: json['status'] ?? '',
      requestId: json['request_id'] ?? '',
      statusUrl: json['status_url'] ?? '',
      cancelUrl: json['cancel_url'] ?? '',
    );
  }
}

class HiggsfieldVideoResult {
  final String status;
  final String requestId;
  final String statusUrl;
  final String cancelUrl;

  HiggsfieldVideoResult({
    required this.status,
    required this.requestId,
    required this.statusUrl,
    required this.cancelUrl,
  });

  factory HiggsfieldVideoResult.fromJson(Map<String, dynamic> json) {
    return HiggsfieldVideoResult(
      status: json['status'] ?? '',
      requestId: json['request_id'] ?? '',
      statusUrl: json['status_url'] ?? '',
      cancelUrl: json['cancel_url'] ?? '',
    );
  }
}

class HiggsfieldStatus {
  final String status;
  final String requestId;
  final List<HiggsfieldImage> images;
  final HiggsfieldVideo? video;

  HiggsfieldStatus({
    required this.status,
    required this.requestId,
    this.images = const [],
    this.video,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isNsfw => status == 'nsfw';
  bool get isQueued => status == 'queued';
  bool get isInProgress => status == 'in_progress';

  factory HiggsfieldStatus.fromJson(Map<String, dynamic> json) {
    return HiggsfieldStatus(
      status: json['status'] ?? '',
      requestId: json['request_id'] ?? '',
      images: (json['images'] as List?)
              ?.map((e) => HiggsfieldImage.fromJson(e))
              .toList() ??
          [],
      video: json['video'] != null
          ? HiggsfieldVideo.fromJson(json['video'])
          : null,
    );
  }
}

class HiggsfieldImage {
  final String url;

  HiggsfieldImage({required this.url});

  factory HiggsfieldImage.fromJson(Map<String, dynamic> json) {
    return HiggsfieldImage(url: json['url'] ?? '');
  }
}

class HiggsfieldVideo {
  final String url;

  HiggsfieldVideo({required this.url});

  factory HiggsfieldVideo.fromJson(Map<String, dynamic> json) {
    return HiggsfieldVideo(url: json['url'] ?? '');
  }
}
