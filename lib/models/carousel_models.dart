import 'dart:io';

// ============================================================================
// CAROUSEL DATA MODELS - Exact structure from carousal_prompt.md
// ============================================================================

/// Main Carousel container with all slides
class Carousel {
  final List<CarouselSlide> slides;

  Carousel({required this.slides});

  /// Create a carousel with 5 empty slides
  factory Carousel.empty() {
    return Carousel(
      slides: List.generate(
        5,
        (index) => CarouselSlide(id: index + 1, overlays: []),
      ),
    );
  }
}

/// Individual slide in the carousel
class CarouselSlide {
  final int id;
  final String? backgroundImageUrl;
  final List<OverlayElement> overlays;

  CarouselSlide({
    required this.id,
    this.backgroundImageUrl,
    required this.overlays,
  });

  /// Copy with modifications
  CarouselSlide copyWith({
    int? id,
    String? backgroundImageUrl,
    List<OverlayElement>? overlays,
  }) {
    return CarouselSlide(
      id: id ?? this.id,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      overlays: overlays ?? this.overlays,
    );
  }
}

/// Base overlay class
/// NOTE: x, y, width, and height are in ACTUAL IMAGE PIXEL coordinates.
/// For example, if the background image is 4000x3000, x: 2000 means the horizontal center.
abstract class OverlayElement {
  final String type; // "image", "text", or "drawing"
  final double x;
  final double y;
  final double width;
  final double height;
  final double opacity;

  OverlayElement({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.opacity = 1.0,
  });
}

/// Represents a single continuous stroke in a drawing
class DrawingPath {
  final List<List<double>> points; // List of [x, y] coordinates in pixel space
  final String color; // Hex color #FFFFFF
  final double strokeWidth;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  DrawingPath copyWith({
    List<List<double>>? points,
    String? color,
    double? strokeWidth,
  }) {
    return DrawingPath(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points,
    'color': color,
    'strokeWidth': strokeWidth,
  };
}

/// Drawing overlay - freehand drawing on slide
class DrawingOverlay extends OverlayElement {
  final List<DrawingPath> paths;

  DrawingOverlay({
    required this.paths,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.opacity = 1.0,
  }) : super(
    type: 'drawing',
  );

