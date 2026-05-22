import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../models/generated_content.dart';

class CarouselScreen extends StatefulWidget {
  final GeneratedContent? content;
  const CarouselScreen({super.key, this.content});
  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  String _template = StudioOptions.carouselTemplates[0];
  final _textCtrl = TextEditingController();
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _hasImage = true;
    }
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AimrAppBar(actions: []),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const SizedBox(height: 32),
          
          // TWINORA Logo
          Image.asset(
            'assets/images/TWINORA.AI_LOGO.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          
          const SizedBox(height: 24),
          
          const PhaseHeader(phase: 'PHASE 02', title: 'Carousel Generator'),
          const SizedBox(height: 12),
          Text('Turn images into ready-to-post social media carousels with templates and text overlays.',
              textAlign: TextAlign.center,
              style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 32),

          // Upload image
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
                  ? Stack(fit: StackFit.expand, children: [
                      ClipRRect(
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
                      ),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.gold, size: 40),
                      const SizedBox(height: 12),
                      Text('Upload Image', style: AppFonts.playfair(size: 18, style: FontStyle.italic, color: AppColors.white)),
                    ]),
            ),
          ),

          const SizedBox(height: 24),

          // Template selector
          AimrDropdown(
            label: 'Carousel Template',
            value: _template,
            options: StudioOptions.carouselTemplates,
            icon: Icons.view_carousel_outlined,
            onChanged: (v) => setState(() => _template = v),
          ),

          const SizedBox(height: 24),

          // Text overlay
          AimrField(
            label: 'TEXT OVERLAY (OPTIONAL)',
            controller: _textCtrl,
            hint: 'Add text to your carousel...',
            maxLines: 3,
          ),

          const SizedBox(height: 40),

          GoldButton(
            label: 'GENERATE CAROUSEL',
            onTap: () {},
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Phase 2 feature — coming soon.',
                    style: AppFonts.poppins(size: 11, color: AppColors.gold)),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
