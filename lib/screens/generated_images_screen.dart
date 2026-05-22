import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GeneratedImagesScreen extends StatefulWidget {
  final List<String> generatedImages;
  final String outfit;
  final String location;
  final String hairstyle;
  final String makeup;
  final String angle;
  final String mood;
  final String skin;
  final String height;
  final String bust;
  final String waist;
  final String hips;
  final String gender;
  final String aspectRatio;

  const GeneratedImagesScreen({
    super.key,
    required this.generatedImages,
    required this.outfit,
    required this.location,
    required this.hairstyle,
    required this.makeup,
    required this.angle,
    this.mood = '',
    this.skin = '',
    this.height = '',
    this.bust = '',
    this.waist = '',
    this.hips = '',
    this.gender = 'Female',
    this.aspectRatio = 'As in Photo',
  });

  @override
  State<GeneratedImagesScreen> createState() => _GeneratedImagesScreenState();
}

class _GeneratedImagesScreenState extends State<GeneratedImagesScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentImageToDatabase() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final imageData = widget.generatedImages[_currentIndex];
      if (imageData == 'error' || !imageData.startsWith('data:image')) {
        throw Exception('Invalid image data');
      }

      // Decode base64 to bytes
      final base64Str = imageData.split(',')[1];
      final Uint8List imageBytes = base64Decode(base64Str);

      // Upload to Firebase Storage
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/generatedImages/$fileName');

      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Build clean map — no nulls, no empty FieldValues in wrong places
      final Map<String, dynamic> docData = {
        'imageUrl': downloadUrl,
        'storagePath': storageRef.fullPath,
        'prompt': _buildPrompt(),
        'createdAt': FieldValue.serverTimestamp(),
        'gender': widget.gender,
        'outfit': widget.outfit,
        'location': widget.location,
        'hairstyle': widget.hairstyle,
        'makeup': widget.makeup,
        'angle': widget.angle,
        'mood': widget.mood,
        'skin': widget.skin,
        'height': widget.height,
        'bust': widget.bust,
        'waist': widget.waist,
        'hips': widget.hips,
        'aspectRatio': widget.aspectRatio,
      };

      // Remove any empty string values that could cause issues
      docData.removeWhere((key, value) =>
          key != 'createdAt' && value is String && value.isEmpty);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('generatedImages')
          .add(docData);

      if (mounted) {
        // Show success toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to your library!',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to home (pop both generated screen and generate screen)
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _buildPrompt() {
    return 'Outfit: ${ widget.outfit}, Location: ${widget.location}, Hairstyle: ${widget.hairstyle}, Makeup: ${widget.makeup}, Angle: ${widget.angle}, Mood: ${widget.mood}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: const AimrAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR GENERATED IMAGES',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perfect Lifestyle Shots',
                    style: AppFonts.playfair(
                      size: 32,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.generatedImages.length} image${widget.generatedImages.length > 1 ? 's' : ''} generated',
                    style: AppFonts.poppins(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Image Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: widget.generatedImages.length,
                itemBuilder: (context, index) {
                  final imageData = widget.generatedImages[index];
                  final isBase64Image = imageData.startsWith('data:image');
                  final isError = imageData == 'error';

                  if (isError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.withValues(alpha: 0.7),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generation Failed',
                            style: AppFonts.poppins(
                              size: 16,
                              color: Colors.red,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isBase64Image) {
                    try {
                      final base64String = imageData.split(',')[1];
                      final imageBytes = base64Decode(base64String);
                      final ratio = GeminiService.getDisplayRatio(widget.aspectRatio);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: ratio,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.red.withValues(alpha: 0.7),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Invalid Image',
                              style: AppFonts.poppins(
                                size: 16,
                                color: Colors.red,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          color: AppColors.gold.withValues(alpha: 0.5),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          imageData,
                          style: AppFonts.poppins(
                            size: 16,
                            color: AppColors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.generatedImages.length,
                  (index) => Container(
                    width: _currentIndex == index ? 32 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.gold
                          : AppColors.gold.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GENERATION DETAILS',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Outfit', widget.outfit),
                    const SizedBox(height: 8),
                    _buildDetailRow('Location', widget.location),
                    const SizedBox(height: 8),
                    _buildDetailRow('Hairstyle', widget.hairstyle),
                    const SizedBox(height: 8),
                    _buildDetailRow('Makeup', widget.makeup),
                    const SizedBox(height: 8),
                    _buildDetailRow('Camera Angle', widget.angle),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.gold,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'GENERATE MORE',
                            style: AppFonts.poppins(
                              size: 12,
                              weight: FontWeight.w900,
                              color: AppColors.gold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _saveCurrentImageToDatabase,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? AppColors.gold.withValues(alpha: 0.6)
                              : AppColors.gold,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.black, strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'SAVE IMAGE',
                                  style: AppFonts.poppins(
                                    size: 12,
                                    weight: FontWeight.w900,
                                    color: AppColors.black,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.poppins(
            size: 11,
            color: AppColors.muted,
            weight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppFonts.poppins(
              size: 11,
              color: AppColors.white,
              weight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
