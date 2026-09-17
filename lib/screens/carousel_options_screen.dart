import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../utils/permission_helper.dart';
import 'library_screen.dart';
import 'carousel_screen.dart';
import 'trending_screen.dart';

class CarouselOptionsScreen extends StatefulWidget {
  const CarouselOptionsScreen({super.key});

  @override
  State<CarouselOptionsScreen> createState() => _CarouselOptionsScreenState();
}

class _CarouselOptionsScreenState extends State<CarouselOptionsScreen> {
  final ImagePicker _picker = ImagePicker();

  void _onAvatarSelected(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrendingScreen(
          fromCarousel: true,
          category: 'Carousel',
          title: 'Choose Carousel Template',
          avatarImageFile: imageFile,
        ),
      ),
    );
  }

  void _selectGenerateAvatar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrendingScreen(
          fromCarousel: true,
          category: 'Carousel',
          title: 'Carousel Avatar',
        ),
      ),
    );
  }

  Future<void> _selectUploadGallery() async {
    final hasPermission = await PermissionHelper.checkImagePermission(context, ImageSource.gallery);
    if (!hasPermission) return;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        _onAvatarSelected(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e', style: AppFonts.poppins(size: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectLibrary() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => const LibraryScreen(isSelectionMode: true),
      ),
    );

    if (result != null && mounted) {
      _onAvatarSelected(result);
    }
  }

  void _selectLegacyFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CarouselScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CAROUSEL STUDIO',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Stunning AI Carousels',
                style: AppFonts.playfair(
                  size: 24,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to provide your avatar or use legacy mode',
                style: AppFonts.poppins(
                  size: 12,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Option 1: Generate AI Avatar
              _buildOptionCard(
                icon: Icons.auto_awesome,
                title: 'GENERATE AI AVATAR',
                subtitle: 'Create a fresh AI avatar using prompts',
                onTap: _selectGenerateAvatar,
                gradientColors: [
                  AppColors.gold.withValues(alpha: 0.15),
                  AppColors.gold.withValues(alpha: 0.05),
                ],
              ),
              const SizedBox(height: 16),

              // Option 2: Upload from Gallery
              _buildOptionCard(
                icon: Icons.photo_library_outlined,
                title: 'UPLOAD FROM GALLERY',
                subtitle: 'Pick an avatar photo from your device',
                onTap: _selectUploadGallery,
                gradientColors: [
                  AppColors.white.withValues(alpha: 0.08),
                  AppColors.white.withValues(alpha: 0.02),
                ],
              ),
              const SizedBox(height: 16),

              // Option 3: Select from Library
              _buildOptionCard(
                icon: Icons.grid_view_rounded,
                title: 'SELECT FROM LIBRARY',
                subtitle: 'Choose from your saved library avatars',
                onTap: _selectLibrary,
                gradientColors: [
                  AppColors.white.withValues(alpha: 0.08),
                  AppColors.white.withValues(alpha: 0.02),
                ],
              ),
              const SizedBox(height: 16),

              // Option 4: Use Old Method (Legacy)
              _buildOptionCard(
                icon: Icons.history_rounded,
                title: 'USE OLD METHOD',
                subtitle: 'Access the classic multi-image carousel generator',
                onTap: _selectLegacyFlow,
                isLegacy: true,
                gradientColors: [
                  AppColors.gold.withValues(alpha: 0.08),
                  AppColors.white.withValues(alpha: 0.02),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    bool isLegacy = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isLegacy
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.gold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.poppins(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppFonts.poppins(
                          size: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.gold.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
