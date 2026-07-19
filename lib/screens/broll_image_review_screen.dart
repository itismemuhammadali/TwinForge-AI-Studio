import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../services/fal_ai_service.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';
import 'talking_head_screen.dart';

class BrollImageReviewScreen extends StatefulWidget {
  final GeneratedContent content;
  const BrollImageReviewScreen({super.key, required this.content});

  @override
  State<BrollImageReviewScreen> createState() => _BrollImageReviewScreenState();
}

class _BrollImageReviewScreenState extends State<BrollImageReviewScreen> {
  final _promptCtrl = TextEditingController();
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _saveToGallery = false;
  String? _videoUrl;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _promptCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String get _imageUrl =>
      widget.content.editedImageUrl ?? widget.content.originalImageUrl;

  Future<void> _saveVideo() async {
    if (_videoUrl == null) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      if (_saveToGallery) {
        await Gal.putVideo(_videoUrl!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to gallery!', style: AppFonts.poppins(color: AppColors.white)),
              backgroundColor: const Color(0xFF2a5a2a),
            ),
          );
        }
      } else {
        final fileName = 'broll_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final path = 'users/${user.uid}/generatedVideos/$fileName';

        final savedUrl = await StorageService.downloadAndSaveVideo(_videoUrl!, path);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('library')
            .add({
          'type': 'video',
          'url': savedUrl,
          'source': 'broll',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to library!', style: AppFonts.poppins(color: AppColors.white)),
              backgroundColor: const Color(0xFF2a5a2a),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e', style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _turnIntoBroll() async {
    if (_promptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a prompt for your B-Roll',
              style: AppFonts.poppins(size: 12, color: AppColors.text)),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    final falService = FalAiService();
    if (FalAiService.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('FAL AI API not configured',
              style: AppFonts.poppins(color: AppColors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate video from image using FAL AI
      final videoUrl = await falService.generateVideoFromImage(
        imageUrl: _imageUrl,
        prompt: _promptCtrl.text.trim(),
      );

      setState(() {
        _videoUrl = videoUrl;
        _isGenerating = false;
      });

      // Initialize video player
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_videoUrl!),
      );
      await _videoController!.initialize();
      setState(() {});
      _videoController!.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('B-Roll created successfully!',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          _videoUrl != null ? 'B-ROLL REVIEW' : 'REVIEW IMAGE',
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

              // Video or Image Preview
              if (_videoUrl != null && _videoController != null && _videoController!.value.isInitialized)
                _buildVideoPreview()
              else
                _buildImagePreview(),

              const SizedBox(height: 28),

              // Turn into B-Roll Section (hidden after video is generated)
              if (_videoUrl == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.movie_creation_outlined,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TURN INTO B-ROLL',
                            style: AppFonts.poppins(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Describe the motion and style for your B-Roll video',
                        style: AppFonts.poppins(
                          size: 12,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _promptCtrl,
                        maxLines: 3,
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Slow cinematic pan with golden hour lighting...',
                          hintStyle: AppFonts.poppins(
                            size: 13,
                            color: AppColors.muted.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: GoldButton(
                          label: _isGenerating ? 'GENERATING...' : 'CREATE B-ROLL',
                          loading: _isGenerating,
                          onTap: _isGenerating ? null : _turnIntoBroll,
                        ),
                      ),
                    ],
                  ),
                ),

              // Video Actions (shown after video is generated)
              if (_videoUrl != null) ...[
                // Save option checkbox
                GestureDetector(
                  onTap: () => setState(() => _saveToGallery = !_saveToGallery),
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
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _saveToGallery ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _saveToGallery ? AppColors.gold : AppColors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: _saveToGallery
                              ? const Icon(Icons.check, color: AppColors.black, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Save to Gallery', style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.white)),
                              Text(
                                _saveToGallery ? 'Download to your device' : 'Upload to your Twinora library',
                                style: AppFonts.poppins(size: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _saveToGallery ? Icons.download : Icons.cloud_upload,
                          color: AppColors.gold.withValues(alpha: 0.6), size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GoldButton(
                        label: _isSaving ? 'SAVING...' : 'SAVE VIDEO',
                        loading: _isSaving,
                        onTap: _isSaving ? null : _saveVideo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoldButton(
                        label: 'REGENERATE',
                        outlined: true,
                        onTap: () {
                          setState(() {
                            _videoUrl = null;
                            _videoController?.dispose();
                            _videoController = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Turn into Talking Head
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'TURN INTO TALKING HEAD',
                    outlined: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TalkingHeadScreen(content: widget.content),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Back Button
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
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                // Play/Pause button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
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
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppColors.black,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildImageDisplay(),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_imageUrl.startsWith('data:image')) {
      try {
        final base64Str = _imageUrl.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, height: 380, width: double.infinity);
      } catch (e) {
        return _imagePlaceholder();
      }
    } else if (_imageUrl.startsWith('https://')) {
      return Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        height: 380,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => Container(
    height: 380,
    color: AppColors.surface,
    child: const Icon(Icons.image_not_supported_outlined,
        color: AppColors.muted, size: 60),
  );
}
