import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:video_player/video_player.dart';
import 'package:gal/gal.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../services/storage_service.dart';
import '../../services/everypixel_ai_service.dart';

class TalkingHeadStitchScreen extends StatefulWidget {
  const TalkingHeadStitchScreen({super.key});

  @override
  State<TalkingHeadStitchScreen> createState() => _TalkingHeadStitchScreenState();
}

class _TalkingHeadStitchScreenState extends State<TalkingHeadStitchScreen> {
  bool _isStitching = false;
  String? _stitchedVideoUrl;
  String? _errorMessage;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStitching();
    });
  }

  Future<void> _startStitching() async {
    final provider = context.read<TalkingHeadProvider>();

    if (provider.generatedVideoUrl == null || provider.recordedAudioUrl == null) {
      setState(() => _errorMessage = 'Missing video or audio');
      return;
    }

    setState(() => _isStitching = true);

    try {
      // Get Sync Labs API key
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      // Upload audio to storage first (if it's local)
      String audioUrl = provider.recordedAudioUrl!;
      if (!audioUrl.startsWith('https://')) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not authenticated');

        final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final path = 'users/${user.uid}/talking_heads/$fileName';
        final audioFile = File(audioUrl);
        final audioBytes = await audioFile.readAsBytes();

        audioUrl = await StorageService.uploadAudioBytes(audioBytes, path);
        debugPrint('✅ Audio uploaded: $audioUrl');
      }

      final everypixelClientId = remoteConfig.getString('everypixel_client_id').trim();
      final lipSyncProvider = remoteConfig.getString('lipsync_provider').trim().toLowerCase();

      // Try Everypixel Labs if configured or explicitly preferred
      if (everypixelClientId.isNotEmpty || lipSyncProvider == 'everypixel') {
        try {
          debugPrint('🎬 Starting lip sync with Everypixel Labs...');
          final outputUrl = await EverypixelAiService.generateLipSyncVideo(
            videoUrl: provider.generatedVideoUrl!,
            audioUrl: audioUrl,
          );
          if (mounted) {
            setState(() {
              _stitchedVideoUrl = outputUrl;
              _isStitching = false;
            });
            _initializeVideoPlayer(outputUrl);
            return;
          }
        } catch (eEverypixel) {
          debugPrint('⚠️ Everypixel Labs failed ($eEverypixel). Falling back to Sync Labs...');
        }
      }

      // Fallback or default to Sync Labs
      final syncLabsKey = remoteConfig.getString('synclabs_api_key');
      if (syncLabsKey.isEmpty) {
        throw Exception('Lip Sync API key not configured');
      }

      debugPrint('🎬 Starting lip sync with Sync Labs...');

      // Call Sync Labs API
      final response = await http.post(
        Uri.parse('https://api.sync.so/v2/generate'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': syncLabsKey,
        },
        body: jsonEncode({
          'model': 'sync-3',
          'input': [
            {'type': 'video', 'url': provider.generatedVideoUrl},
            {'type': 'audio', 'url': audioUrl},
          ],
          'options': {'sync_mode': 'loop'},
        }),
      );

      debugPrint('📥 Sync Labs response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Sync Labs error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final generationId = data['id'];

      if (generationId == null) {
        throw Exception('No generation ID from Sync Labs');
      }

      debugPrint('🆔 Sync Labs task ID: $generationId');

      // Poll for completion
      await _pollSyncLabsStatus(generationId, syncLabsKey);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        _showError('Stitching failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isStitching = false);
      }
    }
  }

  Future<void> _pollSyncLabsStatus(String generationId, String apiKey) async {
    int attempts = 0;
    const maxAttempts = 120; // 10 minutes

    while (attempts < maxAttempts) {
      attempts++;
      await Future.delayed(const Duration(seconds: 5));

      try {
        final statusResponse = await http.get(
          Uri.parse('https://api.sync.so/v2/generate/$generationId'),
          headers: {'x-api-key': apiKey},
        );

        if (statusResponse.statusCode == 200) {
          final statusData = jsonDecode(statusResponse.body);
          final status = statusData['status'];

          debugPrint('📊 Sync Labs status: $status (attempt $attempts)');

          if (status == 'COMPLETED') {
            final outputUrl = statusData['outputUrl'];
            if (outputUrl == null) {
              throw Exception('No output URL in response');
            }

            if (mounted) {
              setState(() => _stitchedVideoUrl = outputUrl);
              _initializeVideoPlayer(outputUrl);
            }
            return;
          } else if (status == 'FAILED') {
            throw Exception('Sync Labs task failed: ${statusData['error'] ?? 'Unknown'}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Polling error: $e');
      }
    }

    throw Exception('Stitching timed out after ${maxAttempts * 5} seconds');
  }

  void _initializeVideoPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController!.initialize().then((_) {
      if (mounted) {
        _videoController!.addListener(() {
          if (mounted) setState(() {});
        });
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    });
  }

  Future<void> _saveVideo() async {
    final provider = context.read<TalkingHeadProvider>();
    if (_stitchedVideoUrl == null) return;

    try {
      if (provider.saveToGallery) {
        await Gal.putVideo(_stitchedVideoUrl!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video saved to gallery!',
                style: AppFonts.poppins(color: AppColors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not authenticated');

        final fileName = 'talking_head_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final path = 'users/${user.uid}/talking_heads/$fileName';

        // Upload video to Firebase
        final videoUrl = await StorageService.uploadVideoFromUrl(_stitchedVideoUrl!, path);

        // Save metadata to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('library')
            .add({
          'type': 'video',
          'url': videoUrl,
          'source': 'talking_head',
          'createdAt': FieldValue.serverTimestamp(),
          'duration': provider.selectedDuration,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video saved to library!',
                style: AppFonts.poppins(color: AppColors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Reset provider and navigate back
      provider.reset();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError('Failed to save: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppFonts.poppins(color: AppColors.white)),
        backgroundColor: Colors.red,
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
          leading: _isStitching || _stitchedVideoUrl != null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            _stitchedVideoUrl != null ? 'TALKING HEAD COMPLETE' : 'STITCHING AUDIO',
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

                if (_isStitching)
                  _buildStitchingState()
                else if (_stitchedVideoUrl != null &&
                    _videoController != null &&
                    _videoController!.value.isInitialized)
                  _buildCompletionState()
                else if (_errorMessage != null)
                  _buildErrorState()
                else
                  _buildInitialState(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.animation,
                size: 80,
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to Stitch',
                style: AppFonts.playfair(
                  size: 32,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your video and audio are ready to be combined with lip sync',
                textAlign: TextAlign.center,
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            label: 'START STITCHING',
            onTap: _startStitching,
          ),
        ),
      ],
    );
  }

  Widget _buildStitchingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
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
            'Stitching Audio...',
            style: AppFonts.poppins(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Syncing lips with audio (up to 10 minutes)',
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionState() {
    return Consumer<TalkingHeadProvider>(
      builder: (context, provider, _) => Column(
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
                                _videoController!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.gold,
                                  bufferedColor: Colors.white30,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: _videoController!,
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
            ),
          ),
          const SizedBox(height: 32),

          // Save option
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'SAVE VIDEO',
              onTap: _saveVideo,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'BACK TO HOME',
              outlined: true,
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
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
            'Stitching Failed',
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
                    setState(() {
                      _errorMessage = null;
                      _stitchedVideoUrl = null;
                    });
                    _startStitching();
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

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