  DrawingOverlay copyWith({
    List<DrawingPath>? paths,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
  }) {
    return DrawingOverlay(
      paths: paths ?? this.paths,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Image overlay - user's uploaded photo placed on slide
class ImageOverlay extends OverlayElement {
  final File imageFile; // Path to user's uploaded image
  final double rotation;
  final String cropShape; // "rectangle", "circle", "rounded"

  ImageOverlay({
    required this.imageFile,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    this.rotation = 0,
    this.cropShape = 'rectangle',
    super.opacity = 1.0,
  }) : super(
    type: 'image',
  );

  /// Copy with modifications
  ImageOverlay copyWith({
    File? imageFile,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? cropShape,
    double? opacity,
  }) {
    return ImageOverlay(
      imageFile: imageFile ?? this.imageFile,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      cropShape: cropShape ?? this.cropShape,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Text overlay - text placed on slide
class TextOverlay extends OverlayElement {
  final String text;
  final int fontSize;
  final String fontFamily;
  final String fontColor; // Hex color #FFFFFF
  final String alignment; // left, center, right
  final bool bold;
  final bool italic;
  final bool underline;
  final String backgroundColor; // Hex color or "transparent"
  final bool shadow;

  TextOverlay({
    required this.text,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    this.fontSize = 24,
    this.fontFamily = 'Montserrat',
    this.fontColor = '#FFFFFF',
    this.alignment = 'center',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.backgroundColor = 'transparent',
    this.shadow = false,
    super.opacity = 1.0,
  }) : super(
    type: 'text',
  );

  /// Copy with modifications
  TextOverlay copyWith({
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    int? fontSize,
    String? fontFamily,
    String? fontColor,
    String? alignment,
    bool? bold,
    bool? italic,
    bool? underline,
    String? backgroundColor,
    bool? shadow,
    double? opacity,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      fontColor: fontColor ?? this.fontColor,
      alignment: alignment ?? this.alignment,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      shadow: shadow ?? this.shadow,
      opacity: opacity ?? this.opacity,
    );
  }
}

// ============================================================================
// CAROUSEL CATEGORY SYSTEM
// ============================================================================

/// Category with subcategories
class CarouselCategory {
  final String name;
  final List<String> subcategories;

  CarouselCategory({
    required this.name,
    required this.subcategories,
  });
}

/// All categories from carousal_prompt.md
class CarouselCategories {
  static final List<CarouselCategory> all = [
    CarouselCategory(
      name: 'Business Men and Business Women',
      subcategories: [
        'Office and Workspace',
        'Team and Meetings',
        'Technology and Laptops',
        'Finance and Money',
        'Presentation and Strategy',
        'Coffee and Work Culture',
        'City and Corporate',
        'Networking and Events',
        'Leadership and Coaching',
        'Entrepreneurship',
        'Luxury Business Lifestyle',
        'Vineyard and Wine Business',
      ],
    ),
    CarouselCategory(
      name: 'Nature',
      subcategories: [
        'Mountains',
        'Beach and Sea',
        'Sunset and Sunrise',
        'Waterfall',
        'Forest',
        'Desert',
        'Vineyard and Countryside',
        'Lakes and Rivers',
        'Flowers and Gardens',
        'Snow and Winter Landscapes',
      ],
    ),
    CarouselCategory(
      name: 'Travel',
      subcategories: [
        'Luxury Hotels',
        'City Skylines',
        'Airports and Transit',
        'Exotic Destinations',
        'Road Trips',
        'Vineyard and Wine Country Travel',
        'Cruise and Ocean Travel',
        'Mountain Retreats',
        'Cultural and Heritage Sites',
      ],
    ),
    CarouselCategory(
      name: 'Minimalist',
      subcategories: [
        'White and Clean',
        'Dark and Moody',
        'Pastel and Soft',
        'Geometric and Abstract',
        'Vineyard and Rustic Minimal',
        'Luxury Minimal',
        'Black and White',
      ],
    ),
    CarouselCategory(
      name: 'Fashion and Lifestyle',
      subcategories: [
        'Luxury and Premium',
        'Fitness and Wellness',
        'Food and Dining',
        'Vineyard and Wine Lifestyle',
        'Beauty and Skincare',
        'Home and Interior Design',
        'Mindfulness and Meditation',
        'Streetwear and Urban',
      ],
    ),
    CarouselCategory(
      name: 'Food and Beverage',
      subcategories: [
        'Fine Dining',
        'Coffee and Cafes',
        'Vineyard and Wine',
        'Cocktails and Drinks',
        'Healthy and Organic',
        'Desserts and Pastry',
        'Street Food',
        'Cooking and Kitchen',
      ],
    ),
    CarouselCategory(
      name: 'Architecture and Interiors',
      subcategories: [
        'Luxury Homes',
        'Modern Architecture',
        'Vineyard Estates and Villas',
        'Office Interiors',
        'Hotels and Resorts',
        'Industrial and Urban Spaces',
        'Historic Buildings',
      ],
    ),
    CarouselCategory(
      name: 'Motivation and Personal Brand',
      subcategories: [
        'Quotes and Typography Backgrounds',
        'Sunrise and New Beginnings',
        'Vineyard and Reflection',
        'Achievement and Success',
        'Books and Learning',
        'Journaling and Planning',
      ],
    ),
  ];
}

// ============================================================================
// CAROUSEL STATE MODELS
// ============================================================================

/// Represents state during carousel creation flow
class CarouselCreationState {
  final List<File> uploadedImages; // User's uploaded 4-5 images
  final Set<String> selectedSubcategories; // Selected subcategories
  final List<String> backgroundImageUrls; // 5 Pexels images fetched
  final int currentSlideIndex; // Currently editing slide (0-4)
  final Carousel carousel; // Current carousel being edited

  CarouselCreationState({
    required this.uploadedImages,
    required this.selectedSubcategories,
    required this.backgroundImageUrls,
    this.currentSlideIndex = 0,
    required this.carousel,
  });

  /// Copy with modifications
  CarouselCreationState copyWith({
    List<File>? uploadedImages,
    Set<String>? selectedSubcategories,
    List<String>? backgroundImageUrls,
    int? currentSlideIndex,
    Carousel? carousel,
  }) {
    return CarouselCreationState(
      uploadedImages: uploadedImages ?? this.uploadedImages,
      selectedSubcategories: selectedSubcategories ?? this.selectedSubcategories,
      backgroundImageUrls: backgroundImageUrls ?? this.backgroundImageUrls,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      carousel: carousel ?? this.carousel,
    );
  }
}
