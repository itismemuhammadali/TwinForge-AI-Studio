import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class StockImage {
  final String id;
  final String title;
  final String imageUrl;
  final String photographer;
  final String source; // 'pexels' or 'pixabay'

  StockImage({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.photographer,
    required this.source,
  });

  factory StockImage.fromPexels(Map<String, dynamic> json) {
    return StockImage(
      id: json['id'].toString(),
      title: json['alt'] ?? 'Stock Image',
      imageUrl: json['src']['medium'] ?? json['src']['original'],
      photographer: json['photographer'] ?? 'Unknown',
      source: 'pexels',
    );
  }

  factory StockImage.fromPixabay(Map<String, dynamic> json) {
    return StockImage(
      id: json['id'].toString(),
      title: json['tags'] ?? 'Stock Image',
      imageUrl: json['webformatURL'] ?? json['largeImageURL'],
      photographer: json['user'] ?? 'Unknown',
      source: 'pixabay',
    );
  }
}

class StockVideo {
  final String id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final String photographer;
  final String source; // 'pexels' or 'pixabay'
  final int duration; // in seconds

  StockVideo({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.photographer,
    required this.source,
    required this.duration,
  });

  factory StockVideo.fromPexels(Map<String, dynamic> json) {
    final videoFiles = json['video_files'] as List?;
    final videoUrl = videoFiles != null && videoFiles.isNotEmpty
        ? videoFiles[0]['link'] ?? ''
        : '';
    
    return StockVideo(
      id: json['id'].toString(),
      title: json['user']['name'] ?? 'Stock Video',
      videoUrl: videoUrl,
      thumbnailUrl: json['image'] ?? '',
      photographer: json['user']['name'] ?? 'Unknown',
      source: 'pexels',
      duration: json['duration'] ?? 0,
    );
  }

  factory StockVideo.fromPixabay(Map<String, dynamic> json) {
    final videos = json['videos'] as Map?;
    final videoUrl = videos != null && videos.isNotEmpty
        ? (videos['medium']?['url'] ?? videos['small']?['url'] ?? '')
        : '';
    
    return StockVideo(
      id: json['id'].toString(),
      title: json['tags'] ?? 'Stock Video',
      videoUrl: videoUrl,
      thumbnailUrl: json['previewURL'] ?? json['userImageURL'] ?? '',
      photographer: json['user'] ?? 'Unknown',
      source: 'pixabay',
      duration: json['duration'] ?? 0,
    );
  }
}

