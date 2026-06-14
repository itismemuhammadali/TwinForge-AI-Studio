class CarouselTemplate {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final String templateImageUrl;
  final int imageSlots; // Number of image slots in this template (4-7)
  final String style; // e.g., "Minimalist", "Aesthetic", "Scrapbook"
  final List<ImageSlot> slots; // Define where images should be placed

  CarouselTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.templateImageUrl,
    required this.imageSlots,
    required this.style,
    required this.slots,
  });

  factory CarouselTemplate.fromJson(Map<String, dynamic> json) {
    return CarouselTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['previewURL'] ?? '',
      templateImageUrl: json['templateImageUrl'] ?? json['largeImageURL'] ?? '',
      imageSlots: json['imageSlots'] ?? 4,
      style: json['style'] ?? 'Default',
      slots: List<ImageSlot>.from(
        (json['slots'] as List<dynamic>?)?.map((slot) => ImageSlot.fromJson(slot)) ?? [],
      ),
    );
  }
}

class ImageSlot {
  final int index;
  final double x; // Position x (0-1, relative)
  final double y; // Position y (0-1, relative)
  final double width; // Width (0-1, relative)
  final double height; // Height (0-1, relative)
  String? userImagePath; // Path to user's uploaded image for this slot

  ImageSlot({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.userImagePath,
  });

  factory ImageSlot.fromJson(Map<String, dynamic> json) {
    return ImageSlot(
      index: json['index'] ?? 0,
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 0.5).toDouble(),
      height: (json['height'] ?? 0.5).toDouble(),
    );
  }
}

class CarouselComposition {
  final String templateId;
  final List<String> userImagePaths; // Paths to user uploaded images
  final Map<int, String> slotMappings; // Map slot index to user image path
  final List<OverlayElement> overlays; // Text and graphic overlays

  CarouselComposition({
    required this.templateId,
    required this.userImagePaths,
    required this.slotMappings,
    required this.overlays,
  });
}

class OverlayElement {
  final String id;
  final OverlayType type; // text, sticker, shape
  final String content; // Text content for text overlays
  final double x;
  final double y;
  final double width;
  final double height;
  final String color; // Hex color
  final double fontSize; // For text
  final String fontFamily; // For text

  OverlayElement({
    required this.id,
    required this.type,
    required this.content,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.fontSize = 16,
    this.fontFamily = 'Poppins',
  });
}

enum OverlayType {
  text,
  sticker,
  shape,
}
