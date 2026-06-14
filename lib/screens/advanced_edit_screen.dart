import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/filter_service.dart';
import '../services/fal_ai_service.dart';
import '../services/carousel_export_service.dart';
import '../models/carousel_models.dart';
import 'crop_resize_screen.dart';
import 'edit_review_screen.dart';
import 'package:image_picker/image_picker.dart';

class AdvancedEditScreen extends StatefulWidget {
  final File image;
  const AdvancedEditScreen({super.key, required this.image});

  @override
  State<AdvancedEditScreen> createState() => _AdvancedEditScreenState();
}

class _AdvancedEditScreenState extends State<AdvancedEditScreen> {
  late File _currentImage;
  bool _isFilterMode = false;
  bool _isDrawingMode = false;
  String _selectedFilter = 'None';
  bool _isProcessing = false;
  Uint8List? _originalBytes;
  Uint8List? _previewBytes;
  final FalAiService _falAiService = FalAiService();
  final List<OverlayElement> _overlays = [];
  OverlayElement? _selectedOverlay;
  
  // Drawing state
  final List<DrawingPath> _currentSessionPaths = [];
  DrawingPath? _activePath;
  Color _selectedDrawColor = Colors.red;
  double _drawWidth = 5.0;

  final GlobalKey _imageKey = GlobalKey();
  Size _canvasSize = Size.zero; // Real image size in pixels

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    final bytes = await _currentImage.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    
    setState(() {
      _originalBytes = bytes;
      _previewBytes = bytes;
      _canvasSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    });
  }

  void _handleTool(String tool) async {
    if (tool == 'Filters') {
      setState(() => _isFilterMode = true);
    } else if (tool == 'Crop & Resize') {
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (_) => CropResizeScreen(image: _currentImage)),
      );
      if (croppedFile != null) {
        setState(() => _currentImage = croppedFile);
        _loadBytes();
      }
    } else if (tool == 'Enhance') {
      _enhanceImage();
    } else if (tool == 'Overlays') {
      _showOverlayMenu();
    } else if (tool == 'Draw') {
      setState(() => _isDrawingMode = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$tool coming soon!'), duration: const Duration(seconds: 1)),
      );
    }
  }

  void _saveDrawing() {
    if (_currentSessionPaths.isNotEmpty) {
      setState(() {
        _overlays.add(DrawingOverlay(
          paths: List.from(_currentSessionPaths),
          x: 0,
          y: 0,
          width: _canvasSize.width,
          height: _canvasSize.height,
        ));
        _currentSessionPaths.clear();
        _isDrawingMode = false;
      });
    } else {
      setState(() => _isDrawingMode = false);
    }
  }

  Widget _buildTopDrawingSettings() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('SIZE', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _drawWidth,
                    min: 1, max: 20,
                    activeColor: AppColors.gold,
                    inactiveColor: Colors.white10,
                    onChanged: (val) => setState(() => _drawWidth = val),
                  ),
                ),
              ),
              Text('${_drawWidth.toInt()}', style: AppFonts.poppins(size: 10, color: Colors.white, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Colors.red, Colors.blue, Colors.green, Colors.yellow, 
                Colors.white, Colors.black, Colors.purple, Colors.orange,
                Colors.pink, Colors.teal, Colors.cyan, Colors.amber,
              ].map((color) => _colorCircle(color)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _drawingToolItem(Icons.undo, 'Undo', () {
            if (_currentSessionPaths.isNotEmpty) {
              setState(() => _currentSessionPaths.removeLast());
            }
          }),
          _drawingToolItem(Icons.settings, 'Settings', () {
            _showBrushSettingsPopup();
          }),
          _drawingToolItem(Icons.check_circle, 'Apply', () {
            _saveDrawing();
          }, isPrimary: true),
        ],
      ),
    );
  }

  Widget _drawingToolItem(IconData icon, String label, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isPrimary ? 64 : 48,
            height: isPrimary ? 64 : 48,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.gold : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: isPrimary ? Colors.black : AppColors.gold, size: isPrimary ? 32 : 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppFonts.poppins(size: 11, color: isPrimary ? AppColors.gold : AppColors.muted, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showBrushSettingsPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inputBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Brush Settings', style: AppFonts.playfair(size: 22, color: AppColors.white, weight: FontWeight.w900)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BRUSH SIZE', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                      Text('${_drawWidth.toInt()}', style: AppFonts.poppins(size: 11, color: AppColors.white, weight: FontWeight.w600)),
                    ],
                  ),
                  Slider(
                    value: _drawWidth,
                    min: 1, max: 20,
                    activeColor: AppColors.gold,
                    inactiveColor: Colors.white12,
                    onChanged: (value) => setModalState(() {
                      setState(() => _drawWidth = value);
                    }),
                  ),
                  const SizedBox(height: 24),
                  Text('BRUSH COLOR', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Colors.red, Colors.blue, Colors.green, Colors.yellow, 
                        Colors.white, Colors.black, Colors.purple, Colors.orange,
                        Colors.pink, Colors.teal, Colors.cyan, Colors.amber,
                      ].map((color) {
                        final isSelected = _selectedDrawColor == color;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setModalState(() {
                              setState(() => _selectedDrawColor = color);
                            }),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? Colors.white : Colors.white10, width: isSelected ? 2 : 1),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _colorCircle(Color color) {
    bool isSelected = _selectedDrawColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedDrawColor = color),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : null,
        ),
      ),
    );
  }

  void _showOverlayMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151510),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _overlayOption(Icons.text_fields, 'Add Text', () {
                  Navigator.pop(context);
                  _addTextOverlay();
                }),
                _overlayOption(Icons.add_photo_alternate_outlined, 'Add Image', () {
                  Navigator.pop(context);
                  _addImageOverlay();
                }),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _overlayOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 28),
          ),
          const SizedBox(height: 12),
          Text(label, style: AppFonts.poppins(size: 12, color: AppColors.white, weight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _addTextOverlay() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('ADD TEXT', style: AppFonts.poppins(size: 16, weight: FontWeight.w700, color: AppColors.gold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  // Put in the middle of the image by default
                  final double w = _canvasSize.width * 0.5;
                  final double h = _canvasSize.height * 0.1;
                  _overlays.add(TextOverlay(
                    text: controller.text,
                    x: (_canvasSize.width - w) / 2,
                    y: (_canvasSize.height - h) / 2,
                    width: w,
                    height: h,
                    fontSize: (_canvasSize.height * 0.05).toInt().clamp(20, 200),
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('ADD', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addImageOverlay() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        final double w = _canvasSize.width * 0.3;
        final double h = _canvasSize.width * 0.3; // Square default
        _overlays.add(ImageOverlay(
          imageFile: File(pickedFile.path),
          x: (_canvasSize.width - w) / 2,
          y: (_canvasSize.height - h) / 2,
          width: w,
          height: h,
        ));
      });
    }
  }

  void _showTextEditingPanel(int overlayIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inputBg,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final textOverlay = _overlays[overlayIndex] as TextOverlay;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle & Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Text', style: AppFonts.playfair(size: 22, color: AppColors.white, weight: FontWeight.w900)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Text Input
                    TextField(
                      controller: TextEditingController(text: textOverlay.text),
                      style: AppFonts.poppins(color: Colors.white, size: 14),
                      decoration: InputDecoration(
                        labelText: 'TEXT CONTENT',
                        labelStyle: const TextStyle(color: AppColors.gold, fontSize: 10, letterSpacing: 1),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _overlays[overlayIndex] = textOverlay.copyWith(text: val);
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Font family selector
                    Text('FONT FAMILY', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Montserrat', 'Playfair', 'Roboto', 'OpenSans', 'Poppins', 'Lora', 'Pacifico', 'Caveat', 'Raleway', 'Merriweather'].map((font) {
                          final isSelected = textOverlay.fontFamily == font;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setModalState(() {
                                setState(() => _overlays[overlayIndex] = textOverlay.copyWith(fontFamily: font));
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.gold : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(font, style: AppFonts.poppins(size: 11, color: isSelected ? AppColors.black : AppColors.text, weight: FontWeight.w600)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Font size slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('FONT SIZE', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                        Text('${textOverlay.fontSize}', style: AppFonts.poppins(size: 11, color: AppColors.white, weight: FontWeight.w600)),
                      ],
                    ),
                    Slider(
                      value: textOverlay.fontSize.toDouble(),
                      min: 12, max: 120,
                      activeColor: AppColors.gold,
                      inactiveColor: Colors.white12,
                      onChanged: (value) => setModalState(() {
                        setState(() => _overlays[overlayIndex] = textOverlay.copyWith(fontSize: value.toInt()));
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Alignment & Style
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ALIGNMENT', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildAlignmentBtn(overlayIndex, textOverlay, 'left', Icons.format_align_left, setModalState),
                                  const SizedBox(width: 6),
                                  _buildAlignmentBtn(overlayIndex, textOverlay, 'center', Icons.format_align_center, setModalState),
                                  const SizedBox(width: 6),
                                  _buildAlignmentBtn(overlayIndex, textOverlay, 'right', Icons.format_align_right, setModalState),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('STYLE', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildStyleTgl(overlayIndex, textOverlay, 'bold', Icons.format_bold, textOverlay.bold, setModalState),
                                  const SizedBox(width: 6),
                                  _buildStyleTgl(overlayIndex, textOverlay, 'italic', Icons.format_italic, textOverlay.italic, setModalState),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Colors
                    Text('FONT COLOR', style: AppFonts.poppins(size: 10, color: AppColors.gold, weight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['#FFFFFF', '#000000', '#FFD700', '#FF6B6B', '#4ECDC4', '#A8E6CF', '#FF9F1C', '#2EC4B6'].map((color) {
                          return _buildColorCirc(color, textOverlay.fontColor == color, () {
                            setModalState(() {
                              setState(() => _overlays[overlayIndex] = textOverlay.copyWith(fontColor: color));
                            });
                          });
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }


  Widget _buildAlignmentBtn(int idx, TextOverlay overlay, String align, IconData icon, StateSetter setModalState) {
    final isSelected = overlay.alignment == align;
    return GestureDetector(
      onTap: () => setModalState(() {
        setState(() => _overlays[idx] = overlay.copyWith(alignment: align));
      }),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isSelected ? AppColors.gold : AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isSelected ? AppColors.black : AppColors.gold, size: 18),
      ),
    );
  }

  Widget _buildStyleTgl(int idx, TextOverlay overlay, String style, IconData icon, bool isActive, StateSetter setModalState) {
    return GestureDetector(
      onTap: () => setModalState(() {
        if (style == 'bold') {
          setState(() => _overlays[idx] = overlay.copyWith(bold: !overlay.bold));
        } else {
          setState(() => _overlays[idx] = overlay.copyWith(italic: !overlay.italic));
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isActive ? AppColors.gold : AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isActive ? AppColors.black : AppColors.gold, size: 18),
      ),
    );
  }

  Widget _buildColorCirc(String color, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? AppColors.gold : Colors.white24, width: isSelected ? 2 : 1),
          ),
        ),
      ),
    );
  }

  Future<void> _enhanceImage() async {
    setState(() => _isProcessing = true);
    try {
      // 1. Convert current image bytes to Base64
      if (_originalBytes == null) return;
      final String base64Image = 'data:image/jpeg;base64,${base64Encode(_originalBytes!)}';

      // 2. Call Fal AI to enhance using base64
      final String enhancedUrl = await _falAiService.enhanceImage(base64Image: base64Image);

      // 3. Download enhanced image
      final response = await http.get(Uri.parse(enhancedUrl));
      if (response.statusCode == 200) {
        final Uint8List enhancedBytes = response.bodyBytes;
        
        // Update canvas size for new enhanced image
        final decoded = await decodeImageFromList(enhancedBytes);
        
        // 4. Save to temp file locally
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final enhancedFile = File(path)..writeAsBytesSync(enhancedBytes);

        setState(() {
          _currentImage = enhancedFile;
          _originalBytes = enhancedBytes;
          _previewBytes = enhancedBytes;
          _canvasSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image enhanced successfully!')),
          );
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enhancement failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_overlays.isEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditReviewScreen(
              editedFile: _currentImage,
              originalFile: widget.image,
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Bake overlays into the image
      final bakedBytes = await CarouselExportService.bakeOverlays(
        _previewBytes ?? _originalBytes!,
        _overlays,
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/final_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final finalFile = File(path)..writeAsBytesSync(bakedBytes);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditReviewScreen(
              editedFile: finalFile,
              originalFile: widget.image,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _applyFilter(String filterName) async {
    if (_originalBytes == null) return;
    setState(() {
      _selectedFilter = filterName;
      _isProcessing = true;
    });

    // Run filter in background-like feel
    final filtered = await Future.delayed(Duration.zero, () {
      return FilterService.applyFilter(_originalBytes!, filterName);
    });

    setState(() {
      _previewBytes = filtered;
      _isProcessing = false;
    });
  }

  Future<void> _saveFilter() async {
    if (_previewBytes == null) return;
    
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filteredFile = File(path)..writeAsBytesSync(_previewBytes!);
    
    setState(() {
      _currentImage = filteredFile;
      _isFilterMode = false;
      _originalBytes = _previewBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isFilterMode ? 'FILTERS' : (_isDrawingMode ? 'DRAW' : 'EDITOR'), 
          style: AppFonts.poppins(size: 14, weight: FontWeight.w800, color: AppColors.gold, letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon((_isFilterMode || _isDrawingMode) ? Icons.close : Icons.close, color: AppColors.white),
          onPressed: () {
            if (_isFilterMode) {
              setState(() {
                _isFilterMode = false;
                _previewBytes = _originalBytes;
                _selectedFilter = 'None';
              });
            } else if (_isDrawingMode) {
              setState(() {
                _isDrawingMode = false;
                _currentSessionPaths.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isFilterMode)
            TextButton(
              onPressed: _saveFilter,
              child: Text('APPLY', style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold)),
            )
          else if (_isDrawingMode)
            TextButton(
              onPressed: _saveDrawing,
              child: Text('APPLY', style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold)),
            )
          else
            TextButton(
              onPressed: _handleSave,
              child: Text('SAVE', style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double previewWidth = constraints.maxWidth;
                  final double previewHeight = constraints.maxHeight;
                  
                  double scale = 1.0;
                  double offsetX = 0;
                  double offsetY = 0;
                  
                  if (_canvasSize != Size.zero) {
                    final canvasAspect = _canvasSize.width / _canvasSize.height;
                    final previewAspect = previewWidth / previewHeight;
                    
                    if (canvasAspect > previewAspect) {
                      scale = previewWidth / _canvasSize.width;
                      offsetY = (previewHeight - (_canvasSize.height * scale)) / 2;
                    } else {
                      scale = previewHeight / _canvasSize.height;
                      offsetX = (previewWidth - (_canvasSize.width * scale)) / 2;
                    }
                  }

                  return GestureDetector(
                    onTap: () => setState(() => _selectedOverlay = null),
                    onPanStart: _isDrawingMode ? (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final offset = box.globalToLocal(details.globalPosition);
                      
                      final canvasX = (offset.dx - offsetX) / scale;
                      final canvasY = (offset.dy - offsetY) / scale;
                      
                      setState(() {
                        _activePath = DrawingPath(
                          points: [[canvasX, canvasY]],
                          color: '#${_selectedDrawColor.value.toRadixString(16).substring(2).toUpperCase()}',
                          strokeWidth: _drawWidth,
                        );
                        _currentSessionPaths.add(_activePath!);
                      });
                    } : null,
                    onPanUpdate: _isDrawingMode ? (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final offset = box.globalToLocal(details.globalPosition);
                      
                      final canvasX = (offset.dx - offsetX) / scale;
                      final canvasY = (offset.dy - offsetY) / scale;
                      
                      if (_activePath != null) {
                        setState(() {
                          _activePath!.points.add([canvasX, canvasY]);
                        });
                      }
                    } : null,
                    onPanEnd: _isDrawingMode ? (_) => _activePath = null : null,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        // Base Image
                        Center(
                          child: _previewBytes != null 
                            ? Image.memory(
                                _previewBytes!, 
                                key: ValueKey('filter_$_selectedFilter'),
                                fit: BoxFit.fitWidth,
                                width: double.infinity,
                              )
                            : Image.file(
                                _currentImage, 
                                fit: BoxFit.fitWidth,
                                width: double.infinity,
                              ),
                        ),
                        
                        // Current Session Drawing (in real-time)
                        if (_isDrawingMode) ...[
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DrawPainter(
                                paths: _currentSessionPaths,
                                scale: scale,
                                offsetX: offsetX,
                                offsetY: offsetY,
                              ),
                            ),
                          ),
                          // Top Settings Bar for Drawing
                          Positioned(
                            top: 20,
                            left: 20,
                            right: 20,
                            child: _buildTopDrawingSettings(),
                          ),
                        ],

                        // Render Overlays
                        ..._overlays.asMap().entries.map((entry) {
                          final index = entry.key;
                          final overlay = entry.value;
                          return _buildOverlayWidget(overlay, index, scale, offsetX, offsetY);
                        }).toList(),

                        if (_isProcessing)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: AppColors.gold),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isFilterMode ? 'Applying Filter...' : 'Enhancing Image...',
                                    style: AppFonts.poppins(size: 14, weight: FontWeight.w600, color: AppColors.gold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
              ),
            ),
          ),
          
          // Tools / Filters Area
          Container(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF151510),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
            ),
            child: _isFilterMode ? _buildFilterList() : _buildToolList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayWidget(OverlayElement overlay, int index, double scale, double offsetX, double offsetY) {
    final isSelected = _selectedOverlay == overlay;
    
    // Convert canvas coordinates to screen coordinates
    final screenX = offsetX + (overlay.x * scale);
    final screenY = offsetY + (overlay.y * scale);
    final screenW = overlay.width * scale;
    final screenH = overlay.height * scale;

    return Positioned(
      left: screenX,
      top: screenY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Convert screen delta back to canvas delta
            final dx = details.delta.dx / scale;
            final dy = details.delta.dy / scale;
            
            if (overlay is TextOverlay) {
              _overlays[index] = (overlay as TextOverlay).copyWith(
                x: overlay.x + dx,
                y: overlay.y + dy,
              );
            } else if (overlay is ImageOverlay) {
              _overlays[index] = (overlay as ImageOverlay).copyWith(
                x: overlay.x + dx,
                y: overlay.y + dy,
              );
            }
          });
        },
        onTap: () {
          setState(() => _selectedOverlay = overlay);
          if (overlay is TextOverlay) {
            _showTextEditingPanel(index);
          }
        },
        child: Container(
          width: screenW,
          height: screenH,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.transparent,
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Content
              Center(
                child: Opacity(
                  opacity: overlay.opacity,
                  child: _buildOverlayContent(overlay, scale, screenW, screenH),
                ),
              ),
              
              if (isSelected) ...[
                // Resize Handle (Bottom Right)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final dw = details.delta.dx / scale;
                        final dh = details.delta.dy / scale;
                        
                        if (overlay is TextOverlay) {
                          _overlays[index] = (overlay as TextOverlay).copyWith(
                            width: (overlay.width + dw).clamp(50, _canvasSize.width),
                            height: (overlay.height + dh).clamp(20, _canvasSize.height),
                          );
                        } else if (overlay is ImageOverlay) {
                          _overlays[index] = (overlay as ImageOverlay).copyWith(
                            width: (overlay.width + dw).clamp(50, _canvasSize.width),
                            height: (overlay.height + dh).clamp(50, _canvasSize.height),
                          );
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                      child: const Icon(Icons.open_in_full, color: Colors.black, size: 12),
                    ),
                  ),
                ),
                
                // Delete button
                Positioned(
                  right: -10,
                  top: -10,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _overlays.removeAt(index);
                      _selectedOverlay = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _bottomTool(Icons.crop, 'Crop & Resize'),
          _bottomTool(Icons.tune, 'Filters'),
          _bottomTool(Icons.auto_fix_high, 'Enhance'),
          _bottomTool(Icons.layers_outlined, 'Overlays'),
          _bottomTool(Icons.brush, 'Draw'),
        ],
      ),
    );
  }

  Widget _buildFilterList() {
    final filters = FilterService.availableFilters.keys.toList();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: filters.map((filter) {
              bool isSelected = _selectedFilter == filter;
              return GestureDetector(
                onTap: () => _applyFilter(filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.gold : Colors.white10,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // Small preview could be added here if we had thumbnails
                              Container(color: AppColors.surface),
                              Center(
                                child: Text(
                                  filter[0], 
                                  style: AppFonts.playfair(size: 24, color: isSelected ? AppColors.gold : AppColors.muted)
                                ),
                              ),
                              if (_isProcessing && isSelected)
                                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(filter, style: AppFonts.poppins(size: 10, color: isSelected ? AppColors.gold : AppColors.muted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _bottomTool(IconData icon, String label) {
    return GestureDetector(
      onTap: () => _handleTool(label),
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: AppColors.gold, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppFonts.poppins(size: 11, color: AppColors.muted, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayContent(OverlayElement overlay, double scale, double screenW, double screenH) {
    if (overlay is TextOverlay) {
      return Text(
        overlay.text,
        textAlign: switch (overlay.alignment) {
          'left' => TextAlign.left,
          'right' => TextAlign.right,
          _ => TextAlign.center,
        },
        style: AppFonts.poppins(
          size: overlay.fontSize * scale,
          color: Color(int.parse(overlay.fontColor.replaceFirst('#', '0xFF'))),
          weight: overlay.bold ? FontWeight.bold : FontWeight.normal,
          style: overlay.italic ? FontStyle.italic : FontStyle.normal,
        ),
      );
    } else if (overlay is ImageOverlay) {
      return Image.file(
        overlay.imageFile,
        width: screenW,
        height: screenH,
        fit: BoxFit.contain,
      );
    } else if (overlay is DrawingOverlay) {
      return CustomPaint(
        size: Size(screenW, screenH),
        painter: DrawPainter(
          paths: overlay.paths,
          scale: scale,
          offsetX: 0,
          offsetY: 0,
        ),
      );
    }
    return const SizedBox();
  }
}

class DrawPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final double scale;
  final double offsetX;
  final double offsetY;

  DrawPainter({
    required this.paths,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      final paint = Paint()
        ..color = Color(int.parse('0xFF${path.color.replaceFirst('#', '')}'))
        ..strokeWidth = path.strokeWidth * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final uiPath = Path();
      if (path.points.isNotEmpty) {
        uiPath.moveTo(
          offsetX + path.points[0][0] * scale,
          offsetY + path.points[0][1] * scale,
        );
        for (int i = 1; i < path.points.length; i++) {
          uiPath.lineTo(
            offsetX + path.points[i][0] * scale,
            offsetY + path.points[i][1] * scale,
          );
        }
      }
      canvas.drawPath(uiPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) => true;
}
