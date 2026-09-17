import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../services/fal_ai_service.dart';
import '../../services/storage_service.dart';
import 'talking_head_review_screen.dart';

class TalkingHeadGenerationScreen extends StatefulWidget {
  const TalkingHeadGenerationScreen({super.key});

  @override
  State<TalkingHeadGenerationScreen> createState() =>
      _TalkingHeadGenerationScreenState();
}

class _TalkingHeadGenerationScreenState extends State<TalkingHeadGenerationScreen> {
  VideoPlayerController? _videoController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateVideo();
    });
  }

  Future<void> _generateVideo() async {
    final provider = context.read<TalkingHeadProvider>();

    if (provider.selectedImage == null && provider.selectedImageUrl == null) {
      setState(() => _errorMessage = 'No image selected');
      return;
    }

    provider.setIsGeneratingVideo(true);

    try {
      debugPrint('🎬 Generating video with Kling V3...');

      // Convert File to URL if needed
      String imageUrl;
      if (provider.selectedImageUrl != null) {
        imageUrl = provider.selectedImageUrl!;
      } else {
        // Upload file to Firebase to get URL
        imageUrl = await StorageService.uploadImage(
          provider.selectedImage!,
          'users/${FirebaseAuth.instance.currentUser?.uid}/temp/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final videoUrl = await FalAiService().generateVideoFromKling(
        imageUrl: imageUrl,
        prompt: provider.videoPrompt,
        durationSeconds: provider.selectedDuration,
      );

      if (mounted) {
        provider.setGeneratedVideoUrl(videoUrl);
        _initializeVideoPlayer(videoUrl);
      }
    } catch (e) {
      debugPrint('❌ Video generation error: $e');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  void _initializeVideoPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController!.play();
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load video: $e');
      }
    });
  }

  void _proceedToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadReviewScreen(),
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
          leading: provider.isGeneratingVideo
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            'GENERATING VIDEO',
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

                if (provider.isGeneratingVideo)
                  _buildLoadingState()
                else if (_errorMessage != null)
                  _buildErrorState()
                else if (provider.generatedVideoUrl != null && _videoController != null && _videoController!.value.isInitialized)
                  _buildVideoState()
                else
                  Container(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppColors.gold,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating Video...',
            style: AppFonts.poppins(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Using HeyGen Engine',
            textAlign: TextAlign.center,
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFFC084FC),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Generation & Lip-Sync',
                        style: AppFonts.poppins(
                          size: 13,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Video generation and lip-sync creation take approximately 2 to 3 minutes. Please wait on this screen while our AI renders your creation.',
                        style: AppFonts.poppins(
                          size: 11,
                          weight: FontWeight.w400,
                          color: const Color(0xFF9CA3AF),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            'Video Generation Failed',
            style: AppFonts.poppins(
              size: 14,
              weight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GoldButton(
                  label: 'RETRY',
                  onTap: () {
                    setState(() => _errorMessage = null);
                    _generateVideo();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GoldButton(
                  label: 'GO BACK',
                  outlined: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoState() {
    return Column(
      children: [
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
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: GoldButton(
                label: 'REGENERATE',
                outlined: true,
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoldButton(
                label: 'PROCEED',
                onTap: _proceedToReview,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
