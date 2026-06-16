import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../models/generated_content.dart';
import '../services/stock_image_service.dart';
import '../services/gemini_service.dart';
import 'image_edit_screen.dart';

class GenerateScreen extends StatefulWidget {
  final String? presetStyle;
  final StockImage? templateImage;
  const GenerateScreen({
    super.key,
    this.presetStyle,
    this.templateImage,
  });
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late String _mood;
  late String _location;
  late String _outfit;
  String _hairstyle = StudioOptions.hairstyles[0];
  String _makeup    = StudioOptions.makeupLooks[0];
  String _skin      = StudioOptions.skinStyles[0];
  String _height    = StudioOptions.heightOptions[0];
  String _bust      = StudioOptions.bustSizes[0];
  String _waist     = StudioOptions.waistSizes[0];
  String _hips      = StudioOptions.hipsSizes[0];
  String _angle     = StudioOptions.cameraAngles[0];
  String _ratio     = StudioOptions.aspectRatios[0];
  int    _batch     = 4;
  bool   _hasImage  = false;
  bool   _generating = false;
  File? _selectedImage;
  final  _enhCtrl   = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mood     = StudioOptions.moods[0];
    _location = StudioOptions.locations[0];
    _outfit   = StudioOptions.outfitStyles[0];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text('GENERATE',
                      style: AppFonts.poppins(
                        size: 10, weight: FontWeight.w700,
                        color: AppColors.gold, letterSpacing: 3,
                      )),
                  const SizedBox(height: 8),
                  Text('Your Twin',
                      style: AppFonts.playfair(
                        size: 32, weight: FontWeight.w900, color: AppColors.white,
                      )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 32),
                  if (widget.presetStyle != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(children: [
                        Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Using Template: ${widget.presetStyle}',
                            style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold))),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.gold.withValues(alpha: 0.6), size: 18),
                          onPressed: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const GenerateScreen())),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Display template image if provided
                  if (widget.templateImage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Template Image (Style Reference)',
                            style: AppFonts.poppins(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.templateImage!.imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: AppColors.inputBg,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.muted,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By: ${widget.templateImage!.photographer}',
                            style: AppFonts.poppins(
                              size: 10,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            'Source: ${widget.templateImage!.source}',
                            style: AppFonts.poppins(
                              size: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildPhase01(),
                  const SizedBox(height: 56),
                  _buildPhase02(),
                  const SizedBox(height: 56),
                  _buildPhase03(),
                  const SizedBox(height: 56),
                  _buildPhase04(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase01() => Column(children: [
    const PhaseHeader(phase: 'PHASE 01', title: 'Upload Your Photo'),
    const SizedBox(height: 16),
    GestureDetector(
      onTap: _hasImage ? () {
        // Show options to replace image
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: AppColors.gold),
                    title: Text('Take Photo', style: AppFonts.poppins(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: AppColors.gold),
                    title: Text('Choose from Gallery', style: AppFonts.poppins(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      } : () {
        // Show options to pick image
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: AppColors.gold),
                    title: Text('Take Photo', style: AppFonts.poppins(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: AppColors.gold),
                    title: Text('Choose from Gallery', style: AppFonts.poppins(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity, height: 300,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _hasImage ? AppColors.gold.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: _hasImage && _selectedImage != null
            ? Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(bottom: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Text('Change Image',
                        style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.white)),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.06),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.gold, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Upload Your Photo', style: AppFonts.playfair(size: 22, style: FontStyle.italic, color: AppColors.white)),
                const SizedBox(height: 6),
                Text('EDITORIAL REFERENCE',
                    style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
              ]),
      ),
    ),
  ]);

  Widget _buildPhase02() => Column(children: [
    const PhaseHeader(phase: 'PHASE 02', title: 'Customize Your Scene'),
    const SizedBox(height: 32),
    AimrDropdown(label: 'The Vibe', value: _mood, options: StudioOptions.moods,
        icon: Icons.wb_sunny_outlined, onChanged: (v) => setState(() => _mood = v)),
    const SizedBox(height: 20),
    AimrDropdown(label: 'The Scene', value: _location, options: StudioOptions.locations,
        icon: Icons.location_on_outlined, onChanged: (v) => setState(() => _location = v)),
    const SizedBox(height: 20),
    AimrDropdown(label: 'The Outfit', value: _outfit, options: StudioOptions.outfitStyles,
        icon: Icons.checkroom_outlined, onChanged: (v) => setState(() => _outfit = v)),
  ]);

  Widget _buildPhase03() => Column(children: [
    const PhaseHeader(phase: 'PHASE 03', title: 'Refine Your Twin'),
    const SizedBox(height: 32),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Hair Style', value: _hairstyle,
          options: StudioOptions.hairstyles, icon: Icons.face_retouching_natural,
          onChanged: (v) => setState(() => _hairstyle = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Makeup', value: _makeup,
          options: StudioOptions.makeupLooks, icon: Icons.brush_outlined,
          onChanged: (v) => setState(() => _makeup = v))),
    ]),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Skin Style', value: _skin,
          options: StudioOptions.skinStyles, icon: Icons.spa_outlined,
          onChanged: (v) => setState(() => _skin = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Height', value: _height,
          options: StudioOptions.heightOptions, icon: Icons.height,
          onChanged: (v) => setState(() => _height = v))),
    ]),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Bust', value: _bust,
          options: StudioOptions.bustSizes, icon: Icons.straighten,
          onChanged: (v) => setState(() => _bust = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Waist', value: _waist,
          options: StudioOptions.waistSizes, icon: Icons.straighten,
          onChanged: (v) => setState(() => _waist = v))),
    ]),
    const SizedBox(height: 20),
    AimrDropdown(label: 'Hips Sculpt', value: _hips,
        options: StudioOptions.hipsSizes, icon: Icons.straighten,
        onChanged: (v) => setState(() => _hips = v)),
  ]);

  Widget _buildPhase04() => Column(children: [
    const PhaseHeader(phase: 'PHASE 04', title: 'Final Touches'),
    const SizedBox(height: 32),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Camera Angle', value: _angle,
          options: StudioOptions.cameraAngles, icon: Icons.camera_alt_outlined,
          onChanged: (v) => setState(() => _angle = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Aspect Ratio', value: _ratio,
          options: StudioOptions.aspectRatios, icon: Icons.crop_outlined,
          onChanged: (v) => setState(() => _ratio = v))),
    ]),
    const SizedBox(height: 24),
    // Custom enhancer
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('OPTIONAL: MAKE IT CUSTOM',
          style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
      const SizedBox(height: 12),
      TextField(
        controller: _enhCtrl,
        maxLines: 4,
        style: AppFonts.poppins(size: 14, color: AppColors.text, height: 1.6),
        cursorColor: AppColors.gold,
        decoration: InputDecoration(
          hintText: '"Golden hour glow", "holding a vintage camera"...',
          hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.3), height: 1.6),
          filled: true,
          fillColor: AppColors.inputBg,
          contentPadding: const EdgeInsets.all(20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.08), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
          ),
        ),
      ),
    ]),
    const SizedBox(height: 40),
    if (widget.templateImage != null) ...[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.gold,
                size: 16,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PREMIUM STYLE EXTRACTION',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Using a template requires deep AI analysis for precise style matching, which may take an extra moment.',
                    style: AppFonts.poppins(
                      size: 11,
                      color: AppColors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ],
    GoldButton(
      label: _generating ? 'MANIFESTING...' : 'RENDER TWIN',
      loading: _generating,
      onTap: () async {
        if (!_hasImage || _selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('Please upload a source photo first.',
                style: AppFonts.poppins(size: 12, color: AppColors.text)),
          ));
          return;
        }

        setState(() => _generating = true);
        
        try {
          final geminiService = GeminiService();
          List<String> generatedImages;

          if (widget.templateImage != null) {
            // Path 1: Template-Based Generation (Dual Reference)
            generatedImages = await geminiService.generateImageWithTemplateAndReference(
              templateImageUrl: widget.templateImage!.imageUrl,
              userImageFile: _selectedImage!,
              mood: _mood,
              location: _location,
              outfit: _outfit,
              hairstyle: _hairstyle,
              makeup: _makeup,
              skin: _skin,
              height: _height,
              bust: _bust,
              waist: _waist,
              hips: _hips,
              angle: _angle,
              ratio: _ratio,
              batch: _batch,
              customDescription: _enhCtrl.text,
            );
          } else {
            // Path 2: Standard Reference-Based Generation (Single Reference)
            generatedImages = await geminiService.generateImagesWithReference(
              referenceImage: _selectedImage!,
              mood: _mood,
              location: _location,
              outfit: _outfit,
              hairstyle: _hairstyle,
              makeup: _makeup,
              skin: _skin,
              height: _height,
              bust: _bust,
              waist: _waist,
              hips: _hips,
              angle: _angle,
              aspectRatio: _ratio,
              numberOfImages: _batch,
            );
          }

          // Find the first successful image
          final firstValidImage = generatedImages.firstWhere(
            (img) => img != 'error' && img.isNotEmpty,
            orElse: () => '',
          );

          if (firstValidImage.isEmpty) {
            throw Exception('All generation attempts failed. Please try again.');
          }
          
          // Create generated content
          final generatedContent = GeneratedContent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            originalImageUrl: firstValidImage,
            prompt: _enhCtrl.text.isNotEmpty ? _enhCtrl.text : '$_mood, $_location, $_outfit',
            createdAt: DateTime.now(),
            contentType: 'original',
            metadata: {
              'mood': _mood,
              'location': _location,
              'outfit': _outfit,
              'hairstyle': _hairstyle,
              'makeup': _makeup,
              'skin': _skin,
              'height': _height,
              'bust': _bust,
              'waist': _waist,
              'hips': _hips,
              'angle': _angle,
              'ratio': _ratio,
              'batch': _batch,
              'all_images': generatedImages.where((img) => img != 'error' && img.isNotEmpty).toList(),
            },
          );
          
          if (mounted) {
            setState(() => _generating = false);
            
            // Navigate to edit screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageEditScreen(content: generatedContent),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ GENERATION ERROR: $e');
          if (mounted) {
            setState(() => _generating = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppColors.surface,
              content: Text('Generation failed: $e',
                  style: AppFonts.poppins(size: 12, color: AppColors.text)),
            ));
          }
        }
      },
    ),
  ]);
}
