import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gal/gal.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../services/heygen_service.dart';
import '../services/fal_ai_service.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';

class TalkingHeadCreationScreen extends StatefulWidget {
  final GeneratedContent content;
  const TalkingHeadCreationScreen({super.key, required this.content});

  @override
  State<TalkingHeadCreationScreen> createState() => _TalkingHeadCreationScreenState();
}

class _TalkingHeadCreationScreenState extends State<TalkingHeadCreationScreen> {
  final _scriptCtrl = TextEditingController();
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _saveToGallery = false;
  String? _videoUrl;
  VideoPlayerController? _videoController;
  String _statusMessage = '';
  bool _useRecordedVoice = true;
  bool _isRecording = false;
  String? _recordedAudioPath;
  String? _clonedVoiceId;
  bool _isCloning = false;

  AudioRecorder? _audioRecorder;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  final ValueNotifier<String> _recordingDurationText = ValueNotifier('00:00');
  late final Widget _cachedImage;
  String? _clonedAudioUrl;

  @override
  void initState() {
    super.initState();
    _useRecordedVoice = true;
    _cachedImage = _buildImageDisplay();
    _initRecorder();
  }

  @override
  void dispose() {
    _scriptCtrl.dispose();
    _videoController?.dispose();
    _recordingTimer?.cancel();
    _recordingDurationText.dispose();
    if (_isRecording) {
      _audioRecorder?.stop();
    }
    _audioRecorder?.dispose();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    try {
      _audioRecorder ??= AudioRecorder();
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission is required to record your voice', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Recorder init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voice recording is not available on the iOS Simulator. Please test on a real device.',
              style: AppFonts.poppins(size: 12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission is required', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_sample.m4a';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordedAudioPath = path;
      _startRecordingTimer();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voice recording is not available on the iOS Simulator. Please test on a real device.',
              style: AppFonts.poppins(size: 12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecordingTimer() {
    _recordingStartTime = DateTime.now();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartTime != null) {
        final d = DateTime.now().difference(_recordingStartTime!);
        final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
        _recordingDurationText.value = '$m:$s';
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingStartTime = null;
    _recordingDurationText.value = '00:00';
  }

  Future<void> _stopRecording() async {
    await _audioRecorder?.stop();
    _stopRecordingTimer();
    if (mounted) setState(() => _isRecording = false);

    if (_recordedAudioPath != null) {
      final file = File(_recordedAudioPath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.length < 1000) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recording too short. Please record at least 3 seconds.', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
            );
          }
          setState(() {
            _recordedAudioPath = null;
            _useRecordedVoice = false;
          });
          return;
        }

        setState(() => _statusMessage = 'Recording saved. Enter your script and tap Clone Voice.');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _statusMessage = '');
        });
      }
    }
  }

  Future<void> _cloneVoice() async {
    final script = _scriptCtrl.text.trim();
    if (script.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write your script first', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
      );
      return;
    }
    if (_recordedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record your voice first', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isCloning = true;
      _statusMessage = 'Cloning your voice and generating speech...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';

      // Upload the recorded audio to get a URL
      final file = File(_recordedAudioPath!);
      final bytes = await file.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadPath = 'users/$uid/talking_head/voice_sample_$timestamp.m4a';
      final voiceSampleUrl = await StorageService.uploadAudioBytes(bytes, uploadPath);

      // Send to Fal AI for voice cloning + speech generation
      final fal = FalAiService();
      final generatedAudioUrl = await fal.cloneAndGenerateSpeech(
        voiceSampleUrl: voiceSampleUrl,
        script: script,
      );

      // Save the generated audio
      final audioResponse = await http.get(Uri.parse(generatedAudioUrl));
      final audioPath = 'users/$uid/talking_head/cloned_audio_$timestamp.mp3';
      _clonedAudioUrl = await StorageService.uploadAudioBytes(audioResponse.bodyBytes, audioPath);
      debugPrint('✅ Cloned audio saved: $_clonedAudioUrl');

      setState(() {
        _isCloning = false;
        _clonedVoiceId = 'fal_voice_clone';
        _clonedAudioUrl = _clonedAudioUrl;
        _statusMessage = 'Voice cloned and speech ready!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _statusMessage = '');
      });
    } catch (e) {
      debugPrint('❌ Voice cloning error: $e');
      setState(() {
        _isCloning = false;
        _clonedVoiceId = null;
        _statusMessage = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice cloning failed: $e', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
        );
      }
    }
  }

  String get _imageUrl =>
      widget.content.editedImageUrl ?? widget.content.originalImageUrl;

  Future<void> _generateTalkingHead() async {
    if (_scriptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write a script', style: AppFonts.poppins(size: 12, color: AppColors.text)), backgroundColor: AppColors.surface),
      );
      return;
    }

    if (_useRecordedVoice && _recordedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record your voice first', style: AppFonts.poppins(size: 12, color: AppColors.text)), backgroundColor: AppColors.surface),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Uploading image...';
    });

    debugPrint('🎬 _generateTalkingHead: _useRecordedVoice=$_useRecordedVoice, _clonedAudioUrl=$_clonedAudioUrl, _clonedVoiceId=$_clonedVoiceId, _recordedAudioPath=$_recordedAudioPath');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      setState(() => _statusMessage = 'Uploading image...');
      final imageUrl = await _uploadImageToStorage();

      String audioUrl = '';
      if (_clonedAudioUrl != null && _clonedAudioUrl!.isNotEmpty) {
        // Use the pre-cloned audio from recording time
        setState(() => _statusMessage = 'Using your cloned voice...');
        audioUrl = _clonedAudioUrl!;
        debugPrint('✅ Using pre-cloned audio: $audioUrl');
      } else if (_useRecordedVoice && _recordedAudioPath != null) {
        // Fallback: use the raw recording directly
        setState(() => _statusMessage = 'Using your recorded voice...');
        final recordedFile = File(_recordedAudioPath!);
        final recordedBytes = await recordedFile.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final audioPath = 'users/${user.uid}/talking_head/recorded_$timestamp.m4a';
        audioUrl = await StorageService.uploadAudioBytes(recordedBytes, audioPath);
      }

      setState(() => _statusMessage = 'Creating talking head video...');
      final heygen = HeyGenService();
      final videoId = await heygen.createPhotoTalkingHeadVideo(
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );

      setState(() => _statusMessage = 'Processing video... This may take a minute.');
      String status = 'processing';
      int attempts = 0;
      while ((status == 'processing' || status == 'pending') && attempts < 60) {
        await Future.delayed(const Duration(seconds: 5));
        attempts++;
        final statusData = await heygen.getVideoStatus(videoId: videoId);
        status = statusData['data']?['status'] ?? statusData['status'] ?? 'processing';
        if (status == 'processing' || status == 'pending') {
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
      } else {
        throw Exception(status == 'failed' ? 'HeyGen video generation failed' : 'Video generation timed out');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isGenerating = false; _statusMessage = ''; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> _uploadImageToStorage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = 'users/${user.uid}/talking_head/$timestamp.jpg';

    if (_imageUrl.startsWith('http')) {
      final response = await http.get(Uri.parse(_imageUrl));
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      return await StorageService.uploadImage(tempFile, imagePath);
    } else if (_imageUrl.startsWith('data:image')) {
      final base64Str = _imageUrl.split(',')[1];
      final bytes = base64Decode(base64Str);
      return await StorageService.uploadImageBytes(bytes, imagePath);
    } else {
      final file = File(_imageUrl);
      return await StorageService.uploadImage(file, imagePath);
    }
  }

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
            SnackBar(content: Text('Video saved to gallery!', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: const Color(0xFF2a5a2a)),
          );
        }
      } else {
        final fileName = 'talking_head_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final path = 'users/${user.uid}/generatedVideos/$fileName';
        final savedUrl = await StorageService.downloadAndSaveVideo(_videoUrl!, path);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('library').add({
          'type': 'video',
          'url': savedUrl,
          'source': 'talking_head',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video saved to library!', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: const Color(0xFF2a5a2a)),
          );
        }
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _videoUrl != null ? 'TALKING HEAD REVIEW' : 'CREATE TALKING HEAD',
          style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: _videoUrl != null ? _buildVideoResult() : _buildCreationForm(),
    );
  }

  Widget _buildCreationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // PHASE 1: Image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 1)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _cachedImage,
            ),
          ),
          const SizedBox(height: 28),

          // PHASE 2: Script + Voice Clone
          if (_clonedVoiceId == null) ...[
            // Script input
            Text('YOUR SCRIPT', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
            const SizedBox(height: 12),
            TextField(
              controller: _scriptCtrl,
              maxLines: 5,
              style: AppFonts.poppins(size: 13, color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Write what your AI twin will say...',
                hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Voice recording
            Text('RECORD YOUR VOICE', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(
              'Record a 3-10 second sample. Then tap Clone Voice.',
              style: AppFonts.poppins(size: 11, color: AppColors.muted.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: (_isGenerating || _isCloning) ? null : _toggleRecording,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red.withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _isRecording ? Colors.red : AppColors.gold.withValues(alpha: 0.5),
                    width: _isRecording ? 3 : 1.5,
                  ),
                  boxShadow: _isRecording
                      ? [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic,
                      color: _isRecording ? Colors.red : AppColors.gold,
                      size: 40,
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: _recordingDurationText,
                        builder: (context, value, _) => Text(
                          value,
                          style: AppFonts.poppins(size: 11, color: Colors.red, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isRecording)
              Text('Tap to stop recording', style: AppFonts.poppins(size: 11, color: Colors.red.withValues(alpha: 0.7)))
            else if (_recordedAudioPath != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: const Color(0xFF2a5a2a), size: 16),
                  const SizedBox(width: 6),
                  Text('Recording ready!', style: AppFonts.poppins(size: 12, color: const Color(0xFF2a5a2a), weight: FontWeight.w600)),
                ],
              )
            else
              Text('Tap the mic to start recording', style: AppFonts.poppins(size: 11, color: AppColors.muted.withValues(alpha: 0.6))),
            const SizedBox(height: 20),

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
                  if (_isCloning || _isGenerating) ...[
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Text(_statusMessage, style: AppFonts.poppins(size: 12, color: AppColors.gold))),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Clone Voice button
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: _isCloning ? 'CLONING VOICE...' : 'CLONE VOICE',
                loading: _isCloning || _isGenerating,
                onTap: (_isCloning || _isGenerating) ? null : _cloneVoice,
              ),
            ),
          ] else ...[
            // PHASE 3: Voice cloned - show create button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2a5a2a).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2a5a2a).withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: const Color(0xFF2a5a2a), size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voice Cloned & Speech Ready', style: AppFonts.poppins(size: 13, color: const Color(0xFF2a5a2a), weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Your voice has been cloned and the speech audio is generated.', style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: _isGenerating ? 'CREATING VIDEO...' : 'CREATE TALKING HEAD',
                loading: _isGenerating,
                onTap: _isGenerating ? null : _generateTalkingHead,
              ),
            ),
          ],
          const SizedBox(height: 16),

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
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
                        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 1)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
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
              GestureDetector(
                onTap: () => setState(() => _saveToGallery = !_saveToGallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _saveToGallery ? AppColors.gold : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _saveToGallery ? AppColors.gold : AppColors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: _saveToGallery ? const Icon(Icons.check, color: AppColors.black, size: 14) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Save to Gallery', style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.white)),
                        Text(_saveToGallery ? 'Download to your device' : 'Upload to your Twinora library', style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                      ],
                    )),
                    Icon(_saveToGallery ? Icons.download : Icons.cloud_upload, color: AppColors.gold.withValues(alpha: 0.6), size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GoldButton(label: _isSaving ? 'SAVING...' : 'SAVE VIDEO', loading: _isSaving, onTap: _isSaving ? null : _saveVideo)),
                const SizedBox(width: 12),
                Expanded(child: GoldButton(label: 'REGENERATE', outlined: true, onTap: () {
                  setState(() { _videoUrl = null; _videoController?.dispose(); _videoController = null; });
                })),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageDisplay() {
    if (_imageUrl.startsWith('data:image')) {
      try {
        final base64Str = _imageUrl.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, height: 300, width: double.infinity);
      } catch (e) {
        return _imagePlaceholder();
      }
    } else if (_imageUrl.startsWith('https://')) {
      return Image.network(
        _imageUrl,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => Container(
    height: 300,
    color: AppColors.surface,
    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.muted, size: 60),
  );
}
