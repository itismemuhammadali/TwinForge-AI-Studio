import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class CarouselPexelsService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static late String _pexelsApiKey;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      debugLog('🔍 Initializing Carousel Pexels Service...');

      await _remoteConfig.setDefaults({'pexels_api_key': ''});
      await _remoteConfig.fetchAndActivate();

      _pexelsApiKey = _remoteConfig.getString('pexels_api_key');

      if (_pexelsApiKey.isEmpty) {
        throw Exception('Pexels API key not found in Firebase Remote Config');
      }

      debugLog('✅ Pexels API key loaded');
      _initialized = true;
    } catch (e) {
      debugLog('❌ Error initializing: $e');
      rethrow;
    }
  }

  static Future<void> initialize() async {
    await _ensureInitialized();
  }

  static void debugLog(String message) {
    developer.log('[CarouselPexelsService] $message');
  }

  /// Fetch carousel background images from Pexels
  /// Always fetches EXACTLY 5 images
  /// Always appends "professional" or "premium" to query
  static Future<List<String>> fetchCarouselImages({
    required Set<String> subcategories,
  }) async {
    await _ensureInitialized();

    if (_pexelsApiKey.isEmpty) {
      throw Exception('Pexels API key not configured');
    }

    try {
      // Build search query from subcategories
      final query = _buildSearchQuery(subcategories);
      debugLog('📤 Fetching carousel images for: "$query"');

      final url = Uri.parse(
        'https://api.pexels.com/v1/search?query=$query&per_page=5&page=1',
      );

      debugLog('🔗 Calling: $url');

      // Use a shorter timeout for Pexels API
      final response = await http
          .get(
            url,
            headers: {'Authorization': _pexelsApiKey},
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugLog('⏱️ Pexels API timeout after 15s, trying fallback...');
              throw TimeoutException('Pexels API timeout');
            },
          );

      debugLog('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = (data['photos'] as List? ?? []);

        if (photos.isEmpty) {
          debugLog('⚠️ No photos found, trying fallback query...');
          return _fetchFallbackImages();
        }

        // Extract image URLs (get exactly 5)
        final imageUrls = photos
            .take(5)
            .map<String>((photo) {
              final largeUrl = photo['src']?['large'];
              final mediumUrl = photo['src']?['medium'];
              final originalUrl = photo['src']?['original'];
              return (largeUrl ?? mediumUrl ?? originalUrl ?? '') as String;
            })
            .where((url) => url.isNotEmpty)
            .toList();

        if (imageUrls.length < 5) {
          debugLog(
              '⚠️ Only got ${imageUrls.length} images, trying fallback...');
          return _fetchFallbackImages();
        }

        debugLog('✅ Fetched exactly 5 carousel images');
        return imageUrls;
      } else {
        debugLog('❌ Pexels API error ${response.statusCode}');
        return _fetchFallbackImages();
      }
    } catch (e) {
      debugLog('❌ Error fetching images: $e');
      try {
        return await _fetchFallbackImages();
      } catch (e2) {
        debugLog('❌ Fallback also failed: $e2');
        rethrow;
      }
    }
  }

  /// Build Pexels search query from subcategories
  static String _buildSearchQuery(Set<String> subcategories) {
    if (subcategories.isEmpty) {
      return 'professional premium';
    }

    final keywords = subcategories.toList();

    // Map subcategories to search-friendly keywords
    final mappedKeywords = keywords.map((sub) {
      return sub
          .toLowerCase()
          .replaceAll(' and ', ' ')
          .replaceAll(' ', '_')
          .replaceAll('_', ' ');
    }).toList();

    // Combine into single query (limit to 3 keywords to avoid too specific queries)
    final limitedKeywords = mappedKeywords.take(3).toList();
    final query = limitedKeywords.join(' ');

    // Always append professional
    return '$query professional premium';
  }

  /// Fallback to broader query if specific one fails
  static Future<List<String>> _fetchFallbackImages() async {
    debugLog('🔄 Using fallback curated images...');

    try {
      final url = Uri.parse(
        'https://api.pexels.com/v1/curated?per_page=5&page=1',
      );

      debugLog('🔗 Calling fallback: $url');

      final response = await http
          .get(
            url,
            headers: {'Authorization': _pexelsApiKey},
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Fallback API timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = (data['photos'] as List? ?? []);

        final imageUrls = photos
            .take(5)
            .map<String>((photo) {
              final largeUrl = photo['src']?['large'];
              final mediumUrl = photo['src']?['medium'];
              final originalUrl = photo['src']?['original'];
              return (largeUrl ?? mediumUrl ?? originalUrl ?? '') as String;
            })
            .where((url) => url.isNotEmpty)
            .toList();

        debugLog(
            '✅ Fallback fetch got ${imageUrls.length} images');
        return imageUrls.isNotEmpty ? imageUrls : _getMockImages();
      } else {
        debugLog('⚠️ Fallback also failed, using mock images');
        return _getMockImages();
      }
    } catch (e) {
      debugLog('❌ Fallback failed: $e, using mock images');
      return _getMockImages();
    }
  }

  /// Fallback mock images (for testing when API is down)
  static List<String> _getMockImages() {
    return [
      'https://images.pexels.com/photos/3807517/pexels-photo-3807517.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/3807519/pexels-photo-3807519.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/3807518/pexels-photo-3807518.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/3807521/pexels-photo-3807521.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/3807523/pexels-photo-3807523.jpeg?auto=compress&cs=tinysrgb&w=600',
    ];
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

