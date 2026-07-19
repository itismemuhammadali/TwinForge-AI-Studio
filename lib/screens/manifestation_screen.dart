import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../services/gemini_service.dart';
import '../models/generated_content.dart';
import 'manifestation_review_screen.dart';

class ManifestationScreen extends StatefulWidget {
  const ManifestationScreen({super.key});
  @override
  State<ManifestationScreen> createState() => _ManifestationScreenState();
}

class _ManifestationScreenState extends State<ManifestationScreen> {
  File? _selectedImage;
  final _visionCtrl = TextEditingController();
  String _mood = StudioOptions.moods[0];
  bool _isGenerating = false;

  static const _visionSuggestions = [
    'Driving a Rolls-Royce',
    'Walking into Burj Khalifa',
    'Standing in front of a luxury mansion',
    'Stepping out of a private jet',
    'On a yacht in Monaco',
    'At a Forbes cover shoot',
    'Shopping on Rodeo Drive',
    'At a red carpet event',
    'In a penthouse overlooking NYC',
    'At a luxury spa in Bali',
  ];

  @override
  void dispose() {
    _visionCtrl.dispose();
    super.dispose();
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourceBottomSheet(
        onSourceSelected: (source) async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: source, imageQuality: 90);
          if (picked != null) {
            setState(() => _selectedImage = File(picked.path));
          }
        },
        title: 'UPLOAD YOUR PHOTO',
        subtitle: 'Choose a clear front-facing photo',
      ),
    );
  }

  Future<void> _generate() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload an image first', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }
    if (_visionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please describe your vision', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final gemini = GeminiService();
      final results = await gemini.generateImagesWithReference(
        referenceImage: _selectedImage!,
        outfit: 'As in photo',
        location: 'As in photo',
        hairstyle: 'As in photo',
        makeup: 'As in photo',
        angle: 'Standard Eye Level',
        skin: 'Natural & Realistic (with pores)',
        mood: _mood,
        height: 'As in photo',
        bust: 'As in photo',
        waist: 'As in photo',
        hips: 'As in photo',
        aspectRatio: '9:16 (Portrait)',
        numberOfImages: 1,
        customPrompt: 'Create a high-quality, realistic photo of this person ${_visionCtrl.text.trim()}. '
            'The person should be clearly visible with their face naturally integrated into the scene. '
            'Make it look like a professional, cinematic photograph. '
            'Style: ${_mood.toLowerCase()}, luxurious, aspirational, magazine-quality.',
      );

      if (mounted) {
        final validImages = results.where((img) => img != 'error').toList();
        if (validImages.isNotEmpty) {
          final content = GeneratedContent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            originalImageUrl: validImages.first,
            editedImageUrl: validImages.first,
            prompt: _visionCtrl.text.trim(),
            createdAt: DateTime.now(),
            contentType: 'manifestation',
            metadata: {'mood': _mood, 'vision': _visionCtrl.text.trim()},
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManifestationReviewScreen(content: content),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generation failed. Please try again.', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('MANIFESTATION AI', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: const Color(0xFF7B68EE), letterSpacing: 3)),
            const SizedBox(height: 8),
            Text('Visualize Your Dreams', style: AppFonts.playfair(size: 32, weight: FontWeight.w900, color: AppColors.white)),
            const SizedBox(height: 6),
            Text('Upload your photo and describe your vision — AI will create it for you',
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 32),

            // Step 1 — Upload
            _stepLabel('01', 'Upload Your Photo'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedImage != null ? const Color(0xFF7B68EE).withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.face_outlined, color: const Color(0xFF7B68EE), size: 40),
                        const SizedBox(height: 12),
                        Text('Upload Your Photo', style: AppFonts.playfair(size: 18, style: FontStyle.italic, color: AppColors.white)),
                        const SizedBox(height: 6),
                        Text('CLEAR FRONT-FACING PHOTO', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: const Color(0xFF7B68EE), letterSpacing: 2)),
                      ]),
              ),
            ),
            const SizedBox(height: 32),

            // Step 2 — Vision
            _stepLabel('02', 'Describe Your Vision'),
            const SizedBox(height: 12),
            TextField(
              controller: _visionCtrl,
              maxLines: 3,
              style: AppFonts.poppins(size: 13, color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Driving a Rolls-Royce in front of a luxury mansion...',
                hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF7B68EE).withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF7B68EE).withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B68EE), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Vision suggestions
            Text('QUICK IDEAS', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _visionSuggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () => setState(() => _visionCtrl.text = suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 0.5),
                    ),
                    child: Text(suggestion, style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Step 3 — Mood
            _stepLabel('03', 'Choose Your Mood'),
            const SizedBox(height: 12),
            AimrDropdown(
              label: 'Style & Mood',
              value: _mood,
              options: StudioOptions.moods,
              icon: Icons.palette_outlined,
              onChanged: (v) => setState(() => _mood = v),
            ),
            const SizedBox(height: 32),

            GoldButton(
              label: _isGenerating ? 'GENERATING...' : 'GENERATE IMAGE',
              loading: _isGenerating,
              onTap: _isGenerating ? null : _generate,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(String num, String label) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF7B68EE).withValues(alpha: 0.15),
        border: Border.all(color: const Color(0xFF7B68EE).withValues(alpha: 0.4), width: 0.8),
      ),
      child: Center(child: Text(num, style: AppFonts.poppins(size: 10, weight: FontWeight.w900, color: const Color(0xFF7B68EE)))),
    ),
    const SizedBox(width: 12),
    Text(label, style: AppFonts.playfair(size: 18, weight: FontWeight.w700, color: AppColors.text)),
  ]);
}
