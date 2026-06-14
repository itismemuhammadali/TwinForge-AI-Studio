import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'generate_screen.dart';
import 'library_screen.dart';
import 'carousel_screen.dart';
import 'broll_screen.dart';
import 'talking_head_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AimrAppBar(
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
                borderRadius: BorderRadius.circular(20),
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt, color: AppColors.gold, size: 12),
                const SizedBox(width: 4),
                Text('16 Credits',
                    style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold)),
              ]),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
              color: AppColors.gold.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text('A',
                  style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            
            // TWINORA Logo
            Image.asset(
              'assets/images/TWINORA.AI_LOGO.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            
            const SizedBox(height: 24),
            
            Text('WELCOME BACK',
                style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 4)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: 'Your ', style: AppFonts.playfair(size: 36, weight: FontWeight.w900, color: AppColors.white)),
                TextSpan(text: 'AI', style: AppFonts.playfair(size: 36, weight: FontWeight.w900, color: AppColors.gold, style: FontStyle.italic)),
                TextSpan(text: ' Studio.', style: AppFonts.playfair(size: 36, weight: FontWeight.w900, color: AppColors.white)),
              ]),
            ),
            const SizedBox(height: 32),
            _SectionTitle('PHASE 01', 'Image Generation'),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.auto_awesome,
              title: 'Generate Visuals',
              subtitle: 'Create studio-quality images using your AI twin.',
              tag: 'ACTIVE',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateScreen())),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.collections_outlined,
              title: 'Content Library',
              subtitle: 'Access and manage all your generated studio content.',
              tag: 'ACTIVE',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
            ),
            const SizedBox(height: 32),
            _SectionTitle('PHASE 02', 'Carousel & B-Roll'),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.view_carousel_outlined,
              title: 'Carousel Generator',
              subtitle: 'Turn images into ready-to-post social media carousels.',
              tag: 'PHASE 2',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarouselScreen())),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.video_camera_back_outlined,
              title: 'B-Roll Video',
              subtitle: 'Convert images into short cinematic clips with motion styles.',
              tag: 'PHASE 2',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrollScreen())),
            ),
            const SizedBox(height: 32),
            _SectionTitle('PHASE 03', 'Talking Head'),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.record_voice_over_outlined,
              title: 'Talking Head Video',
              subtitle: 'Upload image, write a script, generate a complete AI video.',
              tag: 'PHASE 3',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TalkingHeadScreen())),
            ),
            const SizedBox(height: 32),
            GoldButton(
              label: 'START GENERATING',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateScreen())),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text('TWINORA  •  FOR HER  •  FOR HIM',
                  style: AppFonts.poppins(size: 9, color: AppColors.muted.withValues(alpha: 0.5), letterSpacing: 2)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String phase;
  final String title;
  const _SectionTitle(this.phase, this.title);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(phase,
            style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
      ),
      const SizedBox(width: 10),
      Text(title, style: AppFonts.playfair(size: 18, weight: FontWeight.w700, color: AppColors.text)),
    ]);
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = tag == 'ACTIVE';
    return DarkCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Icon(icon, color: AppColors.gold, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.gold.withValues(alpha: 0.15) : AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag,
                    style: AppFonts.poppins(size: 8, weight: FontWeight.w700,
                        color: isActive ? AppColors.gold : AppColors.muted, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: AppFonts.poppins(size: 11, color: AppColors.muted, height: 1.5)),
          ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios, color: AppColors.gold.withValues(alpha: 0.4), size: 12),
      ]),
    );
  }
}
