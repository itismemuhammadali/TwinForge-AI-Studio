import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../providers/content_provider.dart';
import 'main_shell.dart';

class VideoReviewScreen extends StatefulWidget {
  final String videoUrl;
  final String prompt;

  const VideoReviewScreen({
    super.key,
    required this.videoUrl,
    required this.prompt,
  });

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  late VideoPlayerController _controller;
  bool _downloadToGallery = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      _controller.setLooping(true);
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // 1. Download video from AI service to upload to Firebase Storage
      final response = await http.get(Uri.parse(widget.videoUrl));
      if (response.statusCode != 200) throw Exception('Failed to fetch generated video');
      final videoBytes = response.bodyBytes;

      // 2. Upload to Firebase Storage
      final fileName = 'broll_${DateTime.now().millisecondsSinceEpoch}.mp4';
      // PATH MUST MATCH STORAGE RULES: users/{userId}/generatedVideos/{videoId}
      final storageRef = FirebaseStorage.instance.ref('users/${user.uid}/generatedVideos/$fileName');
      
      debugPrint('📤 Uploading to Firebase Storage: users/${user.uid}/generatedVideos/$fileName');
      
      final uploadTask = await storageRef.putData(
        videoBytes,
        SettableMetadata(contentType: 'video/mp4'),
      ).catchError((error) {
        debugPrint('❌ Firebase Storage Upload Error: $error');
        throw Exception('Storage Upload Failed: $error');
      });

      final firebaseVideoUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('✅ Video uploaded to Firebase Storage: $firebaseVideoUrl');

      // 3. Create GeneratedContent with the NEW Firebase URL
      final generatedContent = GeneratedContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalImageUrl: firebaseVideoUrl, 
        editedImageUrl: firebaseVideoUrl, 
        prompt: widget.prompt,
        createdAt: DateTime.now(),
        contentType: 'video',
        metadata: {
          'source': 'broll_studio',
          'type': 'video',
          'videoType': 'B-ROLL', // Specific type for the badge
          'storagePath': 'users/${user.uid}/generatedVideos/$fileName',
        },
      );

      final contentMap = generatedContent.toMap();
      contentMap['type'] = 'video';

      // 4. Save to database
      final contentProvider = context.read<ContentProvider>();
      await contentProvider.saveContent(
        user.uid,
        contentMap,
      );

      // 5. Download to gallery if checked (using local bytes we already have)
      if (_downloadToGallery) {
        try {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(videoBytes);
          await Gal.putVideo(filePath, album: 'TWINORA');
        } catch (e) {
          debugPrint('Gallery save error: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video saved${_downloadToGallery ? ' and downloaded' : ''}!',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to MainShell
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              Text('REVIEW VIDEO',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 3,
                  )),
              const SizedBox(height: 8),
              Text('Your AI Masterpiece',
                  style: AppFonts.playfair(
                    size: 32,
                    weight: FontWeight.w900,
                    color: AppColors.white,
                  )),
              const SizedBox(height: 8),
              Text(
                'Review your generated video below.',
                textAlign: TextAlign.center,
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 32),

              // Video Preview
              Container(
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
                    child: _isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_controller),
                                VideoProgressIndicator(_controller, allowScrubbing: true),
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _controller.value.isPlaying
                                            ? _controller.pause()
                                            : _controller.play();
                                      });
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                                          ),
                                          child: Icon(
                                            _controller.value.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: AppColors.gold,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            height: 380,
                            width: double.infinity,
                            color: AppColors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.gold),
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Checkbox for download
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _downloadToGallery,
                      onChanged: (value) => setState(() => _downloadToGallery = value ?? false),
                      activeColor: AppColors.gold,
                      checkColor: AppColors.black,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download to Gallery',
                        style: AppFonts.poppins(
                          size: 14,
                          color: AppColors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              GoldButton(
                label: _isSaving ? 'SAVING...' : 'SAVE VIDEO',
                loading: _isSaving,
                onTap: _isSaving ? null : _handleSave,
              ),

              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'DISCARD',
                  style: AppFonts.poppins(
                    color: Colors.redAccent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
