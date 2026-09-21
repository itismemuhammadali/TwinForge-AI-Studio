import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../services/stock_image_service.dart';
import '../services/gemini_service.dart';
import '../services/open_ai_service.dart';

import '../utils/permission_helper.dart';
import '../services/credit_service.dart';
import '../models/credit_config.dart';
import 'generated_images_screen.dart';
import '../utils/ai_consent_helper.dart';

class GenerateScreen extends StatefulWidget {
  final String? presetStyle;
  final StockImage? templateImage;
  final String? prefilledPrompt;
  final File? avatarImageFile;
  final bool fromBroll;
  final bool fromTalkingHead;
  final bool fromCarousel;
  final bool fromHoliday;
  final bool fromManifestation;
  const GenerateScreen({
    super.key,
    this.presetStyle,
    this.templateImage,
    this.prefilledPrompt,
    this.avatarImageFile,
    this.fromBroll = false,
    this.fromTalkingHead = false,
    this.fromCarousel = false,
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
  String _makeup = StudioOptions.makeupLooks[0];
  String _skin = StudioOptions.skinStyles[0];
  String _height = StudioOptions.heightOptions[0];
  String _bust = StudioOptions.bustSizes[0];
  String _waist = StudioOptions.waistSizes[0];
  String _hips = StudioOptions.hipsSizes[0];
  String _angle = StudioOptions.cameraAngles[0];
  String _ratio = StudioOptions.aspectRatios[0];
  int _batch = 4;
  bool _hasImage = false;
  bool _generating = false;
  bool _processingTemplate = false;
  String? _promptError;
  File? _selectedImage;
  final _promptCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mood = StudioOptions.moods[0];
    _location = StudioOptions.locations[0];
    _outfit = StudioOptions.outfitStyles[0];

    if (widget.avatarImageFile != null) {
      _selectedImage = widget.avatarImageFile;
      _hasImage = true;
    }

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
      String prompt = '';
      if (widget.fromCarousel) {
        // Analyze template using OpenAI GPT-4o Vision
        prompt = await OpenAiService().analyzeCarouselTemplate(
          templateImageUrl: widget.templateImage!.imageUrl,
        );
      } else {
        // Download and analyze for pose via GeminiService
        final response = await http.get(
          Uri.parse(widget.templateImage!.imageUrl),
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to download template image');
        }
        final templateBase64 = base64Encode(response.bodyBytes);
        final geminiService = GeminiService();
        prompt = await geminiService.analyzeTemplateForPose(templateBase64);
      }

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
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
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
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
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
                  child: Icon(Icons.error_outline, color: Colors.red, size: 16),
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
                          _processingTemplate
                              ? 'Retrying...'
                              : 'Retry Analysis',
                          style: AppFonts.poppins(
                            size: 11,
                            weight: FontWeight.w700,
                            color: _processingTemplate
                                ? AppColors.muted
                                : Colors.red,
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
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1,
        ),
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
            style: AppFonts.poppins(size: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptCtrl,
            maxLines: 10,
            minLines: 8,
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.text,
              height: 1.6,
            ),
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
    final granted = await PermissionHelper.checkImagePermission(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        PermissionHelper.handlePermissionError(context, e, ImageSource.gallery);
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    final granted = await PermissionHelper.checkImagePermission(
      context,
      ImageSource.camera,
    );
    if (!granted) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1440,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        PermissionHelper.handlePermissionError(context, e, ImageSource.camera);
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
              Text(
                'GENERATE',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Twin',
                style: AppFonts.playfair(
                  size: 32,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              if (widget.presetStyle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Using Template: ${widget.presetStyle}',
                          style: AppFonts.poppins(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.gold.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GenerateScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 1,
                    ),
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
                  if (_isMagazine) ...[_buildMagazineNoticeBox()],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase01() => Column(
    children: [
      const PhaseHeader(phase: 'PHASE 01', title: 'Upload Your Photo'),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _hasImage
            ? () {
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
                            leading: Icon(
                              Icons.camera_alt,
                              color: AppColors.gold,
                            ),
                            title: Text(
                              'Take Photo',
                              style: AppFonts.poppins(color: AppColors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageFromCamera();
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.photo_library,
                              color: AppColors.gold,
                            ),
                            title: Text(
                              'Choose from Gallery',
                              style: AppFonts.poppins(color: AppColors.white),
                            ),
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
              }
            : () {
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
                            leading: Icon(
                              Icons.camera_alt,
                              color: AppColors.gold,
                            ),
                            title: Text(
                              'Take Photo',
                              style: AppFonts.poppins(color: AppColors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageFromCamera();
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.photo_library,
                              color: AppColors.gold,
                            ),
                            title: Text(
                              'Choose from Gallery',
                              style: AppFonts.poppins(color: AppColors.white),
                            ),
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
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _hasImage
                  ? AppColors.gold.withValues(alpha: 0.4)
                  : AppColors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: _hasImage && _selectedImage != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.file(_selectedImage!, fit: BoxFit.contain),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Change Image',
                          style: AppFonts.poppins(
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: 0.06),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.gold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload Your Photo',
                        style: AppFonts.playfair(
                          size: 22,
                          style: FontStyle.italic,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'EDITORIAL REFERENCE',
                        style: AppFonts.poppins(
                          size: 9,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ],
  );

  Widget _buildPhase02() => Column(
    children: [
      const PhaseHeader(phase: 'PHASE 02', title: 'Customize Your Scene'),
      const SizedBox(height: 32),
      AimrDropdown(
        label: 'The Vibe',
        value: _mood,
        options: StudioOptions.moods,
        icon: Icons.wb_sunny_outlined,
        onChanged: (v) => setState(() => _mood = v),
      ),
      const SizedBox(height: 20),
      AimrDropdown(
        label: 'The Scene',
        value: _location,
        options: StudioOptions.locations,
        icon: Icons.location_on_outlined,
        onChanged: (v) => setState(() => _location = v),
      ),
      const SizedBox(height: 20),
      AimrDropdown(
        label: 'The Outfit',
        value: _outfit,
        options: StudioOptions.outfitStyles,
        icon: Icons.checkroom_outlined,
        onChanged: (v) => setState(() => _outfit = v),
      ),
    ],
  );

  Widget _buildPhase03() => Column(
    children: [
      const PhaseHeader(phase: 'PHASE 03', title: 'Refine Your Twin'),
      const SizedBox(height: 32),
      Row(
        children: [
          Expanded(
            child: AimrDropdown(
              label: 'Hair Style',
              value: _hairstyle,
              options: StudioOptions.hairstyles,
              icon: Icons.face_retouching_natural,
              onChanged: (v) => setState(() => _hairstyle = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AimrDropdown(
              label: 'Makeup',
              value: _makeup,
              options: StudioOptions.makeupLooks,
              icon: Icons.brush_outlined,
              onChanged: (v) => setState(() => _makeup = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: AimrDropdown(
              label: 'Skin Style',
              value: _skin,
              options: StudioOptions.skinStyles,
              icon: Icons.spa_outlined,
              onChanged: (v) => setState(() => _skin = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AimrDropdown(
              label: 'Height',
              value: _height,
              options: StudioOptions.heightOptions,
              icon: Icons.height,
              onChanged: (v) => setState(() => _height = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: AimrDropdown(
              label: 'Bust',
              value: _bust,
              options: StudioOptions.bustSizes,
              icon: Icons.straighten,
              onChanged: (v) => setState(() => _bust = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AimrDropdown(
              label: 'Waist',
              value: _waist,
              options: StudioOptions.waistSizes,
              icon: Icons.straighten,
              onChanged: (v) => setState(() => _waist = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      AimrDropdown(
        label: 'Hips Sculpt',
        value: _hips,
        options: StudioOptions.hipsSizes,
        icon: Icons.straighten,
        onChanged: (v) => setState(() => _hips = v),
      ),
    ],
  );

  bool get _isMagazine {
    if (widget.presetStyle != null &&
        widget.presetStyle!.toLowerCase().contains('magazine')) {
      return true;
    }
    if (widget.templateImage != null) {
      final title = widget.templateImage!.title.toLowerCase();
      final source = widget.templateImage!.source.toLowerCase();
      if (title.contains('magazine') ||
          title.contains('cover') ||
          source.contains('magazine')) {
        return true;
      }
    }
    return false;
  }

  Widget _buildMagazineNoticeBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF261C0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'IMPORTANT NOTICE',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Copy this prompt and paste it in ChatGPT to fill in the details about yourself before generating!',
            style: AppFonts.poppins(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _promptCtrl.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.gold,
                  duration: const Duration(seconds: 3),
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.black,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prompt copied! Paste in ChatGPT to customize your details.',
                          style: AppFonts.poppins(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.copy_rounded,
                    color: AppColors.black,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COPY PROMPT FOR CHATGPT',
                    style: AppFonts.poppins(
                      size: 11,
                      weight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase04() => Column(
    children: [
      const PhaseHeader(phase: 'PHASE 04', title: 'Final Touches'),
      const SizedBox(height: 32),
      Row(
        children: [
          Expanded(
            child: AimrDropdown(
              label: 'Camera Angle',
              value: _angle,
              options: StudioOptions.cameraAngles,
              icon: Icons.camera_alt_outlined,
              onChanged: (v) => setState(() => _angle = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AimrDropdown(
              label: 'Aspect Ratio',
              value: _ratio,
              options: StudioOptions.aspectRatios,
              icon: Icons.crop_outlined,
              onChanged: (v) => setState(() => _ratio = v),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      // Number of Images Batch Selector
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NUMBER OF IMAGES',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _batch > 1 ? () => setState(() => _batch--) : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _batch > 1
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : AppColors.gold.withValues(alpha: 0.05),
                      border: Border.all(
                        color: _batch > 1
                            ? AppColors.gold.withValues(alpha: 0.4)
                            : AppColors.gold.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: _batch > 1
                          ? AppColors.gold
                          : AppColors.gold.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _batch.toString(),
                    style: AppFonts.playfair(
                      size: 28,
                      weight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _batch < 4 ? () => setState(() => _batch++) : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _batch < 4
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : AppColors.gold.withValues(alpha: 0.05),
                      border: Border.all(
                        color: _batch < 4
                            ? AppColors.gold.withValues(alpha: 0.4)
                            : AppColors.gold.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: _batch < 4
                          ? AppColors.gold
                          : AppColors.gold.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 32),
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
      if (_isMagazine) ...[
        _buildMagazineNoticeBox(),
        const SizedBox(height: 20),
      ],
      GoldButton(
        label: _generating ? 'MANIFESTING...' : 'RENDER TWIN',
        loading: _generating,
        onTap: () async {
          // Check if template is still processing
          if (_processingTemplate) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surface,
                content: Text(
                  'Please wait while we analyze your template...',
                  style: AppFonts.poppins(size: 12, color: AppColors.text),
                ),
              ),
            );
            return;
          }

          if (!_hasImage || _selectedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surface,
                content: Text(
                  'Please upload a source photo first.',
                  style: AppFonts.poppins(size: 12, color: AppColors.text),
                ),
              ),
            );
            return;
          }

          // Pre-generation Gatekeeper: Apple Guidelines 5.1.1(i) & 5.1.2(i)
          final hasConsent = await AiConsentHelper.ensureConsent(context);
          if (!hasConsent || !mounted) return;

          final totalRequiredCredits = _batch * CreditConfig.geminiImageCredits;
          final hasCredits = await CreditService.ensureSufficientCredits(
            context,
            requiredCredits: totalRequiredCredits,
            featureName: 'Image Generation',
          );
          if (!hasCredits) return;

          setState(() => _generating = true);

          try {
            List<String> generatedImages;

            if (widget.fromCarousel && _selectedImage != null) {
              // CAROUSEL FLOW: Dynamic Reference Image Generation (uses AI-synthesized Vision prompt from _promptCtrl.text)
              final geminiService = GeminiService();
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
                aspectRatio: '9:16',
                numberOfImages: 1,
                customPrompt: _promptCtrl.text,
              );
            } else if (widget.templateImage != null &&
                (widget.prefilledPrompt == null ||
                    widget.prefilledPrompt!.isEmpty)) {
              final geminiService = GeminiService();
              // Path 1: Template-Based Generation (Dual Reference) when no prefilled prompt exists
              generatedImages = await geminiService
                  .generateImageWithTemplateAndReference(
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
              final geminiService = GeminiService();
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
                customPrompt: _promptCtrl.text.isNotEmpty
                    ? _promptCtrl.text
                    : null,
              );
            }

            // Find the first successful image
            final firstValidImage = generatedImages.firstWhere(
              (img) => img != 'error' && img.isNotEmpty,
              orElse: () => '',
            );

            if (firstValidImage.isEmpty) {
              throw Exception(
                'All generation attempts failed. Please try again.',
              );
            }

            final successCount = generatedImages
                .where((img) => img != 'error' && img.isNotEmpty)
                .length;
            if (successCount > 0 && mounted) {
              final creditsDeducted =
                  successCount * CreditConfig.geminiImageCredits;
              await CreditService.deductCredits(
                context: context,
                creditsToDeduct: creditsDeducted,
                feature: 'gemini_image',
                estimatedUsdCost:
                    CreditConfig.estimateGeminiCostUsd(
                      'Gemini 3.1 Flash',
                      _ratio,
                    ) *
                    successCount,
                provider: 'Gemini',
              );
            }

            if (mounted) {
              setState(() => _generating = false);

              // Navigate to GeneratedImagesScreen (allows swiping left/right through all batch images & saving batch to library + gallery)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeneratedImagesScreen(
                    generatedImages: generatedImages,
                    outfit: _outfit,
                    location: _location,
                    hairstyle: _hairstyle,
                    makeup: _makeup,
                    angle: _angle,
                    mood: _mood,
                    skin: _skin,
                    height: _height,
                    bust: _bust,
                    waist: _waist,
                    hips: _hips,
                    aspectRatio: _ratio,
                    fromTalkingHead: widget.fromTalkingHead,
                    fromBroll: widget.fromBroll,
                    fromCarousel: widget.fromCarousel,
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
                errorMessage =
                    'Generation took too long. Please try with a smaller batch size or simpler prompt.';
              } else if (e.toString().contains('API')) {
                errorMessage =
                    'API error occurred. Please check your connection and try again.';
              } else if (e.toString().contains('image')) {
                errorMessage =
                    'Image processing failed. Please try with a different image.';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surface,
                  duration: const Duration(seconds: 5),
                  content: Text(
                    errorMessage,
                    style: AppFonts.poppins(size: 12, color: AppColors.text),
                  ),
                ),
              );
            }
          }
        },
      ),
    ],
  );
}
