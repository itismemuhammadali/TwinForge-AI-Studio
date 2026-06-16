import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../models/generated_content.dart';

import 'profile_screen.dart';

class TalkingHeadScreen extends StatefulWidget {
  final GeneratedContent? content;
  const TalkingHeadScreen({super.key, this.content});
  @override
  State<TalkingHeadScreen> createState() => _TalkingHeadScreenState();
}

class _TalkingHeadScreenState extends State<TalkingHeadScreen> {
  bool _hasImage = false;
  String _voiceStyle = StudioOptions.voiceStyles[0];
  final _scriptCtrl = TextEditingController();
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _hasImage = true;
    }
  }

  @override
  void dispose() { 
    _scriptCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(children: [
          // Section Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TALKING HEAD',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create AI Video Messages',
                style: AppFonts.playfair(
                  size: 32,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload your image, write a script, and generate a complete talking head video',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Step 1 — Upload
          _stepLabel('01', 'Upload Your Image'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _hasImage = !_hasImage),
            child: Container(
              width: double.infinity, height: 220,
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
                                child: const Icon(Icons.person, color: AppColors.muted, size: 60),
                              ),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.person, color: AppColors.muted, size: 60),
                            ),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.face_outlined, color: AppColors.gold, size: 40),
                      const SizedBox(height: 12),
                      Text('Upload Face Image', style: AppFonts.playfair(size: 18, style: FontStyle.italic, color: AppColors.white)),
                      const SizedBox(height: 6),
                      Text('CLEAR FRONT-FACING PHOTO',
                          style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                    ]),
            ),
          ),

          const SizedBox(height: 32),

          // Step 2 — Voice
          _stepLabel('02', 'Choose Voice Style'),
          const SizedBox(height: 12),
          AimrDropdown(
            label: 'AI Voice (ElevenLabs)',
            value: _voiceStyle,
            options: StudioOptions.voiceStyles,
            icon: Icons.record_voice_over_outlined,
            onChanged: (v) => setState(() => _voiceStyle = v),
          ),

          const SizedBox(height: 32),

          // Step 3 — Script
          _stepLabel('03', 'Write Your Script'),
          const SizedBox(height: 12),
          AimrField(
            label: 'SCRIPT',
            controller: _scriptCtrl,
            hint: 'Write what your AI twin will say...',
            maxLines: 6,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('0 / 500 characters',
                style: AppFonts.poppins(size: 10, color: AppColors.muted)),
          ),

          const SizedBox(height: 32),

          // Tech stack info
          DarkCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('POWERED BY',
                  style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
              const SizedBox(height: 12),
              _techRow(Icons.mic_outlined, 'ElevenLabs', 'AI Voice Generation'),
              const SizedBox(height: 10),
              _techRow(Icons.videocam_outlined, 'Kling API', 'Lip Sync'),
              const SizedBox(height: 10),
              _techRow(Icons.movie_outlined, 'Sync.so', 'Final Video Stitching'),
            ]),
          ),

          const SizedBox(height: 32),

          GoldButton(
            label: _generating ? 'GENERATING...' : 'GENERATE VIDEO',
            loading: _generating,
            onTap: () {
              setState(() => _generating = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _generating = false);
              });
            },
          ),

          const SizedBox(height: 24),
          _comingSoonBadge('Phase 3 feature — ElevenLabs, Kling & Sync.so integration coming soon.'),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _stepLabel(String num, String label) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Center(child: Text(num,
          style: AppFonts.poppins(size: 10, weight: FontWeight.w900, color: AppColors.gold))),
    ),
    const SizedBox(width: 12),
    Text(label, style: AppFonts.playfair(size: 18, weight: FontWeight.w700, color: AppColors.text)),
  ]);

  Widget _techRow(IconData icon, String name, String desc) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Icon(icon, color: AppColors.gold, size: 18),
    ),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.text)),
      Text(desc, style: AppFonts.poppins(size: 10, color: AppColors.muted)),
    ]),
  ]);

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
