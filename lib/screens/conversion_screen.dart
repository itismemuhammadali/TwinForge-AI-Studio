import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import 'talking_head_screen.dart';
import 'broll_screen.dart';
import 'carousel_screen.dart';

class ConversionScreen extends StatelessWidget {
  final GeneratedContent content;
  const ConversionScreen({super.key, required this.content});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  TextSpan(text: 'A', style: AppFonts.playfair(size: 28, weight: FontWeight.w900, color: AppColors.gold)),
                  TextSpan(text: 'IMR', style: AppFonts.playfair(size: 28, weight: FontWeight.w900, color: AppColors.white)),
                ]),
              ),
              const SizedBox(height: 24),
              Text('CONVERT TO VIDEO',
                  style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 4)),
              const SizedBox(height: 8),
              Text('Choose Your Format',
                  style: AppFonts.playfair(size: 32, weight: FontWeight.w900, color: AppColors.white)),
              const SizedBox(height: 8),
              Text('Transform your image into engaging video content.',
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6)),
              const SizedBox(height: 32),

              // Image Preview with glow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    content.editedImageUrl ?? content.originalImageUrl,
                    fit: BoxFit.cover,
                    height: 280,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => Container(
                      height: 280,
                      color: AppColors.surface,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.muted, size: 60),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Conversion Options
              _conversionCard(
                context,
                icon: Icons.person_outline,
                title: 'Talking Head',
                description: 'Add voice & lip sync to create a speaking video',
                color: const Color(0xFF9B59B6),
                onTap: () => _navigate(
                  context,
                  TalkingHeadScreen(content: content),
                ),
              ),
              const SizedBox(height: 16),

              _conversionCard(
                context,
                icon: Icons.movie_outlined,
                title: 'B-Roll Video',
                description: 'Create cinematic motion with camera effects',
                color: const Color(0xFF3498DB),
                onTap: () => _navigate(
                  context,
                  BrollScreen(content: content),
                ),
              ),
              const SizedBox(height: 16),

              _conversionCard(
                context,
                icon: Icons.collections_outlined,
                title: 'Social Carousel',
                description: 'Turn into a multi-slide social media post',
                color: const Color(0xFF27AE60),
                onTap: () => _navigate(
                  context,
                  const CarouselScreen(),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.poppins(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppFonts.poppins(
                      size: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
