import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'generate_screen.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: const AimrAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trending Templates',
              style: AppFonts.playfair(size: 30, weight: FontWeight.w900, color: AppColors.white)),
          const SizedBox(height: 8),
          Text('Latest viral templates for images and videos. Upload your photo to generate.',
              style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 24),

          Wrap(spacing: 10, runSpacing: 10, children: [
            _categoryChip('All', selected: true),
            _categoryChip('Image'),
            _categoryChip('Video'),
            _categoryChip('Social'),
          ]),
          const SizedBox(height: 28),

          Text('Hot Picks This Week', style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 16),
          _buildTemplateGrid(context),
          const SizedBox(height: 28),

          GoldButton(
            label: 'LOAD MORE TEMPLATES',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.surface,
                content: Text('More templates coming soon in updates.',
                    style: AppFonts.poppins(size: 12, color: AppColors.text)),
              ));
            },
          ),
        ]),
      ),
    );
  }

  Widget _categoryChip(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.gold.withValues(alpha: 0.18) : AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Text(label,
          style: AppFonts.poppins(
              size: 11,
              weight: FontWeight.w700,
              color: selected ? AppColors.gold : AppColors.text,
              letterSpacing: 1)),
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    final templates = [
      {'title': 'Viral Portrait', 'desc': 'Bold studio lighting with dramatic shadows'},
      {'title': 'Story Glow', 'desc': 'Soft golden hour effect for social stories'},
      {'title': 'Cinematic Reel', 'desc': 'Slow motion style with depth of field'},
      {'title': 'Minimalist Chic', 'desc': 'Clean white background with subtle gradients'},
      {'title': 'Neon Nights', 'desc': 'Cyberpunk aesthetic with neon accents'},
      {'title': 'Vintage Film', 'desc': 'Retro grain effect with warm tones'},
      {'title': 'Urban Edge', 'desc': 'Street style with high contrast'},
      {'title': 'Dreamy Soft', 'desc': 'Blush tones with ethereal lighting'},
      {'title': 'Bold Pop', 'desc': 'Vibrant colors with pop art influences'},
      {'title': 'Monochrome Mood', 'desc': 'Timeless black and white with texture'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _templateCard(
          context,
          title: template['title']!,
          desc: template['desc']!,
        );
      },
    );
  }

  Widget _templateCard(BuildContext context, {
    required String title,
    required String desc,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GenerateScreen(presetStyle: title))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: Column(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.image, color: AppColors.gold.withValues(alpha: 0.3), size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.white)),
              const SizedBox(height: 4),
              Text(desc, style: AppFonts.poppins(size: 10, color: AppColors.muted, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }
}
