import 'dart:developer' as developer;

class CarouselTemplate {
  final String id;
  final String name;
  final String description;
  final String category; // 'fashion', 'lifestyle', 'product', 'travel', etc.
  final int slideCount;
  final List<String> colors;
  final String layoutType; // 'grid', 'stacked', 'flow', 'magazine'
  final bool hasTextOverlay;
  final bool hasMusic;

  CarouselTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.slideCount,
    required this.colors,
    required this.layoutType,
    required this.hasTextOverlay,
    required this.hasMusic,
  });
}

class BRollTemplate {
  final String id;
  final String name;
  final String description;
  final String category; // 'cinematic', 'lifestyle', 'product', 'travel', etc.
  final String motionStyle; // 'slow_push', 'side_pan', 'cinematic_reveal', 'zoom'
  final int durationSeconds;
  final List<String> colors;
  final bool hasMusic;
  final bool hasVoiceover;

  BRollTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.motionStyle,
    required this.durationSeconds,
    required this.colors,
    required this.hasMusic,
    required this.hasVoiceover,
  });
}

class TemplateService {
  static void debugLog(String message) {
    developer.log('[TemplateService] $message');
  }

  /// Get all carousel templates
  static List<CarouselTemplate> getCarouselTemplates() {
    debugLog('📋 Loading carousel templates');

    return [
      // Fashion & Lifestyle Templates
      CarouselTemplate(
        id: 'carousel_fashion_grid',
        name: 'Fashion Grid',
        description: 'Modern grid layout perfect for fashion lookbooks',
        category: 'fashion',
        slideCount: 5,
        colors: ['#000000', '#FFFFFF', '#B1946C'],
        layoutType: 'grid',
        hasTextOverlay: true,
        hasMusic: true,
      ),
      CarouselTemplate(
        id: 'carousel_fashion_stacked',
        name: 'Stacked Elegance',
        description: 'Elegant stacked layout with smooth transitions',
        category: 'fashion',
        slideCount: 4,
        colors: ['#1A1A1A', '#D4AF37', '#FFFFFF'],
        layoutType: 'stacked',
        hasTextOverlay: true,
        hasMusic: true,
      ),
      CarouselTemplate(
        id: 'carousel_lifestyle_flow',
        name: 'Lifestyle Flow',
        description: 'Dynamic flow layout for lifestyle content',
        category: 'lifestyle',
        slideCount: 6,
        colors: ['#F5E6D3', '#8B7355', '#FFFFFF'],
        layoutType: 'flow',
        hasTextOverlay: true,
        hasMusic: true,
      ),

      // Product Templates
      CarouselTemplate(
        id: 'carousel_product_showcase',
        name: 'Product Showcase',
        description: 'Clean product-focused layout with details',
        category: 'product',
        slideCount: 5,
        colors: ['#FFFFFF', '#333333', '#B1946C'],
        layoutType: 'grid',
        hasTextOverlay: true,
        hasMusic: false,
      ),
      CarouselTemplate(
        id: 'carousel_product_magazine',
        name: 'Magazine Style',
        description: 'Magazine-inspired layout for premium products',
        category: 'product',
        slideCount: 4,
        colors: ['#2C2C2C', '#E8D5C4', '#FFFFFF'],
        layoutType: 'magazine',
        hasTextOverlay: true,
        hasMusic: true,
      ),

      // Travel & Adventure Templates
      CarouselTemplate(
        id: 'carousel_travel_adventure',
        name: 'Travel Adventure',
        description: 'Vibrant layout for travel and adventure content',
        category: 'travel',
        slideCount: 6,
        colors: ['#FF6B6B', '#4ECDC4', '#FFE66D'],
        layoutType: 'flow',
        hasTextOverlay: true,
        hasMusic: true,
      ),
      CarouselTemplate(
        id: 'carousel_travel_minimal',
        name: 'Minimal Travel',
        description: 'Minimalist travel layout with focus on images',
        category: 'travel',
        slideCount: 5,
        colors: ['#FFFFFF', '#000000', '#999999'],
        layoutType: 'grid',
        hasTextOverlay: false,
        hasMusic: true,
      ),

      // Beauty & Wellness Templates
      CarouselTemplate(
        id: 'carousel_beauty_glow',
        name: 'Beauty Glow',
        description: 'Luxurious layout for beauty and wellness',
        category: 'beauty',
        slideCount: 5,
        colors: ['#FFB6C1', '#FFE4E1', '#FFFFFF'],
        layoutType: 'stacked',
        hasTextOverlay: true,
        hasMusic: true,
      ),
    ];
  }

