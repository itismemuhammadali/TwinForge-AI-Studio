import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/generated_content.dart';
import '../utils/permission_helper.dart';
import 'talking_head_creation_screen.dart';
import 'ai_video_story_creation_screen.dart';
import 'trending_screen.dart';

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
  final bool fromTalkingHead;
  final bool fromBroll;
  final bool fromCarousel;

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
    this.fromTalkingHead = false,
    this.fromBroll = false,
    this.fromCarousel = false,
  });

  @override
  State<GeneratedImagesScreen> createState() => _GeneratedImagesScreenState();
}

class _GeneratedImagesScreenState extends State<GeneratedImagesScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isSaving = false;
  bool _saveToGalleryChecked = true;

  Future<void> _saveToGallery() async {
    try {
      final imageData = widget.generatedImages[_currentIndex];
      Uint8List imageBytes;

      if (imageData.startsWith('data:image')) {
        final base64Str = imageData.split(',')[1];
        imageBytes = base64Decode(base64Str);
      } else {
        final response = await http.get(Uri.parse(imageData));
        imageBytes = response.bodyBytes;
      }

      if (!mounted) return;
      final hasPermission = await PermissionHelper.checkSavePermission(context);
      if (!hasPermission) return;

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImageBytes(imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Image saved to Photo Gallery!',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Gal save error: $e');
    }
  }

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

      if (_saveToGalleryChecked) {
        await _saveToGallery();
      }

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

  Future<void> _turnIntoCarousel() async {
    try {
      final currentImageData = widget.generatedImages[_currentIndex];
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/carousel_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (currentImageData.startsWith('data:image')) {
        final base64Str = currentImageData.split(',')[1];
        final bytes = base64Decode(base64Str);
        await file.writeAsBytes(bytes);
      } else {
        await file.writeAsString(currentImageData);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrendingScreen(
              fromCarousel: true,
              category: 'Carousel',
              title: 'Choose Carousel Template',
              avatarImageFile: file,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparing avatar for carousel: $e',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildPrompt() {
    return 'Outfit: ${ widget.outfit}, Location: ${widget.location}, Hairstyle: ${widget.hairstyle}, Makeup: ${widget.makeup}, Angle: ${widget.angle}, Mood: ${widget.mood}';
  }

  Widget _buildSaveToGalleryCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() => _saveToGalleryChecked = !_saveToGalleryChecked);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _saveToGalleryChecked ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3),
            width: _saveToGalleryChecked ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _saveToGalleryChecked,
              activeColor: AppColors.gold,
              checkColor: AppColors.black,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _saveToGalleryChecked = val);
                }
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Save Image to Device Gallery',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
            Icon(
              Icons.photo_library_outlined,
              color: _saveToGalleryChecked ? AppColors.gold : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final displayRatio = widget.fromCarousel ? (9.0 / 16.0) : GeminiService.getDisplayRatio(widget.aspectRatio);
    final carouselHeight = ((screenWidth - 40) / displayRatio) + 16;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(
        actions: [
          ReportContentIconButton(
            contentId: 'image_${widget.generatedImages.isNotEmpty ? widget.generatedImages[_currentIndex].hashCode : DateTime.now().millisecondsSinceEpoch}',
            contentType: 'AI Generated Image',
            previewUrl: widget.generatedImages.isNotEmpty ? widget.generatedImages[_currentIndex] : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
            SizedBox(
              height: carouselHeight,
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
                      final ratio = widget.fromCarousel ? (9.0 / 16.0) : GeminiService.getDisplayRatio(widget.aspectRatio);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: ratio,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.memory(
                                imageBytes,
                                fit: widget.fromCarousel ? BoxFit.contain : BoxFit.cover,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: AspectRatio(
                        aspectRatio: widget.fromCarousel ? (9.0 / 16.0) : GeminiService.getDisplayRatio(widget.aspectRatio),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            imageData,
                            fit: widget.fromCarousel ? BoxFit.contain : BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Image Preview Available',
                                  style: AppFonts.poppins(
                                    size: 16,
                                    color: AppColors.white,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ReportContentTextButton(
                  contentId: 'image_${widget.generatedImages.isNotEmpty ? widget.generatedImages[_currentIndex].hashCode : DateTime.now().millisecondsSinceEpoch}',
                  contentType: 'AI Generated Image',
                  previewUrl: widget.generatedImages.isNotEmpty ? widget.generatedImages[_currentIndex] : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      final currentImage = widget.generatedImages[_currentIndex];
                      final content = GeneratedContent(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        originalImageUrl: currentImage,
                        prompt: 'Generated from Image flow',
                        createdAt: DateTime.now(),
                        contentType: 'original',
                        metadata: {
                          'outfit': widget.outfit,
                          'location': widget.location,
                          'hairstyle': widget.hairstyle,
                          'makeup': widget.makeup,
                          'angle': widget.angle,
                        },
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TalkingHeadCreationScreen(content: content),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_outlined, color: AppColors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'TURN INTO TALKING HEAD',
                              style: AppFonts.poppins(
                                size: 12,
                                weight: FontWeight.w900,
                                color: AppColors.black,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      final currentImage = widget.generatedImages[_currentIndex];
                      final content = GeneratedContent(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        originalImageUrl: currentImage,
                        prompt: 'Generated from Image flow',
                        createdAt: DateTime.now(),
                        contentType: 'original',
                        metadata: {
                          'outfit': widget.outfit,
                          'location': widget.location,
                          'hairstyle': widget.hairstyle,
                          'makeup': widget.makeup,
                          'angle': widget.angle,
                        },
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiVideoStoryCreationScreen(content: content),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.gold, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.movie_creation_outlined, color: AppColors.gold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'TURN INTO B-ROLL',
                              style: AppFonts.poppins(
                                size: 12,
                                weight: FontWeight.w900,
                                color: AppColors.gold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!widget.fromCarousel) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _turnIntoCarousel,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.gold, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_carousel_outlined, color: AppColors.gold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'TURN INTO CAROUSEL',
                                style: AppFonts.poppins(
                                  size: 12,
                                  weight: FontWeight.w900,
                                  color: AppColors.gold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Save to Gallery Checkbox Option (placed right above bottom action buttons)
            _buildSaveToGalleryCheckbox(),

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
