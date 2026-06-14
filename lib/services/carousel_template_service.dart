import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/carousel_template.dart';

class CarouselTemplateService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static late String _pexelsApiKey;
  static late String _pixabayApiKey;
  static bool _initialized = false;

  /// Initialize service with API keys from Firebase Remote Config
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

      // Get API keys
      _pexelsApiKey = _remoteConfig.getString('pexels_api_key');
      _pixabayApiKey = _remoteConfig.getString('pixabay_api_key');

      if (_pexelsApiKey.isEmpty && _pixabayApiKey.isEmpty) {
        throw Exception('Carousel template API keys not configured');
      }

      debugLog('✅ Carousel template API keys loaded');
      _initialized = true;
    } catch (e) {
      debugLog('❌ Error initializing Carousel Template Service: $e');
      rethrow;
    }
  }

  static Future<void> initialize() async {
    await _ensureInitialized();
  }

  static void debugLog(String message) {
    developer.log('[CarouselTemplateService] $message');
  }

  /// Fetch carousel templates from Pexels
  /// Each template is a group of 4 images from the category
  static Future<List<CarouselTemplate>> fetchPexelsTemplates({
    required String category,
  }) async {
    await _ensureInitialized();

    if (_pexelsApiKey.isEmpty) {
      throw Exception('Pexels API key not configured');
    }

    try {
      debugLog('📤 Fetching Pexels carousel templates for category: "$category"');

      // Fetch images for this category
      final url = Uri.parse(
        'https://api.pexels.com/v1/search?query=$category&per_page=30&page=1',
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
        final photos = (data['photos'] as List? ?? []);

        if (photos.isEmpty) {
          debugLog('⚠️ No photos found for category: $category');
          return [];
        }

        // Group photos into templates (each template = 4 images)
        final templates = <CarouselTemplate>[];
        const imagesPerTemplate = 4;

        for (int i = 0; i < photos.length; i += imagesPerTemplate) {
          final endIndex = (i + imagesPerTemplate).clamp(0, photos.length);
          if (i < photos.length) {
            final templatePhotos = photos.sublist(i, endIndex);
            final template = _createTemplateFromPhotos(
              templatePhotos,
              templateIndex: templates.length,
              category: category,
            );
            templates.add(template);
          }
        }

        debugLog('✅ Created ${templates.length} carousel templates from Pexels');
        return templates;
      } else {
        throw Exception('Pexels API error ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error fetching Pexels templates: $e');
      rethrow;
    }
  }

  /// Fetch carousel templates from Pixabay
  /// Each template is a group of 4 images from the category
  static Future<List<CarouselTemplate>> fetchPixabayTemplates({
    required String category,
  }) async {
    await _ensureInitialized();

    if (_pixabayApiKey.isEmpty) {
      throw Exception('Pixabay API key not configured');
    }

    try {
      debugLog('📤 Fetching Pixabay carousel templates for category: "$category"');

      final url = Uri.parse(
        'https://pixabay.com/api/?key=$_pixabayApiKey&q=$category&per_page=30&image_type=photo&order=popular',
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
        final hits = (data['hits'] as List? ?? []);

        if (hits.isEmpty) {
          debugLog('⚠️ No images found for category: $category');
          return [];
        }

        // Group images into templates (each template = 4 images)
        final templates = <CarouselTemplate>[];
        const imagesPerTemplate = 4;

        for (int i = 0; i < hits.length; i += imagesPerTemplate) {
          final endIndex = (i + imagesPerTemplate).clamp(0, hits.length);
          if (i < hits.length) {
            final templateHits = hits.sublist(i, endIndex);
            final template = _createTemplateFromHits(
              templateHits,
              templateIndex: templates.length,
              category: category,
            );
            templates.add(template);
          }
        }

        debugLog('✅ Created ${templates.length} carousel templates from Pixabay');
        return templates;
      } else {
        throw Exception('Pixabay API error ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error fetching Pixabay templates: $e');
      rethrow;
    }
  }

  /// Fetch templates from both Pexels and Pixabay
  static Future<List<CarouselTemplate>> fetchAllTemplates({
    required String category,
  }) async {
    await _ensureInitialized();

    try {
      debugLog('📤 Fetching carousel templates from all sources for: "$category"');

      final results = await Future.wait([
        _pexelsApiKey.isNotEmpty
            ? fetchPexelsTemplates(category: category)
            : Future.value(<CarouselTemplate>[]),
        _pixabayApiKey.isNotEmpty
            ? fetchPixabayTemplates(category: category)
            : Future.value(<CarouselTemplate>[]),
      ]);

      final allTemplates = [...results[0], ...results[1]];
      debugLog('✅ Fetched ${allTemplates.length} total templates');
      return allTemplates;
    } catch (e) {
      debugLog('❌ Error fetching all templates: $e');
      rethrow;
    }
  }

  /// Create a template from a set of Pexels photos
  /// Template has multiple images (placeholder images that user will swap)
  static CarouselTemplate _createTemplateFromPhotos(
    List<dynamic> photos, {
    required int templateIndex,
    required String category,
  }) {
    final imageSlots = <ImageSlot>[];

    // Define positions for 4-image carousel (2x2 grid)
    const positions = [
      (x: 0.0, y: 0.0, w: 0.5, h: 0.5),   // Top left
      (x: 0.5, y: 0.0, w: 0.5, h: 0.5),   // Top right
      (x: 0.0, y: 0.5, w: 0.5, h: 0.5),   // Bottom left
      (x: 0.5, y: 0.5, w: 0.5, h: 0.5),   // Bottom right
    ];

    // Store the template's placeholder images (these are what user will swap out)
    final templateImages = <String>[];

    for (int i = 0; i < photos.length && i < positions.length; i++) {
      final photo = photos[i];
      final pos = positions[i];
      
      // Create slot
      imageSlots.add(
        ImageSlot(
          index: i,
          x: pos.x,
          y: pos.y,
          width: pos.w,
          height: pos.h,
          userImagePath: photo['src']['medium'] ?? photo['src']['original'],
        ),
      );

      // Store template image URL
      templateImages.add(photo['src']['medium'] ?? photo['src']['original']);
    }

    final firstPhoto = photos[0];
    final templateName = '${category.toUpperCase()} Template ${templateIndex + 1}';

    return CarouselTemplate(
      id: 'pexels_template_${templateIndex}_${DateTime.now().millisecondsSinceEpoch}',
      name: templateName,
      description: 'Carousel with ${photos.length} images - swap your images into this template',
      thumbnailUrl: firstPhoto['src']['medium'] ?? firstPhoto['src']['original'],
      templateImageUrl: firstPhoto['src']['large'] ?? firstPhoto['src']['original'],
      imageSlots: photos.length,
      style: 'Grid',
      slots: imageSlots,
    );
  }

  /// Create a template from a set of Pixabay images
  static CarouselTemplate _createTemplateFromHits(
    List<dynamic> hits, {
    required int templateIndex,
    required String category,
  }) {
    final imageSlots = <ImageSlot>[];

    // Define positions for 4-image carousel (2x2 grid)
    const positions = [
      (x: 0.0, y: 0.0, w: 0.5, h: 0.5),
      (x: 0.5, y: 0.0, w: 0.5, h: 0.5),
      (x: 0.0, y: 0.5, w: 0.5, h: 0.5),
      (x: 0.5, y: 0.5, w: 0.5, h: 0.5),
    ];

    // Store the template's placeholder images
    final templateImages = <String>[];

    for (int i = 0; i < hits.length && i < positions.length; i++) {
      final hit = hits[i];
      final pos = positions[i];

      // Create slot
      imageSlots.add(
        ImageSlot(
          index: i,
          x: pos.x,
          y: pos.y,
          width: pos.w,
          height: pos.h,
          userImagePath: hit['previewURL'] ?? hit['webformatURL'],
        ),
      );

      // Store template image URL
      templateImages.add(hit['previewURL'] ?? hit['webformatURL']);
    }

    final firstHit = hits[0];
    final templateName = '${category.toUpperCase()} Template ${templateIndex + 1}';

    return CarouselTemplate(
      id: 'pixabay_template_${templateIndex}_${DateTime.now().millisecondsSinceEpoch}',
      name: templateName,
      description: 'Carousel with ${hits.length} images - swap your images into this template',
      thumbnailUrl: firstHit['previewURL'],
      templateImageUrl: firstHit['largeImageURL'],
      imageSlots: hits.length,
      style: 'Grid',
      slots: imageSlots,
    );
  }

  /// Get popular carousel categories/keywords
  static List<String> getPopularCategories() {
    return [
      'lifestyle',
      'fashion',
      'travel',
      'food',
      'nature',
      'business',
      'portrait',
      'minimalist',
    ];
  }
}
