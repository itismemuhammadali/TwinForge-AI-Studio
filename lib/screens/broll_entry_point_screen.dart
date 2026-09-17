import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'library_screen.dart';
import 'trending_screen.dart';
import 'broll_image_review_screen.dart';

class BrollEntryPointScreen extends StatelessWidget {
  const BrollEntryPointScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: Text(
          'CREATE B-ROLL',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'STEP 1',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start with an Image',
                style: AppFonts.playfair(
                  size: 32,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose how you want to begin your B-Roll creation',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildOptionCard(
                context,
                icon: Icons.auto_awesome,
                title: 'Generate New Image',
                subtitle: 'Create a fresh image using AI templates and prompts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrendingScreen(fromBroll: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context,
                icon: Icons.photo_library_outlined,
                title: 'Select from Library',
                subtitle: 'Use a previously generated image from your collection',
                onTap: () async {
                  final result = await Navigator.push<File>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LibraryScreen(isSelectionMode: true),
                    ),
                  );
                  if (result != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrollImageReviewScreen(
                          imageFile: result,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context,
                icon: Icons.upload_file,
                title: 'Upload from Gallery',
                subtitle: 'Use an image already saved on your device',
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrollImageReviewScreen(
                          imageFile: File(pickedFile.path),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.gold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.poppins(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppFonts.poppins(
                      size: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
