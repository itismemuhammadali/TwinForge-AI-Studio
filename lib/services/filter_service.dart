import 'dart:typed_data';
import 'package:image/image.dart' as img;

class FilterService {
  static Map<String, img.Image Function(img.Image)> get availableFilters => {
    'None': (img.Image image) => image,
    'Grayscale': (img.Image image) => img.grayscale(image),
    'Sepia': (img.Image image) => img.sepia(image),
    'Invert': (img.Image image) => img.invert(image),
    'Cinematic': (img.Image image) => img.adjustColor(image, saturation: 1.5, contrast: 1.2),
    'Vintage': (img.Image image) => img.sepia(img.adjustColor(image, saturation: 0.7), amount: 0.5),
    'Cool': (img.Image image) => img.colorOffset(image, blue: 30, red: -10),
    'Warm': (img.Image image) => img.colorOffset(image, red: 30, blue: -10),
    'B&W High': (img.Image image) => img.contrast(img.grayscale(image), contrast: 150),
    'Vivid': (img.Image image) => img.adjustColor(image, saturation: 2.0),
  };

  static Uint8List applyFilter(Uint8List imageBytes, String filterName) {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      final filterFunc = availableFilters[filterName];
      if (filterFunc == null) return imageBytes;

      // Create a copy to avoid mutating the original until we want to
      img.Image workingImage = img.Image.from(image);
      img.Image filtered = filterFunc(workingImage);
      
      return Uint8List.fromList(img.encodeJpg(filtered));
    } catch (e) {
      print('Error applying filter: $e');
      return imageBytes;
    }
  }
}
