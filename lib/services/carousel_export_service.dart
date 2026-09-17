import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../models/carousel_models.dart';

class CarouselExportService {
  static void debugLog(String message) {
    developer.log('[CarouselExportService] $message');
  }

  /// Download image from URL to bytes
  static Future<Uint8List> downloadImage(String url) async {
    try {
      debugLog('📥 Downloading image from: $url');
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 30),
          );
      if (response.statusCode == 200) {
        debugLog('✅ Image downloaded successfully (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Error downloading image: $e');
      rethrow;
    }
  }

  /// Render text overlay as image using Flutter's text rendering
  static Future<img.Image> renderTextToImage(TextOverlay overlay, int width, int height) async {
    try {
      debugLog('🎨 Rendering text: "${overlay.text}" (${width}x$height)');

      // Create a recorder to capture the text rendering
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      // Fill background if not transparent
      if (overlay.backgroundColor != 'transparent') {
        final bgColor = int.parse('0xFF${overlay.backgroundColor.replaceFirst('#', '')}');
        final r = (bgColor >> 16) & 0xFF;
        final g = (bgColor >> 8) & 0xFF;
        final b = bgColor & 0xFF;
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          ui.Paint()..color = ui.Color.fromARGB(255, r, g, b),
        );
      }

      // Parse font color
      final fontColorInt = int.parse('0xFF${overlay.fontColor.replaceFirst('#', '')}');
      final fontColorR = (fontColorInt >> 16) & 0xFF;
      final fontColorG = (fontColorInt >> 8) & 0xFF;
      final fontColorB = fontColorInt & 0xFF;

      // Build text style
      final textStyle = ui.TextStyle(
        color: ui.Color.fromARGB(255, fontColorR, fontColorG, fontColorB),
        fontSize: overlay.fontSize.toDouble(),
        fontWeight: overlay.bold ? ui.FontWeight.bold : ui.FontWeight.normal,
        fontStyle: overlay.italic ? ui.FontStyle.italic : ui.FontStyle.normal,
        decoration: overlay.underline ? ui.TextDecoration.underline : ui.TextDecoration.none,
      );

      // Calculate text alignment
      final textAlign = overlay.alignment == 'left'
          ? ui.TextAlign.left
          : overlay.alignment == 'right'
              ? ui.TextAlign.right
              : ui.TextAlign.center;

      // Create paragraph builder
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: textAlign,
        maxLines: null,
      ));
      paragraphBuilder.pushStyle(textStyle);
      paragraphBuilder.addText(overlay.text);

      // Build and measure paragraph
      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: width.toDouble()));

      // Calculate vertical centering
      final yOffset = (height - paragraph.height) / 2;

      // Draw shadow if enabled
      if (overlay.shadow) {
        // Redraw paragraph for shadow effect
        final shadowTextStyle = ui.TextStyle(
          color: ui.Color.fromARGB(128, 0, 0, 0),
          fontSize: overlay.fontSize.toDouble(),
          fontWeight: overlay.bold ? ui.FontWeight.bold : ui.FontWeight.normal,
          fontStyle: overlay.italic ? ui.FontStyle.italic : ui.FontStyle.normal,
          decoration: overlay.underline ? ui.TextDecoration.underline : ui.TextDecoration.none,
        );
        final shadowBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: textAlign,
          maxLines: null,
        ));
        shadowBuilder.pushStyle(shadowTextStyle);
        shadowBuilder.addText(overlay.text);
        final shadowParagraph = shadowBuilder.build();
        shadowParagraph.layout(ui.ParagraphConstraints(width: width.toDouble()));
        canvas.drawParagraph(shadowParagraph, ui.Offset(2, yOffset + 2));
      }

      // Draw main text
      canvas.drawParagraph(paragraph, ui.Offset(0, yOffset));

      // Convert to image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(width, height);
      final bytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        throw Exception('Failed to convert UI image to bytes');
      }

      final textImage = img.decodeImage(bytes.buffer.asUint8List());
      if (textImage == null) {
        throw Exception('Failed to decode rendered text image');
      }

      debugLog('✅ Text rendered successfully');
      return textImage;
    } catch (e) {
      debugLog('❌ Error rendering text: $e');
      rethrow;
    }
  }

  /// Render drawing overlay as image
  static Future<img.Image> renderDrawingToImage(DrawingOverlay overlay) async {
    try {
      debugLog('🎨 Rendering drawing: ${overlay.paths.length} paths');

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, overlay.width, overlay.height));

      for (final path in overlay.paths) {
        final colorInt = int.parse('0xFF${path.color.replaceFirst('#', '')}');
        final paint = ui.Paint()
          ..color = ui.Color(colorInt)
          ..strokeWidth = path.strokeWidth
          ..style = ui.PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round;

        final uiPath = ui.Path();
        if (path.points.isNotEmpty) {
          uiPath.moveTo(path.points[0][0], path.points[0][1]);
          for (int i = 1; i < path.points.length; i++) {
            uiPath.lineTo(path.points[i][0], path.points[i][1]);
          }
        }
        canvas.drawPath(uiPath, paint);
      }

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(overlay.width.toInt(), overlay.height.toInt());
      final bytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) throw Exception('Failed to convert drawing to bytes');

      final drawingImage = img.decodeImage(bytes.buffer.asUint8List());
      if (drawingImage == null) throw Exception('Failed to decode drawing image');

      return drawingImage;
    } catch (e) {
      debugLog('❌ Error rendering drawing: $e');
      rethrow;
    }
  }

  /// Bake overlays onto a base image
  static Future<Uint8List> bakeOverlays(
    Uint8List baseImageBytes,
    List<OverlayElement> overlays,
  ) async {
    try {
      debugLog('🎨 Baking ${overlays.length} overlays onto image...');

      final bgImage = img.decodeImage(baseImageBytes);
      if (bgImage == null) throw Exception('Failed to decode base image');

      final canvas = bgImage.clone();

      for (final overlay in overlays) {
        if (overlay is ImageOverlay) {
          try {
            final imageData = overlay.imageFile.readAsBytesSync();
            final overlayImage = img.decodeImage(imageData);
            if (overlayImage != null) {
              final resizedOverlay = _resizeImageMaintainingAspectRatio(
                overlayImage,
                overlay.width.toInt(),
                overlay.height.toInt(),
              );
              img.compositeImage(
                canvas,
                resizedOverlay,
                dstX: overlay.x.toInt(),
                dstY: overlay.y.toInt(),
              );
            }
          } catch (e) {
            debugLog('⚠️ Error adding image overlay: $e');
          }
        } else if (overlay is TextOverlay) {
          try {
            final textImage = await renderTextToImage(
              overlay,
              overlay.width.toInt(),
              overlay.height.toInt(),
            );
            img.compositeImage(
              canvas,
              textImage,
              dstX: overlay.x.toInt(),
              dstY: overlay.y.toInt(),
            );
          } catch (e) {
            debugLog('⚠️ Error adding text overlay: $e');
          }
        } else if (overlay is DrawingOverlay) {
          try {
            final drawingImage = await renderDrawingToImage(overlay);
            img.compositeImage(
              canvas,
              drawingImage,
              dstX: overlay.x.toInt(),
              dstY: overlay.y.toInt(),
            );
          } catch (e) {
            debugLog('⚠️ Error adding drawing overlay: $e');
          }
        }
      }

      return Uint8List.fromList(img.encodeJpg(canvas));
    } catch (e) {
      debugLog('❌ Error baking overlays: $e');
      rethrow;
    }
  }

  /// Render a single slide to PNG bytes
  static Future<Uint8List> renderSlideToPng(
    CarouselSlide slide,
  ) async {
    try {
      debugLog('🎨 Rendering slide ${slide.id}...');

      // Download and decode background image
      final bgBytes = await downloadImage(slide.backgroundImageUrl ?? '');
      final bgImage = img.decodeImage(bgBytes);

      if (bgImage == null) {
        throw Exception('Failed to decode background image');
      }

      debugLog('🎨 Background image size: ${bgImage.width}x${bgImage.height}');

      // Use the actual background image dimensions for the canvas
      final canvasWidth = bgImage.width;
      final canvasHeight = bgImage.height;

      // Start with the background image as the canvas
      final canvas = bgImage.clone();

      // Draw overlays in order (image overlays first, then text, then drawing)
      for (final overlay in slide.overlays) {
        if (overlay is ImageOverlay) {
          // Draw image overlay
          try {
            final imageData = overlay.imageFile.readAsBytesSync();
            final overlayImage = img.decodeImage(imageData);

            if (overlayImage != null) {
              // Overlay dimensions and position are now in actual image pixel coordinates
              final overlayWidth = overlay.width.toInt();
              final overlayHeight = overlay.height.toInt();
              final overlayX = overlay.x.toInt();
              final overlayY = overlay.y.toInt();

              // Resize maintaining aspect ratio
              final resizedOverlay = _resizeImageMaintainingAspectRatio(
                overlayImage,
                overlayWidth,
                overlayHeight,
              );

              // Composite overlay onto canvas at its stored position
              img.compositeImage(
                canvas,
                resizedOverlay,
                dstX: overlayX,
                dstY: overlayY,
              );
              debugLog('✅ Image overlay: ($overlayX, $overlayY), ${overlayWidth}x$overlayHeight');
            }
          } catch (e) {
            debugLog('⚠️ Error adding image overlay: $e');
          }
        } else if (overlay is TextOverlay) {
          // Render text overlay
          try {
            // Overlay dimensions and position are now in actual image pixel coordinates
            final overlayWidth = overlay.width.toInt();
            final overlayHeight = overlay.height.toInt();
            final overlayX = overlay.x.toInt();
            final overlayY = overlay.y.toInt();

            final textImage = await renderTextToImage(
              overlay,
              overlayWidth,
              overlayHeight,
            );

            // Composite text image onto canvas at its stored position
            img.compositeImage(
              canvas,
              textImage,
              dstX: overlayX,
              dstY: overlayY,
            );
            debugLog('✅ Text overlay: ($overlayX, $overlayY), font ${overlay.fontSize}');
          } catch (e) {
            debugLog('⚠️ Error adding text overlay: $e');
          }
        } else if (overlay is DrawingOverlay) {
          // Render drawing overlay
          try {
            final overlayX = overlay.x.toInt();
            final overlayY = overlay.y.toInt();

            final drawingImage = await renderDrawingToImage(overlay);

            img.compositeImage(
              canvas,
              drawingImage,
              dstX: overlayX,
              dstY: overlayY,
            );
            debugLog('✅ Drawing overlay: ($overlayX, $overlayY), ${overlay.paths.length} paths');
          } catch (e) {
            debugLog('⚠️ Error adding drawing overlay: $e');
          }
        }
      }

      // Encode to PNG
      final pngBytes = img.encodePng(canvas);
      debugLog('✅ Slide ${slide.id} rendered successfully (${canvasWidth}x$canvasHeight, ${pngBytes.length} bytes)');
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      debugLog('❌ Error rendering slide: $e');
      rethrow;
    }
  }

  /// Resize image maintaining aspect ratio within bounds
  static img.Image _resizeImageMaintainingAspectRatio(
    img.Image image,
    int maxWidth,
    int maxHeight,
  ) {
    final aspectRatio = image.width / image.height;
    late int finalWidth;
    late int finalHeight;

    if (aspectRatio > maxWidth / maxHeight) {
      // Image is wider - fit to width
      finalWidth = maxWidth;
      finalHeight = (maxWidth / aspectRatio).toInt();
    } else {
      // Image is taller - fit to height
      finalHeight = maxHeight;
      finalWidth = (maxHeight * aspectRatio).toInt();
    }

    return img.copyResize(
      image,
      width: finalWidth,
      height: finalHeight,
    );
  }

  /// Export entire carousel to ZIP file
  static Future<File> exportCarouselToZip(
    Carousel carousel,
  ) async {
    try {
      debugLog('📦 Starting carousel export...');

      final archive = Archive();
      int slideNumber = 1;

      // Render each slide
      for (final slide in carousel.slides) {
        debugLog('⏳ Rendering slide $slideNumber of ${carousel.slides.length}...');

        final pngBytes = await renderSlideToPng(slide);

        // Add to archive
        archive.addFile(
          ArchiveFile(
            'slide$slideNumber.png',
            pngBytes.length,
            pngBytes,
          ),
        );

        debugLog('✅ Slide $slideNumber added to archive');
        slideNumber++;
      }

      // Get Downloads directory
      final downloadDir = await getDownloadsDirectory();
      
      if (downloadDir == null) {
        throw Exception('Could not access Downloads directory');
      }

      debugLog('💾 Downloads directory: ${downloadDir.path}');

      // Create filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'carousel_$timestamp.zip';
      final zipFile = File('${downloadDir.path}/$filename');
      debugLog('💾 Saving to: ${zipFile.path}');

      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('Failed to encode ZIP file');
      }

      await zipFile.writeAsBytes(zipBytes);
      debugLog('✅ ZIP file created: ${zipFile.path} (${zipBytes.length} bytes)');

      return zipFile;
    } catch (e) {
      debugLog('❌ Error exporting carousel: $e');
      rethrow;
    }
  }

  /// Save carousel as individual PNG files
  static Future<Directory> exportCarouselAsPngs(
    Carousel carousel,
  ) async {
    try {
      debugLog('📸 Exporting carousel as individual PNG files...');

      final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final carouselDir = Directory('${downloadsDir.path}/carousel_${DateTime.now().millisecondsSinceEpoch}');
      await carouselDir.create(recursive: true);

      int slideNumber = 1;
      for (final slide in carousel.slides) {
        debugLog('💾 Saving slide $slideNumber...');

        final pngBytes = await renderSlideToPng(slide);
        final file = File('${carouselDir.path}/slide$slideNumber.png');
        await file.writeAsBytes(pngBytes);

        debugLog('✅ Slide $slideNumber saved: ${file.path}');
        slideNumber++;
      }

      debugLog('✅ All slides exported to: ${carouselDir.path}');
      return carouselDir;
    } catch (e) {
      debugLog('❌ Error exporting PNG files: $e');
      rethrow;
    }
  }

  /// Export entire carousel to ZIP bytes for Firebase upload
  static Future<Uint8List> exportCarouselToZipBytes(
    Carousel carousel,
  ) async {
    try {
      debugLog('📦 Starting carousel export to bytes...');

      final archive = Archive();
      int slideNumber = 1;

      // Render each slide
      for (final slide in carousel.slides) {
        debugLog('⏳ Rendering slide $slideNumber of ${carousel.slides.length}...');
        final pngBytes = await renderSlideToPng(slide);
        archive.addFile(
          ArchiveFile(
            'slide$slideNumber.png',
            pngBytes.length,
            pngBytes,
          ),
        );
        slideNumber++;
      }

      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('Failed to encode ZIP file');
      }

      return Uint8List.fromList(zipBytes);
    } catch (e) {
      debugLog('❌ Error exporting carousel to bytes: $e');
      rethrow;
    }
  }

  /// Get downloads directory
  static Future<Directory?> getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          return dir;
        }
      } else if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugLog('⚠️ Error getting downloads directory: $e');
    }
    return null;
  }
}

