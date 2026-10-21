import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'talking_head_audio_screen.dart';
import 'main_shell.dart';

class TalkingHeadVideoReviewScreen extends StatefulWidget {
  final String videoUrl;
  final int durationSeconds;
  final String prompt;
  final bool hasAudioStitched;

  const TalkingHeadVideoReviewScreen({
    super.key,
    required this.videoUrl,
    required this.durationSeconds,
    required this.prompt,
    this.hasAudioStitched = false,
  });

  @override
  State<TalkingHeadVideoReviewScreen> createState() => _TalkingHeadVideoReviewScreenState();
}

class _TalkingHeadVideoReviewScreenState extends State<TalkingHeadVideoReviewScreen> {
  late VideoPlayerController _videoController;
  late String _currentVideoUrl;
  late bool _hasAudioStitched;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _saveToGallery = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.videoUrl;
    _hasAudioStitched = widget.hasAudioStitched;
    _initVideo(_currentVideoUrl);
  }

  Future<void> _initVideo([String? urlOverride]) async {
    final url = urlOverride ?? _currentVideoUrl;
    final oldCtrl = _isInitialized ? _videoController : null;
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController.initialize();
      if (oldCtrl != null) await oldCtrl.dispose();
      if (mounted) {
        _videoController.addListener(() {
          if (mounted) setState(() {});
        });
        setState(() {
          _currentVideoUrl = url;
          _isInitialized = true;
        });
        _videoController.play();
        _videoController.setLooping(true);
      }
    } catch (e) {
      debugPrint('Error initializing video review player: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _saveVideo() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      setState(() => _statusMessage = 'Downloading video...');
      final response = await http.get(Uri.parse(_currentVideoUrl)).timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('Download timed out'),
      );
      final videoBytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/talking_head_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await tempFile.writeAsBytes(videoBytes);

      setState(() => _statusMessage = 'Saving to library...');
      final fileName = 'talking_head_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = 'users/${user.uid}/generatedVideos/$fileName';
      final storageRef = FirebaseStorage.instance.ref().child(path);

      await storageRef.putData(
        videoBytes,
        SettableMetadata(contentType: 'video/mp4'),
      );

      final savedUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('content').add({
        'type': 'video',
        'editedImageUrl': savedUrl,
        'originalImageUrl': savedUrl,
        'videoUrl': savedUrl,
        'prompt': widget.prompt,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'videoType': 'TALKING HEAD',
          'durationSeconds': widget.durationSeconds,
        },
      });

      if (_saveToGallery) {
        setState(() => _statusMessage = 'Saving to gallery...');
        try {
          await Gal.putVideo(tempFile.path);
        } catch (e) {
          debugPrint('⚠️ Gallery save error: $e');
        }
      }

      await tempFile.delete();
      setState(() => _statusMessage = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video saved to library${_saveToGallery ? ' & gallery' : ''}!', style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: const Color(0xFF2a5a2a),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      if (mounted) {
        setState(() => _statusMessage = '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e', style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'REVIEW VIDEO',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          ReportContentIconButton(
            contentId: 'talking_head_${widget.videoUrl.hashCode}',
            contentType: 'AI Generated Talking Head Video',
            previewUrl: widget.videoUrl,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // CREATION TIME & DURATION BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.gold, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'Created Just Now',
                        style: AppFonts.poppins(size: 11, weight: FontWeight.w600, color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Duration: ${widget.durationSeconds}s',
                  style: AppFonts.poppins(size: 11, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // VIDEO PLAYER PREVIEW (DYNAMIC ASPECT RATIO FRAME)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 200,
                  maxHeight: 440,
                ),
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: _videoController.value.size.width > 0
                                        ? _videoController.value.size.width
                                        : 1280,
                                    height: _videoController.value.size.height > 0
                                        ? _videoController.value.size.height
                                        : 720,
                                    child: VideoPlayer(_videoController),
                                  ),
                                ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videoController.value.isPlaying
                                      ? _videoController.pause()
                                      : _videoController.play();
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold.withValues(alpha: 0.8),
                                ),
                                child: Icon(
                                  _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: AppColors.black,
                                  size: 30,
                                ),
                              ),
                            ),

                            // PROGRESS BAR OVERLAY AT BOTTOM
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    VideoProgressIndicator(
                                      _videoController,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: AppColors.gold,
                                        bufferedColor: Colors.white30,
                                        backgroundColor: Colors.white12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ValueListenableBuilder<VideoPlayerValue>(
                                      valueListenable: _videoController,
                                      builder: (context, value, child) {
                                        final pos = value.position;
                                        final dur = value.duration;
                                        final posStr = '${pos.inMinutes.remainder(60).toString().padLeft(2, '0')}:${pos.inSeconds.remainder(60).toString().padLeft(2, '0')}';
                                        final durStr = '${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}:${dur.inSeconds.remainder(60).toString().padLeft(2, '0')}';
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(posStr, style: AppFonts.poppins(size: 10, color: Colors.white70)),
                                            Text(durStr, style: AppFonts.poppins(size: 10, color: Colors.white70)),
                                          ],
                                        );
                                      },
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   )
                 : Container(
                     height: 280,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       color: AppColors.surface,
                       borderRadius: BorderRadius.circular(26),
                       border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
                     ),
                     child: const Center(
                       child: CircularProgressIndicator(color: AppColors.gold),
                     ),
                   ),
             ),
           ),

            const SizedBox(height: 28),

            const SizedBox(height: 12),
            ReportContentTextButton(
              contentId: 'talking_head_${widget.videoUrl.hashCode}',
              contentType: 'AI Generated Talking Head Video',
              previewUrl: widget.videoUrl,
            ),
            const SizedBox(height: 16),
            // BUTTON TO GO TO AUDIO RECORDING / VOICE CLONING SCREEN (SHOWN ONLY BEFORE STITCHING)
            if (!_hasAudioStitched) ...[
              SizedBox(
                width: double.infinity,
                child: GoldButton(
                  label: 'RECORD AUDIO',
                  onTap: () async {
                    final newUrl = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TalkingHeadAudioScreen(
                          initialVideoUrl: _currentVideoUrl,
                          durationSeconds: widget.durationSeconds,
                          prompt: widget.prompt,
                          videoModel: 'Kling 3.0 Pro',
                        ),
                      ),
                    );
                    if (newUrl != null && mounted) {
                      setState(() {
                        _currentVideoUrl = newUrl;
                        _hasAudioStitched = true;
                      });
                      await _initVideo(newUrl);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // STATUS MESSAGE
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Row(
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(_statusMessage, style: AppFonts.poppins(size: 12, color: AppColors.gold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // SAVE TO GALLERY CHECKBOX & ACTIONS
            GestureDetector(
              onTap: () => setState(() => _saveToGallery = !_saveToGallery),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _saveToGallery ? AppColors.gold : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _saveToGallery ? AppColors.gold : AppColors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: _saveToGallery ? const Icon(Icons.check, color: AppColors.black, size: 13) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Save to Gallery', style: AppFonts.poppins(size: 12, weight: FontWeight.w600, color: AppColors.white)),
                          Text(_saveToGallery ? 'Download to your device' : 'Upload to your Twinora library', style: AppFonts.poppins(size: 10, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Icon(_saveToGallery ? Icons.download : Icons.cloud_upload, color: AppColors.gold.withValues(alpha: 0.6), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: _isSaving ? 'SAVING...' : 'SAVE VIDEO',
                loading: _isSaving,
                onTap: _isSaving ? null : _saveVideo,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: 'BACK TO HOME',
                outlined: true,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
