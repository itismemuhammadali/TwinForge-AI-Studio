import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/stock_image_service.dart';
import 'generate_screen.dart';

import 'profile_screen.dart';

class MagazineScreen extends StatefulWidget {
  const MagazineScreen({super.key});

  @override
  State<MagazineScreen> createState() => _MagazineScreenState();
}

class _MagazineScreenState extends State<MagazineScreen> {
  String _selectedStyle = 'All';
  final List<String> _styles = ['All', 'Cover', 'Newspaper', 'Comic'];
  
  List<StockImage> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    setState(() => _isLoading = true);
    try {
      String query = 'magazine';
      if (_selectedStyle == 'Cover') query = 'magazine cover';
      if (_selectedStyle == 'Newspaper') query = 'newspaper front page';
      if (_selectedStyle == 'Comic') query = 'comic book art';
      if (_selectedStyle == 'All') query = 'magazine layout';

      final results = await StockImageService.searchBoth(query: query, perPage: 15);
      setState(() => _templates = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching templates: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(
        actions: [],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Magazine Studio',
                    style: AppFonts.playfair(size: 30, weight: FontWeight.w900, color: AppColors.white)),
                const SizedBox(height: 8),
                Text('Cover, editorial, newspaper and comic magazine templates designed for premium launches.',
                    style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
                const SizedBox(height: 24),

                Wrap(spacing: 10, runSpacing: 10, children: _styles.map((style) =>
                  _styleChip(style, selected: style == _selectedStyle, onTap: () {
                    setState(() => _selectedStyle = style);
                    _fetchTemplates();
                  })
                ).toList()),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Premium Layouts', style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                    if (_isLoading)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_templates.isEmpty && !_isLoading)
                   Center(child: Text('No templates found', style: AppFonts.poppins(color: AppColors.muted)))
                else
                  _buildTemplateGrid(),
                
                const SizedBox(height: 32),

                GoldButton(
                  label: 'BROWSE ALL PREMIUM TEMPLATES',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppColors.surface,
                      content: Text('Loading more professional layouts...',
                          style: AppFonts.poppins(size: 12, color: AppColors.text)),
                    ));
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleChip(String label, {bool selected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.18) : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.gold : AppColors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Text(label,
            style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: selected ? AppColors.gold : AppColors.text,
                letterSpacing: 1)),
      ),
    );
  }

  Widget _buildTemplateGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _templateCard(context, template);
      },
    );
  }

  Widget _templateCard(BuildContext context, StockImage image) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GenerateScreen(presetStyle: image.title))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: Colors.white10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(image.title, 
                style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('by ${image.photographer}', 
                      style: AppFonts.poppins(size: 9, color: AppColors.muted),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(image.source.toUpperCase(), 
                    style: AppFonts.poppins(size: 8, weight: FontWeight.w800, color: AppColors.gold),
                  ),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
