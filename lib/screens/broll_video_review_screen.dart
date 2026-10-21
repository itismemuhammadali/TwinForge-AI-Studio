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

class BrollVideoReviewScreen extends StatefulWidget {
  final String videoUrl;
  final int durationSeconds;
  final String prompt;

  const BrollVideoReviewScreen({
    super.key,
    required this.videoUrl,
    required this.durationSeconds,
    required this.prompt,
  });

  @override
  State<BrollVideoReviewScreen> createState() => _BrollVideoReviewScreenState();
}

class _BrollVideoReviewScreenState extends State<BrollVideoReviewScreen> {
  late VideoPlayerController _videoController;
  late String _currentVideoUrl;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _saveToGallery = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.videoUrl;
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
      debugPrint('Error initializing B-Roll video review player: $e');
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

      setState(() => _statusMessage = 'Downloading B-Roll video...');
      final response = await http.get(Uri.parse(_currentVideoUrl)).timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('Download timed out'),
      );
      final videoBytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/broll_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await tempFile.writeAsBytes(videoBytes);

      setState(() => _statusMessage = 'Saving to library...');
      final fileName = 'broll_${DateTime.now().millisecondsSinceEpoch}.mp4';
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
          'videoType': 'B-ROLL',
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
            content: Text('B-Roll video saved to library${_saveToGallery ? ' & gallery' : ''}!', style: AppFonts.poppins(color: AppColors.white)),
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
          'B-ROLL REVIEW',
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
            contentId: 'broll_${widget.videoUrl.hashCode}',
            contentType: 'AI Generated B-Roll Video',
            previewUrl: widget.videoUrl,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // VIDEO PLAYER CONTAINER WITH SCRUB BAR & REALTIME TIMER
            Container(
              height: 440,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController.value.size.width,
                                height: _videoController.value.size.height,
                                child: VideoPlayer(_videoController),
                              ),
                            ),
                          ),
                          // PLAY / PAUSE TOUCH OVERLAY
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _videoController.value.isPlaying
                                    ? _videoController.pause()
                                    : _videoController.play();
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: double.infinity,
                              height: double.infinity,
                              child: AnimatedOpacity(
                                opacity: _videoController.value.isPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.gold.withValues(alpha: 0.85),
                                  ),
                                  child: Icon(
                                    _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: AppColors.black,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // BADGE TOP RIGHT
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.movie_filter_outlined, color: AppColors.gold, size: 12),
                                  const SizedBox(width: 5),
                                  Text(
                                    'B-ROLL VIDEO',
                                    style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // PROGRESS BAR & REALTIME FRAME TIMER OVERLAY AT BOTTOM
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  const SizedBox(height: 6),
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
                                          Text(posStr, style: AppFonts.poppins(size: 11, weight: FontWeight.w600, color: Colors.white70)),
                                          Text(durStr, style: AppFonts.poppins(size: 11, weight: FontWeight.w600, color: Colors.white70)),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
              ),
            ),

            const SizedBox(height: 12),
            ReportContentTextButton(
              contentId: 'broll_${widget.videoUrl.hashCode}',
              contentType: 'AI Generated B-Roll Video',
              previewUrl: _currentVideoUrl,
            ),
            const SizedBox(height: 16),

            // BUTTON TO TURN B-ROLL VIDEO INTO TALKING HEAD
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: 'TURN IT INTO TALKING HEAD',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TalkingHeadAudioScreen(
                        initialVideoUrl: _currentVideoUrl,
                        durationSeconds: widget.durationSeconds,
                        prompt: widget.prompt,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

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
              const SizedBox(height: 16),
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
                label: 'TURN INTO TALKING HEAD',
                onTap: () async {
                  final newUrl = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TalkingHeadAudioScreen(
                        initialVideoUrl: _currentVideoUrl,
                        durationSeconds: widget.durationSeconds,
                        prompt: widget.prompt,
                      ),
                    ),
                  );
                  if (newUrl != null && mounted) {
                    setState(() {
                      _currentVideoUrl = newUrl;
                    });
                    await _initVideo(newUrl);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GoldButton(
                    label: _isSaving ? 'SAVING...' : 'SAVE VIDEO',
                    outlined: true,
                    loading: _isSaving,
                    onTap: _isSaving ? null : _saveVideo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
