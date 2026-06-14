import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/carousel_provider.dart';
import '../providers/user_provider.dart';
import '../models/carousel_models.dart';
import '../services/carousel_export_service.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class CarouselEditorScreen extends StatefulWidget {
  const CarouselEditorScreen({super.key});

  @override
  State<CarouselEditorScreen> createState() => _CarouselEditorScreenState();
}

class _CarouselEditorScreenState extends State<CarouselEditorScreen> {
  int? _selectedOverlayIndex;
  final GlobalKey _canvasKey = GlobalKey();
  bool _isLoading = false;
  double _dragStartX = 0;
  double _dragStartY = 0;
  double _lastDragX = 0;
  double _lastDragY = 0;
  double _resizeStartWidth = 0;
  double _resizeStartHeight = 0;
  double _resizeStartX = 0;
  double _resizeStartY = 0;
  String _resizeHandle = ''; // 'tl', 'tr', 'bl', 'br', 'tm', 'bm', 'lm', 'rm'
  bool _isResizing = false;
  final Map<String, Size> _imageSizes = {};

  void debugLog(String message) {
    developer.log('[CarouselEditorScreen] $message');
  }

  void _getImageDimensions(String url) {
    if (_imageSizes.containsKey(url)) return;

    final Image image = Image.network(url);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSizes[url] = Size(info.image.width.toDouble(), info.image.height.toDouble());
            debugLog('🖼️ Image dimensions loaded: ${_imageSizes[url]} for $url');
          });
        }
      }),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _handleDownload() async {
    final carouselProvider = context.read<CarouselProvider>();
    
    setState(() => _isLoading = true);
    
    try {
      debugLog('📥 Starting carousel download...');
      
      // Request storage permissions first
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied. Please grant permission to save files.');
      }
      
      final carousel = carouselProvider.carousel;
      final zipFile = await CarouselExportService.exportCarouselToZip(carousel);
      
      final filePath = zipFile.path;
      final fileName = zipFile.path.split('/').last;
      debugLog('✅ Download complete: $filePath');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.inputBg,
            title: Text(
              '✅ Download Successful!',
              style: AppFonts.playfair(
                size: 22,
                color: AppColors.gold,
                weight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your carousel has been downloaded successfully!',
                  style: AppFonts.poppins(
                    size: 13,
                    color: AppColors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Name:',
                        style: AppFonts.poppins(
                          size: 11,
                          color: AppColors.gold,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        fileName,
                        style: AppFonts.poppins(
                          size: 12,
                          color: AppColors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Full Path:',
                        style: AppFonts.poppins(
                          size: 11,
                          color: AppColors.gold,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        filePath,
                        style: AppFonts.poppins(
                          size: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File saved to app documents folder.',
                        style: AppFonts.poppins(
                          size: 11,
                          color: AppColors.gold,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contains 5 PNG files:\n• slide1.png\n• slide2.png\n• slide3.png\n• slide4.png\n• slide5.png',
                        style: AppFonts.poppins(
                          size: 10,
                          color: AppColors.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: AppFonts.poppins(
                    color: AppColors.gold,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugLog('❌ Download error: $e');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.inputBg,
            title: Text(
              '❌ Download Failed',
              style: AppFonts.playfair(
                size: 22,
                color: Colors.red,
                weight: FontWeight.w900,
              ),
            ),
            content: Text(
              'Error: $e',
              style: AppFonts.poppins(
                size: 12,
                color: AppColors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: AppFonts.poppins(
                    color: AppColors.gold,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddTextDialog(BuildContext context) {
    final carouselProvider = context.read<CarouselProvider>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.inputBg,
        title: Text(
          'Add Text Overlay',
          style: AppFonts.playfair(
            size: 20,
            color: AppColors.white,
            weight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: textController,
          style: AppFonts.poppins(color: AppColors.white),
          decoration: InputDecoration(
            hintText: 'Enter your text...',
            hintStyle: AppFonts.poppins(color: AppColors.muted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold),
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.poppins(color: AppColors.gold),
            ),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final currentSlide = carouselProvider.currentSlide;
                final imageUrl = currentSlide.backgroundImageUrl;
                final imageSize = (imageUrl != null && _imageSizes.containsKey(imageUrl))
                    ? _imageSizes[imageUrl]!
                    : const Size(1080.0, 1350.0);
                
                // Scale initial position and size relative to image dimensions
                // Default was 1080 wide, so we scale by imageSize.width / 1080
                final double scaleFactor = imageSize.width / 1080.0;
                
                final textOverlay = TextOverlay(
                  text: textController.text,
                  x: 50 * scaleFactor,
                  y: 200 * scaleFactor,
                  width: 300 * scaleFactor,
                  height: 60 * scaleFactor,
                  fontSize: (24 * scaleFactor).toInt(),
                  fontFamily: 'Montserrat',
                  fontColor: '#FFFFFF',
                  alignment: 'center',
                );
                carouselProvider.addTextOverlay(textOverlay);
                setState(() => _selectedOverlayIndex = carouselProvider.currentSlide.overlays.length - 1);
                Navigator.pop(context);
                debugLog('✅ Text overlay added: "${textController.text}"');
              }
            },
            child: Text(
              'Add',
              style: AppFonts.poppins(color: AppColors.gold, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPhotoDialog(BuildContext context) async {
    final carouselProvider = context.read<CarouselProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.inputBg,
        title: Text(
          'Select Photo',
          style: AppFonts.playfair(
            size: 20,
            color: AppColors.white,
            weight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: carouselProvider.uploadedImages.length,
            itemBuilder: (context, index) {
              final image = carouselProvider.uploadedImages[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  'Image ${index + 1}',
                  style: AppFonts.poppins(color: AppColors.white, size: 12),
                ),
                onTap: () {
                  final currentSlide = carouselProvider.currentSlide;
                  final imageUrl = currentSlide.backgroundImageUrl;
                  final imageSize = (imageUrl != null && _imageSizes.containsKey(imageUrl))
                      ? _imageSizes[imageUrl]!
                      : const Size(1080.0, 1350.0);
                  
                  // Scale initial position and size relative to image dimensions
                  final double scaleFactor = imageSize.width / 1080.0;

                  final imageOverlay = ImageOverlay(
                    imageFile: image,
                    x: 50 * scaleFactor,
                    y: 100 * scaleFactor,
                    width: 200 * scaleFactor,
                    height: 200 * scaleFactor,
                    rotation: 0,
                    cropShape: 'rectangle',
                  );
                  carouselProvider.addImageOverlay(imageOverlay);
                  setState(() => _selectedOverlayIndex = carouselProvider.currentSlide.overlays.length - 1);
                  Navigator.pop(context);
                  debugLog('✅ Image overlay added');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.poppins(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showTextEditingPanel(BuildContext context, int overlayIndex) {
    final carouselProvider = context.read<CarouselProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inputBg,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        // Use Consumer to watch provider changes inside bottom sheet
        return Consumer<CarouselProvider>(
          builder: (consumerContext, provider, _) {
            // Always get fresh overlay from current provider state
            if (overlayIndex >= provider.currentSlide.overlays.length) {
              return const SizedBox.shrink();
            }
            
            final currentOverlay = provider.currentSlide.overlays[overlayIndex];
            
            if (currentOverlay is! TextOverlay) {
              return const SizedBox.shrink();
            }
            
            final textOverlay = currentOverlay as TextOverlay;
            
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(consumerContext).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Text',
                    style: AppFonts.playfair(
                      size: 24,
                      color: AppColors.white,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Font family selector
                  Text(
                    'Font Family',
                    style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Montserrat', 'Playfair', 'Roboto', 'OpenSans', 'Poppins',
                        'Lora', 'Pacifico', 'Caveat', 'Raleway', 'Merriweather'
                      ].map((font) {
                        final isSelected = textOverlay.fontFamily == font;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              final updated = textOverlay.copyWith(fontFamily: font);
                              provider.updateOverlay(overlayIndex, updated);
                              debugLog('✏️ Font changed to $font');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.gold : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                font,
                                style: AppFonts.poppins(
                                  size: 11,
                                  color: isSelected ? AppColors.black : AppColors.gold,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Font size slider
                  Text(
                    'Font Size: ${textOverlay.fontSize}',
                    style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                  Slider(
                    value: textOverlay.fontSize.toDouble(),
                    min: 12,
                    max: 64,
                    divisions: 13,
                    activeColor: AppColors.gold,
                    inactiveColor: AppColors.gold.withValues(alpha: 0.3),
                    onChanged: (value) {
                      final updated = textOverlay.copyWith(fontSize: value.toInt());
                      provider.updateOverlay(overlayIndex, updated);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Text alignment
                  Text(
                    'Alignment',
                    style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildAlignmentButton(provider, overlayIndex, textOverlay, 'left', Icons.format_align_left),
                      const SizedBox(width: 8),
                      _buildAlignmentButton(provider, overlayIndex, textOverlay, 'center', Icons.format_align_center),
                      const SizedBox(width: 8),
                      _buildAlignmentButton(provider, overlayIndex, textOverlay, 'right', Icons.format_align_right),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bold, Italic, Underline toggles
                  Text(
                    'Text Style',
                    style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStyleToggle(provider, overlayIndex, textOverlay, 'bold', Icons.format_bold, textOverlay.bold),
                      const SizedBox(width: 8),
                      _buildStyleToggle(provider, overlayIndex, textOverlay, 'italic', Icons.format_italic, textOverlay.italic),
                      const SizedBox(width: 8),
                      _buildStyleToggle(provider, overlayIndex, textOverlay, 'underline', Icons.format_underlined, textOverlay.underline),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Font color picker
                  Text(
                    'Font Color',
                    style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildColorCircle('#FFFFFF', textOverlay.fontColor == '#FFFFFF', () {
                        final updated = textOverlay.copyWith(fontColor: '#FFFFFF');
                        provider.updateOverlay(overlayIndex, updated);
                      }),
                      _buildColorCircle('#000000', textOverlay.fontColor == '#000000', () {
                        final updated = textOverlay.copyWith(fontColor: '#000000');
                        provider.updateOverlay(overlayIndex, updated);
                      }),
                      _buildColorCircle('#FFD700', textOverlay.fontColor == '#FFD700', () {
                        final updated = textOverlay.copyWith(fontColor: '#FFD700');
                        provider.updateOverlay(overlayIndex, updated);
                      }),
                      _buildColorCircle('#FF6B6B', textOverlay.fontColor == '#FF6B6B', () {
                        final updated = textOverlay.copyWith(fontColor: '#FF6B6B');
                        provider.updateOverlay(overlayIndex, updated);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Shadow toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Text Shadow',
                          style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final updated = textOverlay.copyWith(shadow: !textOverlay.shadow);
                          provider.updateOverlay(overlayIndex, updated);
                          debugLog('✏️ Shadow toggled: ${updated.shadow}');
                        },
                        child: Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            color: textOverlay.shadow ? AppColors.gold : AppColors.surface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              textOverlay.shadow ? 'ON' : 'OFF',
                              style: AppFonts.poppins(
                                size: 10,
                                color: textOverlay.shadow ? AppColors.black : AppColors.muted,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Opacity slider
                  Text(
                    'Opacity: ${(textOverlay.opacity * 100).toInt()}%',
                    style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                  ),
                  Slider(
                    value: textOverlay.opacity,
                    min: 0,
                    max: 1,
                    activeColor: AppColors.gold,
                    inactiveColor: AppColors.gold.withValues(alpha: 0.3),
                    onChanged: (value) {
                      final updated = textOverlay.copyWith(opacity: value);
                      provider.updateOverlay(overlayIndex, updated);
                    },
                  ),
                  const SizedBox(height: 20),
                  GoldButton(
                    label: 'DONE',
                    onTap: () => Navigator.pop(bottomSheetContext),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildAlignmentButton(CarouselProvider provider, int overlayIndex, TextOverlay overlay, String alignment, IconData icon) {
    final isSelected = overlay.alignment == alignment;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final updated = overlay.copyWith(alignment: alignment);
          provider.updateOverlay(overlayIndex, updated);
          debugLog('✏️ Alignment changed to $alignment');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? AppColors.black : AppColors.gold, size: 18),
        ),
      ),
    );
  }

  Widget _buildStyleToggle(CarouselProvider provider, int overlayIndex, TextOverlay overlay, String style, IconData icon, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          TextOverlay updated;
          if (style == 'bold') {
            updated = overlay.copyWith(bold: !overlay.bold);
          } else if (style == 'italic') {
            updated = overlay.copyWith(italic: !overlay.italic);
          } else {
            updated = overlay.copyWith(underline: !overlay.underline);
          }
          provider.updateOverlay(overlayIndex, updated);
          debugLog('✏️ $style toggled');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isActive ? AppColors.black : AppColors.gold, size: 18),
        ),
      ),
    );
  }

  Widget _buildColorCircle(String color, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(int.parse('0xFF${color.replaceFirst('#', '')}')),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _alignmentButton(BuildContext context, int overlayIndex, TextOverlay overlay, String alignment, IconData icon) {
    final isSelected = overlay.alignment == alignment;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final updated = overlay.copyWith(alignment: alignment);
          context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
          setState(() {}); // Refresh UI
          debugLog('✏️ Alignment changed to $alignment');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? AppColors.black : AppColors.gold, size: 18),
        ),
      ),
    );
  }

  Widget _styleToggleButton(BuildContext context, int overlayIndex, TextOverlay overlay, String style, IconData icon, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          TextOverlay updated;
          if (style == 'bold') {
            updated = overlay.copyWith(bold: !overlay.bold);
          } else if (style == 'italic') {
            updated = overlay.copyWith(italic: !overlay.italic);
          } else {
            updated = overlay.copyWith(underline: !overlay.underline);
          }
          context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
          setState(() {}); // Refresh UI
          debugLog('✏️ $style toggled');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isActive ? AppColors.black : AppColors.gold, size: 18),
        ),
      ),
    );
  }

  Widget _colorCircle(String color, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(int.parse('0xFF${color.replaceFirst('#', '')}')),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    final carouselProvider = context.watch<CarouselProvider>();
    final currentSlide = carouselProvider.currentSlide;
    final currentSlideIndex = carouselProvider.currentSlideIndex;
    
    // Determine actual image size for constraints
    final String? imageUrl = currentSlide.backgroundImageUrl;
    final Size imageSize = (imageUrl != null && _imageSizes.containsKey(imageUrl))
        ? _imageSizes[imageUrl]!
        : const Size(1080.0, 1350.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: Column(
              children: [
                // Slide thumbnails
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: AppColors.surface.withValues(alpha: 0.3),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(5, (index) {
                        final isActive = currentSlideIndex == index;
                        final slide = carouselProvider.carousel.slides[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              carouselProvider.switchToSlide(index);
                              setState(() => _selectedOverlayIndex = null);
                            },
                            child: Container(
                              width: 70,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.gold
                                      : AppColors.gold.withValues(alpha: 0.2),
                                  width: isActive ? 2 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.gold.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: slide.backgroundImageUrl != null
                                    ? Image.network(
                                        slide.backgroundImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.inputBg,
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: AppFonts.poppins(
                                                  size: 12,
                                                  color: AppColors.gold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AppColors.inputBg,
                                        child: Center(
                                          child: Text(
                                            'Slide ${index + 1}',
                                            style: AppFonts.poppins(
                                              size: 10,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // Main editor canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final String? imageUrl = currentSlide.backgroundImageUrl;
                        if (imageUrl != null) {
                          _getImageDimensions(imageUrl);
                        }
                        
                        // Determine actual image size - default to 1080x1350 (Instagram portrait)
                        final Size imageSize = (imageUrl != null && _imageSizes.containsKey(imageUrl))
                            ? _imageSizes[imageUrl]!
                            : const Size(1080.0, 1350.0);
                        
                        final double canvasWidth = imageSize.width;
                        final double canvasHeight = imageSize.height;
                        final double aspectRatio = canvasWidth / canvasHeight;
                        
                        // Calculate display dimensions to fit within constraints
                        double displayWidth = constraints.maxWidth;
                        double displayHeight = displayWidth / aspectRatio;
                        
                        if (displayHeight > constraints.maxHeight) {
                          displayHeight = constraints.maxHeight;
                          displayWidth = displayHeight * aspectRatio;
                        }
                        
                        // Scale factor between image pixels and display pixels
                        final double scale = canvasWidth / displayWidth;

                        return Center(
                          child: Container(
                            width: displayWidth,
                            height: displayHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: canvasWidth,
                                  height: canvasHeight,
                                  child: Stack(
                                    key: _canvasKey,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Background image
                                      if (imageUrl != null)
                                        Image.network(
                                          imageUrl,
                                          width: canvasWidth,
                                          height: canvasHeight,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.inputBg,
                                            child: const Center(child: Icon(Icons.error, color: AppColors.gold, size: 48)),
                                          ),
                                        )
                                      else
                                        Container(
                                          color: AppColors.inputBg,
                                          width: canvasWidth,
                                          height: canvasHeight,
                                          child: Center(
                                            child: Text(
                                              'No Background Image',
                                              style: AppFonts.poppins(size: 32, color: AppColors.muted),
                                            ),
                                          ),
                                        ),
                                        
                                      // Overlays with drag/resize handles
                                      ...List.generate(
                                        currentSlide.overlays.length,
                                        (overlayIndex) {
                                          final overlay = currentSlide.overlays[overlayIndex];
                                          final isSelected = _selectedOverlayIndex == overlayIndex;

                                          return Positioned(
                                            left: overlay.x,
                                            top: overlay.y,
                                            width: overlay.width,
                                            height: overlay.height,
                                            child: GestureDetector(
                                              onPanStart: (details) {
                                                if (isSelected && _resizeHandle.isEmpty) {
                                                  _dragStartX = details.globalPosition.dx;
                                                  _dragStartY = details.globalPosition.dy;
                                                  _lastDragX = overlay.x;
                                                  _lastDragY = overlay.y;
                                                }
                                              },
                                              onPanUpdate: (details) {
                                                if (isSelected && !_isResizing) {
                                                  // Apply scale factor to global movement
                                                  final deltaX = (details.globalPosition.dx - _dragStartX) * scale;
                                                  final deltaY = (details.globalPosition.dy - _dragStartY) * scale;
                                                  final newX = (_lastDragX + deltaX).clamp(0.0, canvasWidth);
                                                  final newY = (_lastDragY + deltaY).clamp(0.0, canvasHeight);
                                                  
                                                  if (overlay is TextOverlay) {
                                                    final updated = overlay.copyWith(x: newX, y: newY);
                                                    context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
                                                  } else if (overlay is ImageOverlay) {
                                                    final updated = overlay.copyWith(x: newX, y: newY);
                                                    context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
                                                  }
                                                }
                                              },
                                              onTap: () {
                                                setState(() => _selectedOverlayIndex = overlayIndex);
                                                if (overlay is TextOverlay) {
                                                  final ctx = context;
                                                  Future.delayed(const Duration(milliseconds: 100), () {
                                                    if (mounted) {
                                                      _showTextEditingPanel(ctx, overlayIndex);
                                                    }
                                                  });
                                                }
                                              },
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  // Content
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
                                                    ),
                                                    child: overlay is TextOverlay
                                                        ? Container(
                                                            color: overlay.backgroundColor != 'transparent'
                                                                ? Color(int.parse('0xFF${overlay.backgroundColor.replaceFirst('#', '')}'))
                                                                : Colors.transparent,
                                                            padding: const EdgeInsets.all(8),
                                                            child: SingleChildScrollView(
                                                              child: Text(
                                                                overlay.text,
                                                                textAlign: overlay.alignment == 'left'
                                                                    ? TextAlign.left
                                                                    : overlay.alignment == 'right'
                                                                        ? TextAlign.right
                                                                        : TextAlign.center,
                                                                maxLines: null,
                                                                overflow: TextOverflow.visible,
                                                                style: TextStyle(
                                                                  fontSize: overlay.fontSize.toDouble(),
                                                                  fontFamily: overlay.fontFamily,
                                                                  color: Color(int.parse('0xFF${overlay.fontColor.replaceFirst('#', '')}')),
                                                                  fontWeight: overlay.bold ? FontWeight.bold : FontWeight.normal,
                                                                  fontStyle: overlay.italic ? FontStyle.italic : FontStyle.normal,
                                                                  decoration: overlay.underline ? TextDecoration.underline : TextDecoration.none,
                                                                  shadows: overlay.shadow ? [const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))] : [],
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Image.file((overlay as ImageOverlay).imageFile, fit: BoxFit.cover),
                                                  ),
                                                  // Resize handles (only when selected)
                                                  if (isSelected) ...[
                                                    // Top-left
                                                    Positioned(
                                                      left: -12,
                                                      top: -12,
                                                      child: GestureDetector(
                                                        onPanStart: (details) {
                                                          _isResizing = true;
                                                          _resizeHandle = 'tl';
                                                          _dragStartX = details.globalPosition.dx;
                                                          _dragStartY = details.globalPosition.dy;
                                                          _resizeStartX = overlay.x;
                                                          _resizeStartY = overlay.y;
                                                          _resizeStartWidth = overlay.width;
                                                          _resizeStartHeight = overlay.height;
                                                        },
                                                        onPanUpdate: (details) {
                                                          if (_resizeHandle == 'tl') {
                                                            final deltaX = (details.globalPosition.dx - _dragStartX) * scale;
                                                            final deltaY = (details.globalPosition.dy - _dragStartY) * scale;
                                                            
                                                            final newX = _resizeStartX + deltaX;
                                                            final newY = _resizeStartY + deltaY;
                                                            final newW = (_resizeStartWidth - deltaX).clamp(50.0, canvasWidth);
                                                            final newH = (_resizeStartHeight - deltaY).clamp(50.0, canvasHeight);
                                                            
                                                            if (overlay is TextOverlay) {
                                                              final updated = overlay.copyWith(x: newX, y: newY, width: newW, height: newH);
                                                              context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
                                                            } else {
                                                              final updated = (overlay as ImageOverlay).copyWith(x: newX, y: newY, width: newW, height: newH);
                                                              context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
                                                            }
                                                          }
                                                        },
                                                        onPanEnd: (_) {
                                                          _isResizing = false;
                                                          _resizeHandle = '';
                                                        },
                                                        child: Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.gold,
                                                            shape: BoxShape.circle,
                                                            border: Border.all(color: Colors.white, width: 2),
                                                          ),
                                                          child: const Icon(Icons.open_in_full, size: 12, color: Colors.black),
                                                        ),
                                                      ),
                                                    ),
                                                    // Bottom-right
                                                    Positioned(
                                                      right: -12,
                                                      bottom: -12,
                                                      child: GestureDetector(
                                                        onPanStart: (details) {
                                                          _isResizing = true;
                                                          _resizeHandle = 'br';
                                                          _dragStartX = details.globalPosition.dx;
                                                          _dragStartY = details.globalPosition.dy;
                                                          _resizeStartWidth = overlay.width;
                                                          _resizeStartHeight = overlay.height;
                                                        },
                                                        onPanUpdate: (details) {
                                                          if (_resizeHandle == 'br') {
                                                            final deltaX = (details.globalPosition.dx - _dragStartX) * scale;
                                                            final deltaY = (details.globalPosition.dy - _dragStartY) * scale;
                                                            
                                                            final newW = (_resizeStartWidth + deltaX).clamp(50.0, canvasWidth);
                                                            final newH = (_resizeStartHeight + deltaY).clamp(50.0, canvasHeight);
                                                            
                                                            if (overlay is TextOverlay) {
                                                              final updated = overlay.copyWith(width: newW, height: newH);
                                                              context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
                                                            } else {
                                                              final updated = (overlay as ImageOverlay).copyWith(width: newW, height: newH);
                                                              context.read<CarouselProvider>().updateOverlay(overlayIndex, updated);
                                                            }
                                                          }
                                                        },
                                                        onPanEnd: (_) {
                                                          _isResizing = false;
                                                          _resizeHandle = '';
                                                        },
                                                        child: Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.gold,
                                                            shape: BoxShape.circle,
                                                            border: Border.all(color: Colors.white, width: 2),
                                                          ),
                                                          child: const Icon(Icons.open_in_full, size: 12, color: Colors.black),
                                                        ),
                                                      ),
                                                    ),
                                                    // Delete button
                                                    Positioned(
                                                      right: -12,
                                                      top: -12,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          context.read<CarouselProvider>().removeOverlay(overlayIndex);
                                                          setState(() => _selectedOverlayIndex = null);
                                                          debugLog('🗑️ Overlay deleted');
                                                        },
                                                        child: Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: const BoxDecoration(
                                                            color: Colors.red,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                ),

                // Bottom toolbar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.3),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Overlay resize controls (if one is selected)
                      if (_selectedOverlayIndex != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Decrease size button
                              GestureDetector(
                                onTap: () {
                                  final overlay = carouselProvider.currentSlide.overlays[_selectedOverlayIndex!];
                                  final newWidth = (overlay.width - 20).clamp(50.0, imageSize.width);
                                  double newHeight = (overlay.height - 20).clamp(50.0, imageSize.height);
                                  
                                  // Auto-adjust height for text
                                  if (overlay is TextOverlay) {
                                    final textOverlay = overlay as TextOverlay;
                                    final charCount = textOverlay.text.length;
                                    final avgCharsPerLine = newWidth / (textOverlay.fontSize / 2);
                                    final estimatedLines = (charCount / avgCharsPerLine).ceil();
                                    newHeight = (estimatedLines * textOverlay.fontSize * 1.5).clamp(50.0, imageSize.height);
                                    
                                    final updated = overlay.copyWith(width: newWidth, height: newHeight);
                                    carouselProvider.updateOverlay(_selectedOverlayIndex!, updated);
                                  } else {
                                    // For images, maintain aspect ratio
                                    final imageOverlay = overlay as ImageOverlay;
                                    final aspectRatio = overlay.width / overlay.height;
                                    final updated = imageOverlay.copyWith(width: newWidth, height: newWidth / aspectRatio);
                                    carouselProvider.updateOverlay(_selectedOverlayIndex!, updated);
                                  }
                                  debugLog('📉 Size reduced');
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.remove, color: AppColors.black, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Size input field
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final overlay = carouselProvider.currentSlide.overlays[_selectedOverlayIndex!];
                                    final sizeController = TextEditingController(
                                      text: overlay.width.toInt().toString(),
                                    );
                                    
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppColors.inputBg,
                                        title: Text(
                                          'Set Width',
                                          style: AppFonts.playfair(
                                            size: 20,
                                            color: AppColors.white,
                                          ),
                                        ),
                                        content: TextField(
                                          controller: sizeController,
                                          keyboardType: TextInputType.number,
                                          style: AppFonts.poppins(color: AppColors.white),
                                          decoration: InputDecoration(
                                            hintText: 'Enter width',
                                            hintStyle: AppFonts.poppins(color: AppColors.muted),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: AppColors.gold),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: AppColors.surface,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel', style: AppFonts.poppins(color: AppColors.gold)),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              final newWidth = double.tryParse(sizeController.text) ?? overlay.width;
                                              final clampedWidth = newWidth.clamp(50.0, imageSize.width);
                                              
                                              // Auto-adjust height based on text wrapping or aspect ratio
                                              double newHeight = overlay.height;
                                              if (overlay is TextOverlay) {
                                                // Estimate new height based on character count and width
                                                final textOverlay = overlay as TextOverlay;
                                                final charCount = textOverlay.text.length;
                                                final avgCharsPerLine = clampedWidth / (textOverlay.fontSize / 2);
                                                final estimatedLines = (charCount / avgCharsPerLine).ceil();
                                                newHeight = (estimatedLines * textOverlay.fontSize * 1.5).clamp(50.0, imageSize.height);
                                                
                                                final updated = overlay.copyWith(width: clampedWidth, height: newHeight);
                                                carouselProvider.updateOverlay(_selectedOverlayIndex!, updated);
                                              } else {
                                                // For images, maintain aspect ratio
                                                final imageOverlay = overlay as ImageOverlay;
                                                final aspectRatio = overlay.width / overlay.height;
                                                newHeight = clampedWidth / aspectRatio;
                                                
                                                final updated = imageOverlay.copyWith(width: clampedWidth, height: newHeight);
                                                carouselProvider.updateOverlay(_selectedOverlayIndex!, updated);
                                              }
                                              Navigator.pop(context);
                                              debugLog('✏️ Size set to width: $clampedWidth, height: $newHeight');
                                            },
                                            child: Text('Set', style: AppFonts.poppins(color: AppColors.gold, weight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.gold.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'W: ${carouselProvider.currentSlide.overlays[_selectedOverlayIndex!].width.toInt()}',
                                        style: AppFonts.poppins(
                                          size: 12,
                                          color: AppColors.gold,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Increase size button
                              GestureDetector(
                                onTap: () {
                                  final overlay = carouselProvider.currentSlide.overlays[_selectedOverlayIndex!];
                                  final newWidth = (overlay.width + 20).clamp(50.0, imageSize.width);
                                  double newHeight = (overlay.height + 20).clamp(50.0, imageSize.height);
                                  
                                  // Auto-adjust height for text
                                  if (overlay is TextOverlay) {
                                    final textOverlay = overlay as TextOverlay;
                                    final charCount = textOverlay.text.length;
                                    final avgCharsPerLine = newWidth / (textOverlay.fontSize / 2);
                                    final estimatedLines = (charCount / avgCharsPerLine).ceil();
                                    newHeight = (estimatedLines * textOverlay.fontSize * 1.5).clamp(50.0, imageSize.height);
                                    
                                    final updated = overlay.copyWith(width: newWidth, height: newHeight);
                                    carouselProvider.updateOverlay(_selectedOverlayIndex!, updated);
                                  } else {
                                    // For images, maintain aspect ratio
                                    final imageOverlay = overlay as ImageOverlay;
                                    final aspectRatio = overlay.width / overlay.height;
                                    final updated = imageOverlay.copyWith(width: newWidth, height: newWidth / aspectRatio);
                                    carouselProvider.updateOverlay(_selectedOverlayIndex!, updated);
                                  }
                                  debugLog('📈 Size increased');
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add, color: AppColors.black, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Main toolbar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.image, color: AppColors.gold, size: 20),
                                    onPressed: carouselProvider.uploadedImages.isEmpty ? null : () => _showAddPhotoDialog(context),
                                    tooltip: 'Add Photo',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.text_fields, color: AppColors.gold, size: 20),
                                    onPressed: () => _showAddTextDialog(context),
                                    tooltip: 'Add Text',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.undo,
                                      color: carouselProvider.canUndo ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3),
                                      size: 20,
                                    ),
                                    onPressed: carouselProvider.canUndo ? () {
                                      carouselProvider.undo();
                                      setState(() => _selectedOverlayIndex = null);
                                      debugLog('↶ Undo executed');
                                    } : null,
                                    tooltip: 'Undo',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.redo,
                                      color: carouselProvider.canRedo ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3),
                                      size: 20,
                                    ),
                                    onPressed: carouselProvider.canRedo ? () {
                                      carouselProvider.redo();
                                      setState(() => _selectedOverlayIndex = null);
                                      debugLog('↷ Redo executed');
                                    } : null,
                                    tooltip: 'Redo',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bottom buttons
                      if (_isLoading)
                        // During download - full width download button
                        GoldButton(
                          label: 'DOWNLOADING...',
                          onTap: null,
                        )
                      else
                        // Normal state - back and download buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.surface,
                                    border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'BACK',
                                      style: AppFonts.poppins(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: AppColors.gold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GoldButton(
                                label: 'DOWNLOAD',
                                onTap: _handleDownload,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
