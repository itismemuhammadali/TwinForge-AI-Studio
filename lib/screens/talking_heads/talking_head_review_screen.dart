import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'talking_head_voice_options_screen.dart';

class TalkingHeadReviewScreen extends StatefulWidget {
  const TalkingHeadReviewScreen({super.key});

  @override
  State<TalkingHeadReviewScreen> createState() => _TalkingHeadReviewScreenState();
}

class _TalkingHeadReviewScreenState extends State<TalkingHeadReviewScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TalkingHeadProvider>();
      if (provider.generatedVideoUrl != null) {
        _initializeVideoPlayer(provider.generatedVideoUrl!);
      }
    });
  }

  void _initializeVideoPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController!.play();
      }
    });
  }

  void _proceedToVoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadVoiceOptionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TalkingHeadProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: const Color(0xFF0E0E0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'VIDEO REVIEW',
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Video Preview
                if (_videoController != null && _videoController!.value.isInitialized)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : _videoController!.play();
                                  });
                                },
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.gold.withValues(alpha: 0.8),
                                  ),
                                  child: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: AppColors.black,
                                    size: 35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Save to Gallery Checkbox
                GestureDetector(
                  onTap: () {
                    provider.setSaveToGallery(!provider.saveToGallery);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: provider.saveToGallery ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: provider.saveToGallery
                                  ? AppColors.gold
                                  : AppColors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: provider.saveToGallery
                              ? const Icon(Icons.check, color: AppColors.black, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Save to Gallery',
                                style: AppFonts.poppins(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                provider.saveToGallery
                                    ? 'Download to your device'
                                    : 'Upload to your Twinora library',
                                style: AppFonts.poppins(size: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          provider.saveToGallery ? Icons.download : Icons.cloud_upload,
                          color: AppColors.gold.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Proceed Button
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'PROCEED TO VOICE',
                    onTap: _proceedToVoice,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
