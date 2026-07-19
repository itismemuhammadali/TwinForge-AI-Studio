import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import 'magazine_review_screen.dart';

class MagazineDetailScreen extends StatefulWidget {
  final String templateImageUrl;
  final String? imagePrompt;
  final String? overlayPrompt;

  const MagazineDetailScreen({
    super.key,
    required this.templateImageUrl,
    this.imagePrompt,
    this.overlayPrompt,
  });

  @override
  State<MagazineDetailScreen> createState() => _MagazineDetailScreenState();
}

class _MagazineDetailScreenState extends State<MagazineDetailScreen> {
  File? _selectedImage;
  final _imagePromptController = TextEditingController();
  final _overlayPromptController = TextEditingController();
  bool _isGenerating = false;
  final _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    if (widget.imagePrompt != null) {
      _imagePromptController.text = widget.imagePrompt!;
    }
    if (widget.overlayPrompt != null) {
      _overlayPromptController.text = widget.overlayPrompt!;
    }
  }

  @override
  void dispose() {
    _imagePromptController.dispose();
    _overlayPromptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Image Source',
                style: AppFonts.poppins(size: 16, weight: FontWeight.w600, color: AppColors.white),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.gold),
                title: Text('Take Photo', style: AppFonts.poppins(color: AppColors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.gold),
                title: Text('Select from Gallery', style: AppFonts.poppins(color: AppColors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  Future<void> _generateMagazine() async {
    if (_selectedImage == null) return;

    setState(() => _isGenerating = true);

    try {
      // Download template image from network
      final response = await http.get(Uri.parse(widget.templateImageUrl));
      final tempDir = Directory.systemTemp;
      final templateFile = File('${tempDir.path}/template_temp.jpg');
      await templateFile.writeAsBytes(response.bodyBytes);

      final base64Result = await _geminiService.generateMagazineCover(
        templateImage: templateFile,
        userPhoto: _selectedImage!,
        imagePrompt: _imagePromptController.text,
        overlayPrompt: _overlayPromptController.text,
      );

      // Save base64 data to a file
      final imageFile = File('${tempDir.path}/magazine_result_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Remove the data URL prefix if present
      String cleanBase64 = base64Result;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      
      final imageBytes = base64Decode(cleanBase64);
      await imageFile.writeAsBytes(imageBytes);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MagazineReviewScreen(
              generatedImage: imageFile.path,
              isNetworkImage: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: AppFonts.poppins(size: 13)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MAGAZINE TEMPLATE',
          style: AppFonts.poppins(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Image
            Text(
              'TEMPLATE',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.1),
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.templateImageUrl,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) return child;
                    return Container(color: AppColors.surface);
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image, color: AppColors.muted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Photo Selection Card
            Text(
              'YOUR PHOTO',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage != null
                        ? AppColors.gold.withValues(alpha: 0.4)
                        : AppColors.white.withValues(alpha: 0.1),
                    width: _selectedImage != null ? 1.5 : 0.8,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedImage!, fit: BoxFit.cover),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.gold.withValues(alpha: 0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to take photo or select from gallery',
                            style: AppFonts.poppins(size: 12, color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Prompt
            Text(
              'IMAGE PROMPT',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            _buildPromptField(
              controller: _imagePromptController,
              hintText: 'Describe the image style, mood, and composition...',
            ),
            const SizedBox(height: 20),

            // Overlay Prompt
            Text(
              'TEXT OVERLAYS & POSITIONING',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Describe text overlays, their position, font size, and styling',
              style: AppFonts.poppins(
                size: 11,
                color: AppColors.muted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            _buildPromptField(
              controller: _overlayPromptController,
              hintText: 'E.g. Title "SUCCESS" at top center, large bold white font...\nSubtitle at bottom, small gold font...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Generate Button
            GestureDetector(
              onTap: _selectedImage == null || _isGenerating
                  ? null
                  : _generateMagazine,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: _selectedImage == null || _isGenerating
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : AppColors.gold,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _selectedImage != null && !_isGenerating
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: _isGenerating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'GENERATE MAGAZINE',
                        style: AppFonts.poppins(
                          size: 12,
                          weight: FontWeight.w900,
                          color: AppColors.black,
                          letterSpacing: 5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 3,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: AppColors.text,
      ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.05),
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
    );
  }
}
