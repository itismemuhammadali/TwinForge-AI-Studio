import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../models/generated_content.dart';
import '../services/heygen_service.dart';
import '../services/eleven_labs_service.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';

class TalkingHeadScreen extends StatefulWidget {
  final GeneratedContent? content;
  const TalkingHeadScreen({super.key, this.content});
  @override
  State<TalkingHeadScreen> createState() => _TalkingHeadScreenState();
}

class _TalkingHeadScreenState extends State<TalkingHeadScreen> {
  File? _selectedImage;
  String _voiceStyle = StudioOptions.voiceStyles[0];
  final _scriptCtrl = TextEditingController();
  bool _isGenerating = false;
  String? _videoUrl;
  VideoPlayerController? _videoController;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      final url = widget.content!.editedImageUrl ?? widget.content!.originalImageUrl;
      _selectedImage = File(url);
    }
  }

  @override
  void dispose() {
    _scriptCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourceBottomSheet(
        onSourceSelected: (source) async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: source, imageQuality: 90);
          if (picked != null) {
            setState(() => _selectedImage = File(picked.path));
          }
        },
        title: 'UPLOAD FACE IMAGE',
        subtitle: 'Choose a clear front-facing photo',
      ),
    );
  }

  String _mapVoiceStyleToElevenLabsId(String style) {
    switch (style) {
      case 'Natural Female': return '21m00Tcm4TlvDq8ikWAM';
      case 'Natural Male': return 'pNInz6obpgDQGcFmaJgB';
      case 'Confident & Bold': return 'AZnzlk1XvdvUeBnXmlld';
      case 'Soft & Warm': return 'MF3mGyEYCl7XYWbV9V6O';
      case 'Professional Narrator': return 'TxGEqnHWrfWFTfGW9XjX';
      case 'Energetic & Upbeat': return 'VR6AewLTigWG4xSOukaG';
      default: return '21m00Tcm4TlvDq8ikWAM';
    }
  }

  Future<void> _generate() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload an image first', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }
    if (_scriptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write a script', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating audio from script...';
    });

    try {
      // Step 1: Upload image to Firebase Storage
      setState(() => _statusMessage = 'Uploading image...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final imageBytes = await _selectedImage!.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = 'users/${user.uid}/talking_head/$timestamp.jpg';
      final imageUrl = await StorageService.uploadImageBytes(imageBytes, imagePath);

      // Step 2: Generate audio using ElevenLabs
      setState(() => _statusMessage = 'Generating voice with ElevenLabs...');
      final elevenLabs = ElevenLabsService();
      final voiceId = _mapVoiceStyleToElevenLabsId(_voiceStyle);
      final audioDataUrl = await elevenLabs.generateSpeech(
        text: _scriptCtrl.text.trim(),
        voiceId: voiceId,
        stabilityLevel: 0.5,
        similarityBoost: 0.75,
      );

      // Step 3: Upload audio to Firebase Storage
      setState(() => _statusMessage = 'Uploading audio...');
      final audioBytes = Uri.parse(audioDataUrl).data!.contentAsBytes();
      final audioPath = 'users/${user.uid}/talking_head/audio_$timestamp.mp3';
      final audioUrl = await StorageService.uploadAudioBytes(audioBytes, audioPath);

      // Step 4: Create talking head video using HeyGen
      setState(() => _statusMessage = 'Creating talking head video...');
      final heygen = HeyGenService();
      final videoId = await heygen.createPhotoTalkingHeadVideo(
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );

      // Step 5: Poll for video completion
      setState(() => _statusMessage = 'Processing video... This may take a minute.');
      String status = 'processing';
      int attempts = 0;
      while (status == 'processing' && attempts < 60) {
        await Future.delayed(const Duration(seconds: 5));
        attempts++;
        final statusData = await heygen.getVideoStatus(videoId: videoId);
        status = statusData['data']?['status'] ?? statusData['status'] ?? 'processing';
        if (status == 'processing') {
          setState(() => _statusMessage = 'Processing video... ($attempts/60)');
        }
      }

      if (status == 'completed') {
        final statusData = await heygen.getVideoStatus(videoId: videoId);
        final videoDownloadUrl = statusData['data']?['video_url'] ?? statusData['video_url'];
        if (videoDownloadUrl != null) {
          setState(() {
            _videoUrl = videoDownloadUrl;
            _statusMessage = '';
            _isGenerating = false;
          });
          _initVideoPlayer(videoDownloadUrl);
        } else {
          throw Exception('No video URL in completed response');
        }
      } else if (status == 'failed') {
        throw Exception('HeyGen video generation failed');
      } else {
        throw Exception('Video generation timed out after 5 minutes');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: AppFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    setState(() {});
    _videoController!.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: _videoUrl != null ? _buildVideoResult() : _buildInputForm(),
    );
  }

  Widget _buildVideoResult() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _videoController != null && _videoController!.value.isInitialized
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
                        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 30)],
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
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.8)),
                                  child: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.black, size: 30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(color: AppColors.gold),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: GoldButton(
                      label: 'BACK TO HOME',
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TALKING HEAD', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
              const SizedBox(height: 8),
              Text('Create AI Video Messages', style: AppFonts.playfair(size: 32, weight: FontWeight.w900, color: AppColors.white)),
              const SizedBox(height: 6),
              Text('Upload your image, write a script, and generate a complete talking head video with sound',
                  style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.5)),
            ],
          ),
          const SizedBox(height: 32),

          // Step 1 — Upload
          _stepLabel('01', 'Upload Your Image'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity, height: 220,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _selectedImage != null ? AppColors.gold.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.face_outlined, color: AppColors.gold, size: 40),
                      const SizedBox(height: 12),
                      Text('Upload Face Image', style: AppFonts.playfair(size: 18, style: FontStyle.italic, color: AppColors.white)),
                      const SizedBox(height: 6),
                      Text('CLEAR FRONT-FACING PHOTO', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
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
            child: Text('${_scriptCtrl.text.length} / 500 characters', style: AppFonts.poppins(size: 10, color: AppColors.muted)),
          ),

          const SizedBox(height: 32),

          // Status message
          if (_statusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(children: [
                if (_isGenerating) ...[
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(_statusMessage, style: AppFonts.poppins(size: 12, color: AppColors.gold))),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Tech stack info
          if (!_isGenerating) ...[
            DarkCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('POWERED BY', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
                const SizedBox(height: 12),
                _techRow(Icons.mic_outlined, 'ElevenLabs', 'AI Voice Generation'),
                const SizedBox(height: 10),
                _techRow(Icons.videocam_outlined, 'HeyGen', 'Lip Sync & Video'),
              ]),
            ),
            const SizedBox(height: 32),
          ],

          GoldButton(
            label: _isGenerating ? 'GENERATING...' : 'GENERATE VIDEO',
            loading: _isGenerating,
            onTap: _isGenerating ? null : _generate,
          ),

          const SizedBox(height: 40),
        ],
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
      child: Center(child: Text(num, style: AppFonts.poppins(size: 10, weight: FontWeight.w900, color: AppColors.gold))),
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
}
