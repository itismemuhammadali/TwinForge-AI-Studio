import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

class CropResizeScreen extends StatefulWidget {
  final File image;
  const CropResizeScreen({super.key, required this.image});

  @override
  State<CropResizeScreen> createState() => _CropResizeScreenState();
}

class _CropResizeScreenState extends State<CropResizeScreen> {
  bool _isProcessing = false;
  Rect? _cropRect;
  Size? _displayImageSize;
  Offset? _imageOffset;
  
  final double _handleSize = 24.0;
  final double _touchAreaSize = 48.0;

  @override
  void initState() {
    super.initState();
  }

  void _initCropRect(Size availableSize, Size imageOriginalSize) {
    if (_cropRect != null) return;

    final double ratio = imageOriginalSize.width / imageOriginalSize.height;
    double width, height;

    if (availableSize.width / availableSize.height > ratio) {
      height = availableSize.height;
      width = height * ratio;
    } else {
      width = availableSize.width;
      height = width / ratio;
    }

    _displayImageSize = Size(width, height);
    _imageOffset = Offset(
      (availableSize.width - width) / 2,
      (availableSize.height - height) / 2,
    );
    
    // Initial crop rect covers the whole image
    _cropRect = Rect.fromLTWH(0, 0, width, height);
  }

  Future<void> _processImage() async {
    if (_cropRect == null || _displayImageSize == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final bytes = await widget.image.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      
      if (decoded != null) {
        // Calculate scale between display and original
        final double scaleX = decoded.width / _displayImageSize!.width;
        final double scaleY = decoded.height / _displayImageSize!.height;
        
        final int x = (_cropRect!.left * scaleX).toInt();
        final int y = (_cropRect!.top * scaleY).toInt();
        final int w = (_cropRect!.width * scaleX).toInt();
        final int h = (_cropRect!.height * scaleY).toInt();
        
        final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
        
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final croppedFile = File(path)..writeAsBytesSync(Uint8List.fromList(img.encodeJpg(cropped)));
        
        if (mounted) {
          Navigator.pop(context, croppedFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _updateCropRect({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (_cropRect == null || _displayImageSize == null) return;

    setState(() {
      double newLeft = left ?? _cropRect!.left;
      double newTop = top ?? _cropRect!.top;
      double newRight = right ?? _cropRect!.right;
      double newBottom = bottom ?? _cropRect!.bottom;

      // Constraints
      const minSize = 50.0;
      
      // Ensure it doesn't go outside image boundaries
      newLeft = newLeft.clamp(0.0, newRight - minSize);
      newTop = newTop.clamp(0.0, newBottom - minSize);
      newRight = newRight.clamp(newLeft + minSize, _displayImageSize!.width);
      newBottom = newBottom.clamp(newTop + minSize, _displayImageSize!.height);

      _cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('CROP', style: AppFonts.poppins(size: 14, weight: FontWeight.w800, color: AppColors.gold, letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isProcessing)
            TextButton(
              onPressed: _processImage,
              child: Text('DONE', style: AppFonts.poppins(color: AppColors.gold, weight: FontWeight.w700)),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<Size>(
            future: _getImageSize(widget.image),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              _initCropRect(Size(constraints.maxWidth, constraints.maxHeight), snapshot.data!);
              
              return Stack(
                children: [
                  // Image
                  Positioned(
                    left: _imageOffset!.dx,
                    top: _imageOffset!.dy,
                    child: Image.file(
                      widget.image,
                      width: _displayImageSize!.width,
                      height: _displayImageSize!.height,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Dimmed Overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CropOverlayPainter(
                        cropRect: _cropRect!.shift(_imageOffset!),
                        fullRect: Offset.zero & Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
                  ),
                  
                  // Draggable Handles & Grid
                  Positioned(
                    left: _imageOffset!.dx + _cropRect!.left,
                    top: _imageOffset!.dy + _cropRect!.top,
                    width: _cropRect!.width,
                    height: _cropRect!.height,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70, width: 1),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Grid Lines
                          _buildGridLines(),
                          
                          // Corner Handles
                          _handle(Alignment.topLeft, (d) => _updateCropRect(left: _cropRect!.left + d.dx, top: _cropRect!.top + d.dy)),
                          _handle(Alignment.topRight, (d) => _updateCropRect(right: _cropRect!.right + d.dx, top: _cropRect!.top + d.dy)),
                          _handle(Alignment.bottomLeft, (d) => _updateCropRect(left: _cropRect!.left + d.dx, bottom: _cropRect!.bottom + d.dy)),
                          _handle(Alignment.bottomRight, (d) => _updateCropRect(right: _cropRect!.right + d.dx, bottom: _cropRect!.bottom + d.dy)),
                          
                          // Side Handles
                          _handle(Alignment.topCenter, (d) => _updateCropRect(top: _cropRect!.top + d.dy)),
                          _handle(Alignment.bottomCenter, (d) => _updateCropRect(bottom: _cropRect!.bottom + d.dy)),
                          _handle(Alignment.centerLeft, (d) => _updateCropRect(left: _cropRect!.left + d.dx)),
                          _handle(Alignment.centerRight, (d) => _updateCropRect(right: _cropRect!.right + d.dx)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      children: [
        Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white38, width: 0.5))))),
        Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white38, width: 0.5))))),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _handle(Alignment alignment, Function(Offset) onDrag) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: _touchAreaSize,
          height: _touchAreaSize,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: _handleSize,
              height: _handleSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Size> _getImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const Size(0, 0);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Rect fullRect;

  CropOverlayPainter({required this.cropRect, required this.fullRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    
    // Draw the dimmed area around the crop rect
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) => 
      oldDelegate.cropRect != cropRect || oldDelegate.fullRect != fullRect;
}