  /// Get all B-roll templates
  static List<BRollTemplate> getBRollTemplates() {
    debugLog('📋 Loading B-roll templates');

    return [
      // Cinematic Templates
      BRollTemplate(
        id: 'broll_cinematic_push',
        name: 'Cinematic Push',
        description: 'Slow camera push for dramatic effect',
        category: 'cinematic',
        motionStyle: 'slow_push',
        durationSeconds: 15,
        colors: ['#1A1A1A', '#B1946C', '#FFFFFF'],
        hasMusic: true,
        hasVoiceover: false,
      ),
      BRollTemplate(
        id: 'broll_cinematic_reveal',
        name: 'Cinematic Reveal',
        description: 'Smooth reveal with cinematic transitions',
        category: 'cinematic',
        motionStyle: 'cinematic_reveal',
        durationSeconds: 12,
        colors: ['#000000', '#D4AF37', '#FFFFFF'],
        hasMusic: true,
        hasVoiceover: false,
      ),

      // Lifestyle Templates
      BRollTemplate(
        id: 'broll_lifestyle_pan',
        name: 'Lifestyle Pan',
        description: 'Side pan motion for lifestyle content',
        category: 'lifestyle',
        motionStyle: 'side_pan',
        durationSeconds: 10,
        colors: ['#F5E6D3', '#8B7355', '#FFFFFF'],
        hasMusic: true,
        hasVoiceover: true,
      ),
      BRollTemplate(
        id: 'broll_lifestyle_zoom',
        name: 'Lifestyle Zoom',
        description: 'Smooth zoom effect for lifestyle shots',
        category: 'lifestyle',
        motionStyle: 'zoom',
        durationSeconds: 8,
        colors: ['#FFFFFF', '#333333', '#B1946C'],
        hasMusic: true,
        hasVoiceover: false,
      ),

      // Product Templates
      BRollTemplate(
        id: 'broll_product_showcase',
        name: 'Product Showcase',
        description: 'Slow push for product showcase',
        category: 'product',
        motionStyle: 'slow_push',
        durationSeconds: 12,
        colors: ['#FFFFFF', '#333333', '#B1946C'],
        hasMusic: false,
        hasVoiceover: true,
      ),
      BRollTemplate(
        id: 'broll_product_rotate',
        name: 'Product Rotate',
        description: 'Rotating motion for product display',
        category: 'product',
        motionStyle: 'zoom',
        durationSeconds: 10,
        colors: ['#2C2C2C', '#E8D5C4', '#FFFFFF'],
        hasMusic: true,
        hasVoiceover: false,
      ),

      // Travel & Adventure Templates
      BRollTemplate(
        id: 'broll_travel_cinematic',
        name: 'Travel Cinematic',
        description: 'Cinematic reveal for travel content',
        category: 'travel',
        motionStyle: 'cinematic_reveal',
        durationSeconds: 15,
        colors: ['#FF6B6B', '#4ECDC4', '#FFE66D'],
        hasMusic: true,
        hasVoiceover: false,
      ),
      BRollTemplate(
        id: 'broll_travel_pan',
        name: 'Travel Pan',
        description: 'Side pan for travel exploration',
        category: 'travel',
        motionStyle: 'side_pan',
        durationSeconds: 12,
        colors: ['#FFFFFF', '#000000', '#999999'],
        hasMusic: true,
        hasVoiceover: true,
      ),

      // Fashion Templates
      BRollTemplate(
        id: 'broll_fashion_runway',
        name: 'Fashion Runway',
        description: 'Slow push for fashion showcase',
        category: 'fashion',
        motionStyle: 'slow_push',
        durationSeconds: 10,
        colors: ['#000000', '#FFFFFF', '#B1946C'],
        hasMusic: true,
        hasVoiceover: false,
      ),
      BRollTemplate(
        id: 'broll_fashion_zoom',
        name: 'Fashion Detail',
        description: 'Zoom effect for fashion details',
        category: 'fashion',
        motionStyle: 'zoom',
        durationSeconds: 8,
        colors: ['#1A1A1A', '#D4AF37', '#FFFFFF'],
        hasMusic: true,
        hasVoiceover: false,
      ),
    ];
  }

  /// Get carousel templates by category
  static List<CarouselTemplate> getCarouselTemplatesByCategory(String category) {
    debugLog('📋 Loading carousel templates for category: $category');
    return getCarouselTemplates()
        .where((template) => template.category == category)
        .toList();
  }

  /// Get B-roll templates by category
  static List<BRollTemplate> getBRollTemplatesByCategory(String category) {
    debugLog('📋 Loading B-roll templates for category: $category');
    return getBRollTemplates()
        .where((template) => template.category == category)
        .toList();
  }

  /// Get all available categories
  static List<String> getAvailableCategories() {
    final carouselCategories = getCarouselTemplates()
        .map((t) => t.category)
        .toSet()
        .toList();
    final brollCategories = getBRollTemplates()
        .map((t) => t.category)
        .toSet()
        .toList();

    final allCategories = {...carouselCategories, ...brollCategories}.toList();
    allCategories.sort();

    debugLog('📋 Available categories: ${allCategories.join(", ")}');
    return allCategories;
  }
}