class StockImageService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static late String _pexelsApiKey;
  static late String _pixabayApiKey;
  static bool _initialized = false;

  /// Lazy initialization — only runs once when first needed
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    try {
      // Set default values
      await _remoteConfig.setDefaults({
        'pexels_api_key': '',
        'pixabay_api_key': '',
      });

      // Fetch remote config
      await _remoteConfig.fetchAndActivate();

      // Get API keys from remote config
      _pexelsApiKey = _remoteConfig.getString('pexels_api_key');
      _pixabayApiKey = _remoteConfig.getString('pixabay_api_key');

      if (_pexelsApiKey.isEmpty && _pixabayApiKey.isEmpty) {
        throw Exception('Stock image API keys not configured in Firebase Remote Config');
      }

      debugLog('✅ Stock image API keys loaded from Firebase Remote Config');
      _initialized = true;
    } catch (e) {
      debugLog('❌ Error initializing Stock Image Service: $e');
      rethrow;
    }
  }

  /// Initialize Stock Image Service with API keys from Firebase Remote Config
  static Future<void> initialize() async {
    await _ensureInitialized();
  }

  /// Debug logging helper
  static void debugLog(String message) {
    developer.log('[StockImageService] $message');
  }

  /// Search images from Pexels
  static Future<List<StockImage>> searchPexels({
    required String query,
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pexelsApiKey.isEmpty) {
      throw Exception('Pexels API key not configured');
    }

    try {
      debugLog('📤 Searching Pexels for: "$query"');

      final url = Uri.parse(
        'https://api.pexels.com/v1/search?query=$query&per_page=$perPage&page=$page',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _pexelsApiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pexels API request timeout');
        },
      );

      debugLog('📥 Pexels response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = (data['photos'] as List)
            .map((photo) => StockImage.fromPexels(photo))
            .toList();

        debugLog('✅ Found ${photos.length} images from Pexels');
        return photos;
      } else {
        debugLog('❌ Pexels API Error: ${response.statusCode}');
        throw Exception('Pexels API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error searching Pexels: $e');
      rethrow;
    }
  }

  /// Search images from Pixabay
  static Future<List<StockImage>> searchPixabay({
    required String query,
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pixabayApiKey.isEmpty) {
      throw Exception('Pixabay API key not configured');
    }

    try {
      debugLog('📤 Searching Pixabay for: "$query"');

      final url = Uri.https(
        'pixabay.com',
        '/api/',
        {
          'key': _pixabayApiKey,
          'q': query,
          'per_page': perPage.toString(),
          'page': page.toString(),
          'image_type': 'photo',
        },
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pixabay API request timeout');
        },
      );

      debugLog('📥 Pixabay response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = (data['hits'] as List)
            .map((hit) => StockImage.fromPixabay(hit))
            .toList();

        debugLog('✅ Found ${hits.length} images from Pixabay');
        return hits;
      } else {
        debugLog('❌ Pixabay API Error: ${response.statusCode}');
        throw Exception('Pixabay API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error searching Pixabay: $e');
      rethrow;
    }
  }

  /// Search both Pexels and Pixabay in parallel
  static Future<List<StockImage>> searchBoth({
    required String query,
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    try {
      debugLog('📤 Searching both Pexels and Pixabay for: "$query"');

      final results = await Future.wait([
        _pexelsApiKey.isNotEmpty
            ? searchPexels(query: query, perPage: perPage, page: page)
            : Future.value(<StockImage>[]),
        _pixabayApiKey.isNotEmpty
            ? searchPixabay(query: query, perPage: perPage, page: page)
            : Future.value(<StockImage>[]),
      ]);

      final allImages = [...results[0], ...results[1]];
      debugLog('✅ Found ${allImages.length} total images from both sources');
      return allImages;
    } catch (e) {
      debugLog('❌ Error searching both sources: $e');
      rethrow;
    }
  }

  /// Get trending images from Pexels
  static Future<List<StockImage>> getTrendingPexels({
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pexelsApiKey.isEmpty) {
      throw Exception('Pexels API key not configured');
    }

    try {
      debugLog('📤 Fetching trending images from Pexels');

      final url = Uri.parse(
        'https://api.pexels.com/v1/curated?per_page=$perPage&page=$page',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _pexelsApiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pexels API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = (data['photos'] as List)
            .map((photo) => StockImage.fromPexels(photo))
            .toList();

        debugLog('✅ Found ${photos.length} trending images from Pexels');
        return photos;
      } else {
        throw Exception('Pexels API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error fetching trending Pexels images: $e');
      rethrow;
    }
  }

  /// Get trending images from Pixabay
  static Future<List<StockImage>> getTrendingPixabay({
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pixabayApiKey.isEmpty) {
      throw Exception('Pixabay API key not configured');
    }

    try {
      debugLog('📤 Fetching trending images from Pixabay');

      final url = Uri.https(
        'pixabay.com',
        '/api/',
        {
          'key': _pixabayApiKey,
          'per_page': perPage.toString(),
          'page': page.toString(),
          'image_type': 'photo',
          'order': 'popular',
        },
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pixabay API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = (data['hits'] as List)
            .map((hit) => StockImage.fromPixabay(hit))
            .toList();

        debugLog('✅ Found ${hits.length} trending images from Pixabay');
        return hits;
      } else {
        throw Exception('Pixabay API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error fetching trending Pixabay images: $e');
      rethrow;
    }
  }

  /// Get trending images from both sources
  static Future<List<StockImage>> getTrendingBoth({
    int perPage = 15,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    try {
      final results = await Future.wait([
        _pexelsApiKey.isNotEmpty
            ? getTrendingPexels(perPage: perPage, page: page)
            : Future.value(<StockImage>[]),
        _pixabayApiKey.isNotEmpty
            ? getTrendingPixabay(perPage: perPage, page: page)
            : Future.value(<StockImage>[]),
      ]);

      final allImages = [...results[0], ...results[1]];
      allImages.shuffle();
      return allImages;
    } catch (e) {
      debugLog('❌ Error fetching trending images: $e');
      rethrow;
    }
  }

  /// Get trending videos from Pexels
  static Future<List<StockVideo>> getTrendingPexelsVideos({
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pexelsApiKey.isEmpty) {
      throw Exception('Pexels API key not configured');
    }

    try {
      debugLog('📤 Fetching trending videos from Pexels');

      final url = Uri.parse(
        'https://api.pexels.com/videos/popular?per_page=$perPage&page=$page',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _pexelsApiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pexels API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = (data['videos'] as List)
            .map((video) => StockVideo.fromPexels(video))
            .toList();

        debugLog('✅ Found ${videos.length} trending videos from Pexels');
        return videos;
      } else {
        throw Exception('Pexels API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error fetching trending Pexels videos: $e');
      rethrow;
    }
  }

  /// Get trending videos from both sources (Currently only Pexels)
  static Future<List<StockVideo>> getTrendingBothVideos({
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    try {
      if (_pexelsApiKey.isNotEmpty) {
        return await getTrendingPexelsVideos(perPage: perPage, page: page);
      }
      return <StockVideo>[];
    } catch (e) {
      debugLog('❌ Error fetching trending videos: $e');
      rethrow;
    }
  }

  /// Search videos from Pexels
  static Future<List<StockVideo>> searchPexelsVideos({
    required String query,
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pexelsApiKey.isEmpty) {
      throw Exception('Pexels API key not configured');
    }

    try {
      debugLog('📤 Searching Pexels videos for: "$query"');

      final url = Uri.parse(
        'https://api.pexels.com/videos/search?query=$query&per_page=$perPage&page=$page',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _pexelsApiKey,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pexels API request timeout');
        },
      );

      debugLog('📥 Pexels videos response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = (data['videos'] as List)
            .map((video) => StockVideo.fromPexels(video))
            .toList();

        debugLog('✅ Found ${videos.length} videos from Pexels');
        return videos;
      } else {
        debugLog('❌ Pexels videos API Error: ${response.statusCode}');
        throw Exception('Pexels API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error searching Pexels videos: $e');
      rethrow;
    }
  }

  /// Search videos from Pixabay
  static Future<List<StockVideo>> searchPixabayVideos({
    required String query,
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    if (_pixabayApiKey.isEmpty) {
      throw Exception('Pixabay API key not configured');
    }

    try {
      debugLog('📤 Searching Pixabay videos for: "$query"');

      final url = Uri.https(
        'pixabay.com',
        '/api/videos/',
        {
          'key': _pixabayApiKey,
          'q': query,
          'per_page': perPage.toString(),
          'page': page.toString(),
          'order': 'popular',
        },
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Pixabay API request timeout');
        },
      );

      debugLog('📥 Pixabay videos response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = (data['hits'] as List)
            .map((hit) => StockVideo.fromPixabay(hit))
            .toList();

        debugLog('✅ Found ${hits.length} videos from Pixabay');
        return hits;
      } else {
        debugLog('❌ Pixabay videos API Error: ${response.statusCode}');
        throw Exception('Pixabay API returned status ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error searching Pixabay videos: $e');
      rethrow;
    }
  }

  /// Search videos from both Pexels and Pixabay
  static Future<List<StockVideo>> searchBothVideos({
    required String query,
    int perPage = 20,
    int page = 1,
  }) async {
    await _ensureInitialized();
    
    try {
      debugLog('📤 Searching Pexels for videos: "$query"');

      final results = await Future.wait([
        _pexelsApiKey.isNotEmpty
            ? searchPexelsVideos(query: query, perPage: perPage, page: page)
            : Future.value(<StockVideo>[]),
        // Skip Pixabay videos for now - API issues
        Future.value(<StockVideo>[]),
      ]);

      final allVideos = [...results[0], ...results[1]];
      debugLog('✅ Found ${allVideos.length} total videos from Pexels');
      return allVideos;
    } catch (e) {
      debugLog('❌ Error searching videos: $e');
      rethrow;
    }
  }

  /// Search specifically for B-Roll videos using curated cinematic queries
  static Future<List<StockVideo>> searchBRollVideos({
    int perPage = 20,
    int page = 1,
  }) async {
    // We use a query that typically returns high-quality B-roll style content
    return searchBothVideos(
      query: 'cinematic slow motion landscape', 
      perPage: perPage, 
      page: page
    );
  }
}
