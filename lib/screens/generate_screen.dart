import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  final String? prefilledPrompt;
  final bool fromBroll;
  final bool fromTalkingHead;
  final bool fromHoliday;
  final bool fromManifestation;
  const GenerateScreen({
    super.key,
    this.presetStyle,
    this.templateImage,
    this.prefilledPrompt,
    this.fromBroll = false,
    this.fromTalkingHead = false,
    this.fromHoliday = false,
    this.fromManifestation = false,
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
  bool   _processingTemplate = false;
  String? _promptError;
  File? _selectedImage;
  final  _promptCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mood     = StudioOptions.moods[0];
    _location = StudioOptions.locations[0];
    _outfit   = StudioOptions.outfitStyles[0];
    
    // If a prefilled prompt is provided (e.g. from admin podcast), use it directly
    if (widget.prefilledPrompt != null && widget.prefilledPrompt!.isNotEmpty) {
      _promptCtrl.text = widget.prefilledPrompt!;
      _batch = 1;
    } else if (widget.templateImage != null) {
      _processTemplateImage();
    }
  }

  Future<void> _processTemplateImage() async {
    if (widget.templateImage == null) return;
    
    setState(() {
      _processingTemplate = true;
      _promptError = null;
    });

    try {
      // Download and convert template image to base64
      final response = await http.get(Uri.parse(widget.templateImage!.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download template image');
      }
      final templateBase64 = base64Encode(response.bodyBytes);
      
      // Use the existing GeminiService method to analyze template
      final geminiService = GeminiService();
      final prompt = await geminiService.analyzeTemplateForPose(templateBase64);
      
      if (mounted) {
        setState(() {
          _promptCtrl.text = prompt;
          _processingTemplate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _promptError = 'Failed to analyze template: $e';
          _processingTemplate = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Widget _buildPromptBox() {
    if (_processingTemplate) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analyzing template style...',
                    style: AppFonts.poppins(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI is extracting the style, composition, and aesthetic from your template.',
              style: AppFonts.poppins(
                size: 11,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_promptError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Template Analysis Failed',
                    style: AppFonts.poppins(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _promptError!,
              style: AppFonts.poppins(
                size: 11,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _processingTemplate ? null : _processTemplateImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _processingTemplate 
                          ? AppColors.muted.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _processingTemplate 
                            ? AppColors.muted.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _processingTemplate ? 'Retrying...' : 'Retry Analysis',
                          style: AppFonts.poppins(
                            size: 11,
                            weight: FontWeight.w700,
                            color: _processingTemplate ? AppColors.muted : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _promptError = null;
                        _promptCtrl.text = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Skip & Continue',
                          style: AppFonts.poppins(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI-Generated Style Prompt',
                  style: AppFonts.poppins(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Feel free to edit the prompt to fine-tune the style for your image:',
            style: AppFonts.poppins(
              size: 10,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptCtrl,
            maxLines: 10,
            minLines: 8,
            style: AppFonts.poppins(size: 12, color: AppColors.text, height: 1.6),
            cursorColor: AppColors.gold,
            decoration: InputDecoration(
              hintText: 'Enter or edit the style prompt...',
              hintStyle: AppFonts.poppins(
                size: 11,
                color: AppColors.muted.withValues(alpha: 0.5),
                height: 1.6,
              ),
              filled: true,
              fillColor: AppColors.inputBg,
              contentPadding: const EdgeInsets.all(18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 8),
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
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: Image.network(
                                widget.templateImage!.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.contain,
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
                    // Generated Prompt Box (only show if template was provided)
                    if (widget.templateImage != null) ...[
                      _buildPromptBox(),
                      if (widget.templateImage!.title.toLowerCase().contains('magazine')) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Copy this prompt and paste it in ChatGPT to fill in the details about yourself.',
                                  style: AppFonts.poppins(size: 11, color: AppColors.gold, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
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
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200, maxHeight: 350),
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
                    fit: BoxFit.contain,
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
        // Check if template is still processing
        if (_processingTemplate) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('Please wait while we analyze your template...',
                style: AppFonts.poppins(size: 12, color: AppColors.text)),
          ));
          return;
        }

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

          if (widget.templateImage != null && widget.prefilledPrompt == null) {
            // Path 1: Template-Based Generation (Dual Reference) — analyze template via Gemini
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
              customDescription: _promptCtrl.text,
            );
          } else {
            // Path 2: Reference-Based Generation — use prompt from text box (no Gemini analysis)
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
              customPrompt: _promptCtrl.text.isNotEmpty ? _promptCtrl.text : null,
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
            prompt: widget.templateImage != null 
              ? _promptCtrl.text
              : '$_mood, $_location, $_outfit',
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
            
            // Navigate to appropriate screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageEditScreen(
                  content: generatedContent,
                  fromTalkingHead: widget.fromTalkingHead,
                  fromBroll: widget.fromBroll,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ GENERATION ERROR: $e');
          if (mounted) {
            setState(() => _generating = false);
            
            // Provide user-friendly error message
            String errorMessage = 'Generation failed. Please try again.';
            if (e.toString().contains('timeout')) {
              errorMessage = 'Generation took too long. Please try with a smaller batch size or simpler prompt.';
            } else if (e.toString().contains('API')) {
              errorMessage = 'API error occurred. Please check your connection and try again.';
            } else if (e.toString().contains('image')) {
              errorMessage = 'Image processing failed. Please try with a different image.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 5),
              content: Text(errorMessage,
                  style: AppFonts.poppins(size: 12, color: AppColors.text)),
            ));
          }
        }
      },
    ),
  ]);
}
