import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/carousel_provider.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'carousel_category_screen.dart';

class CarouselScreen extends StatefulWidget {
  const CarouselScreen({super.key});

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize carousel provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarouselProvider>().initializeCarouselCreation();
    });
  }

  void debugLog(String message) {
    developer.log('[CarouselScreen] $message');
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final files = pickedFiles.map((f) => File(f.path)).toList();
        if (mounted) {
          context.read<CarouselProvider>().addUploadedImages(files);
        }
        debugLog('📸 Added ${files.length} images');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        if (mounted) {
          context.read<CarouselProvider>().addUploadedImages([File(pickedFile.path)]);
        }
        debugLog('📸 Added image from camera');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.gold, size: 24),
              title: Text(
                'Take Photo',
                style: AppFonts.poppins(size: 14, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.gold, size: 24),
              title: Text(
                'Choose from Gallery',
                style: AppFonts.poppins(size: 14, color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _proceedToCategories() async {
    final carouselProvider = context.read<CarouselProvider>();

    if (carouselProvider.uploadedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload at least 1 image',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    debugLog('✅ Proceeding with ${carouselProvider.uploadedImages.length} images');

    if (mounted) {
      _push(context, const CarouselCategoryScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    final carouselProvider = context.watch<CarouselProvider>();
    final imageCount = carouselProvider.uploadedImages.length;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'CAROUSEL',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create Social Media Carousels',
                    style: AppFonts.playfair(
                      size: 32,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload 4-5 images and create professional carousel posts for Instagram and Facebook',
                    style: AppFonts.poppins(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Step 1: Upload Images
                  _buildStepHeader(
                    number: '1',
                    title: 'UPLOAD IMAGES',
                    subtitle: 'Add 4-5 of your photos',
                  ),
                  const SizedBox(height: 20),
                  _buildImageUploadSection(imageCount),
                  const SizedBox(height: 40),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'How It Works',
                              style: AppFonts.poppins(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. Upload 4-5 of your images\n2. Select image categories and styles\n3. Pick a professional carousel template\n4. Place your images on the template\n5. Add text and overlays\n6. Download as ZIP with all files',
                          style: AppFonts.poppins(
                            size: 11,
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Next Button
                  GoldButton(
                    label: imageCount >= 1 ? 'CONTINUE' : 'UPLOAD IMAGES',
                    onTap: imageCount >= 1 ? _proceedToCategories : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.gold,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: AppFonts.poppins(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 2,
              ),
            ),
            Text(
              subtitle,
              style: AppFonts.poppins(
                size: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(int imageCount) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images: $imageCount/5',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            if (imageCount < 5)
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'ADD',
                        style: AppFonts.poppins(
                          size: 9,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        imageCount == 0 ? _buildEmptyImageState() : _buildImageGrid(),
      ],
    );
  }

  Widget _buildEmptyImageState() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.image_outlined,
                color: AppColors.gold,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Your Images',
              style: AppFonts.playfair(
                size: 18,
                style: FontStyle.italic,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload 4-5 images to get started',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final images = context.read<CarouselProvider>().uploadedImages;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => _buildImageCard(images[index], index),
        ),
        if (images.length < 5)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.gold.withValues(alpha: 0.6),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add More Images',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w600,
                        color: AppColors.gold.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageCard(File imageFile, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              context.read<CarouselProvider>().removeUploadedImage(index);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.black.withValues(alpha: 0.7),
                border: Border.all(
                  color: AppColors.gold,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.close,
                color: AppColors.gold,
                size: 14,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '${index + 1}',
              style: AppFonts.poppins(
                size: 9,
                weight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
