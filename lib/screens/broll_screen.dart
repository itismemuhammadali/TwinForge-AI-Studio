import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../models/generated_content.dart';
import '../services/stock_image_service.dart';
import 'video_screen.dart';

class BrollScreen extends StatefulWidget {
  final GeneratedContent? content;
  const BrollScreen({super.key, this.content});
  @override
  State<BrollScreen> createState() => _BrollScreenState();
}

class _BrollScreenState extends State<BrollScreen> {
  String _motionStyle = StudioOptions.motionStyles[0];
  bool _hasImage = false;
  int _selectedDuration = 5;
  
  List<StockVideo> _templates = [];
  bool _isLoadingTemplates = true;

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _hasImage = true;
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final videos = await StockImageService.searchBRollVideos(perPage: 10);
      if (mounted) {
        setState(() {
          _templates = videos;
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTemplates = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: const AimrAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(children: [
          // Section Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'B-ROLL',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create Cinematic Clips',
                style: AppFonts.playfair(
                  size: 32,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Convert images into short cinematic clips or use high-quality templates',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Templates Section
          _buildTemplatesSection(),

          const SizedBox(height: 40),
          
          Row(children: [
            const Expanded(child: Divider(color: AppColors.surface, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR UPLOAD IMAGE', 
                style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
            ),
            const Expanded(child: Divider(color: AppColors.surface, thickness: 1)),
          ]),
          
          const SizedBox(height: 32),

          // Upload
          GestureDetector(
            onTap: () => setState(() => _hasImage = !_hasImage),
            child: Container(
              width: double.infinity, height: 240,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hasImage ? AppColors.gold.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: _hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: widget.content != null
                          ? Image.network(
                              widget.content!.editedImageUrl ?? widget.content!.originalImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.image, color: AppColors.muted, size: 60),
                              ),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.image, color: AppColors.muted, size: 60),
                            ),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.video_camera_back_outlined, color: AppColors.gold, size: 40),
                      const SizedBox(height: 12),
                      Text('Upload Source Image', style: AppFonts.playfair(size: 18, style: FontStyle.italic, color: AppColors.white)),
                    ]),
            ),
          ),

          const SizedBox(height: 24),

          // Motion style
          AimrDropdown(
            label: 'Motion Style',
            value: _motionStyle,
            options: StudioOptions.motionStyles,
            icon: Icons.movie_filter_outlined,
            onChanged: (v) => setState(() => _motionStyle = v),
          ),

          const SizedBox(height: 24),

          // Duration selector
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CLIP DURATION',
                style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
            const SizedBox(height: 12),
            Row(children: [5, 10, 15].map((sec) {
              final isSelected = _selectedDuration == sec;
              return GestureDetector(
                onTap: () => setState(() => _selectedDuration = sec),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.white.withValues(alpha: 0.06),
                      width: isSelected ? 1 : 0.5,
                    ),
                  ),
                  child: Text('${sec}s',
                      style: AppFonts.poppins(size: 13, weight: FontWeight.w600,
                          color: isSelected ? AppColors.gold : AppColors.muted)),
                ),
              );
            }).toList()),
          ]),

          const SizedBox(height: 40),

          GoldButton(label: 'GENERATE B-ROLL', onTap: () {}),

          const SizedBox(height: 24),
          _comingSoonBadge('Phase 2 feature — Kling API integration coming soon.'),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'B-ROLL TEMPLATES',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 3,
              ),
            ),
            if (_templates.isNotEmpty)
              GestureDetector(
                onTap: () => _loadTemplates(),
                child: const Icon(Icons.refresh, color: AppColors.gold, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingTemplates)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          )
        else if (_templates.isEmpty)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('No templates found', style: AppFonts.poppins(color: AppColors.muted)),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final video = _templates[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoScreen(templateVideo: video)),
                  ),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(video.thumbnailUrl, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                              ),
                            ),
                          ),
                          const Center(child: Icon(Icons.play_circle_outline, color: AppColors.white, size: 30)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _comingSoonBadge(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(msg, style: AppFonts.poppins(size: 11, color: AppColors.gold))),
    ]),
  );
}
