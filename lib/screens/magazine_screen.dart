import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'generate_screen.dart';

class MagazineScreen extends StatelessWidget {
  const MagazineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: const AimrAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Magazine Studio',
              style: AppFonts.playfair(size: 30, weight: FontWeight.w900, color: AppColors.white)),
          const SizedBox(height: 8),
          Text('Cover, editorial, newspaper and comic magazine templates designed for premium launches.',
              style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 24),

          Wrap(spacing: 10, runSpacing: 10, children: [
            _styleChip('All', selected: true),
            _styleChip('Cover'),
            _styleChip('Newspaper'),
            _styleChip('Comic'),
          ]),
          const SizedBox(height: 28),

          _sectionHeader('Magazine Covers', 'Professional layouts with your photo on magazine covers'),
          const SizedBox(height: 16),
          _buildTemplateRow(context, [
            {'title': 'Vogue Style', 'desc': 'Elegant fashion magazine cover'},
            {'title': 'Time Magazine', 'desc': 'News magazine with headline'},
            {'title': 'Sports Illustrated', 'desc': 'Athletic and dynamic cover'},
          ]),
          const SizedBox(height: 32),

          _sectionHeader('Newspaper Front Pages', 'Classic newspaper layouts with articles and photos'),
          const SizedBox(height: 16),
          _buildTemplateRow(context, [
            {'title': 'Breaking News', 'desc': 'Front page with bold headlines'},
            {'title': 'Local Press', 'desc': 'Community newspaper style'},
            {'title': 'Business Daily', 'desc': 'Financial news layout'},
          ]),
          const SizedBox(height: 32),

          _sectionHeader('Comic & Storyboard', 'Dramatic comic frames and sequential storytelling'),
          const SizedBox(height: 16),
          _buildTemplateRow(context, [
            {'title': 'Action Comic', 'desc': 'Dynamic superhero style'},
            {'title': 'Romance Comic', 'desc': 'Emotional storytelling frames'},
            {'title': 'Horror Comic', 'desc': 'Suspenseful dark atmosphere'},
          ]),
          const SizedBox(height: 32),

          GoldButton(
            label: 'BROWSE ALL MAGAZINE TEMPLATES',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.surface,
                content: Text('Magazine templates are ready for your next AI image.',
                    style: AppFonts.poppins(size: 12, color: AppColors.text)),
              ));
            },
          ),
        ]),
      ),
    );
  }

  Widget _styleChip(String label, {bool selected = false}) {
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

  Widget _sectionHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
      const SizedBox(height: 6),
      Text(subtitle, style: AppFonts.poppins(size: 11, color: AppColors.muted, height: 1.6)),
    ]);
  }

  Widget _buildTemplateRow(BuildContext context, List<Map<String, String>> templates) {
    return Row(
      children: templates.map((template) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _templateCard(context, template['title']!, template['desc']!),
        ),
      )).toList(),
    );
  }

  Widget _templateCard(BuildContext context, String title, String desc) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GenerateScreen(presetStyle: title))),
      child: Container(
        height: 140,
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
                child: Icon(Icons.article, color: AppColors.gold.withValues(alpha: 0.3), size: 32),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.white)),
              const SizedBox(height: 4),
              Text(desc, style: AppFonts.poppins(size: 9, color: AppColors.muted, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }
}
