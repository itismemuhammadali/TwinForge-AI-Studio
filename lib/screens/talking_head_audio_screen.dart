import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/fal_ai_service.dart';
import '../services/heygen_service.dart';
import '../services/storage_service.dart';
import '../services/everypixel_ai_service.dart';
import '../utils/permission_helper.dart';
import '../services/credit_service.dart';
import '../models/credit_config.dart';
import 'talking_head_video_review_screen.dart';

class TalkingHeadAudioScreen extends StatefulWidget {
  final String? initialVideoUrl;
  final String? avatarImageUrl;
  final int durationSeconds;
  final String prompt;
  final String videoModel;

  const TalkingHeadAudioScreen({
    super.key,
    this.initialVideoUrl,
    this.avatarImageUrl,
    required this.durationSeconds,
    required this.prompt,
    this.videoModel = 'HeyGen',
  });

  @override
  State<TalkingHeadAudioScreen> createState() => _TalkingHeadAudioScreenState();
}

class _TalkingHeadAudioScreenState extends State<TalkingHeadAudioScreen> with WidgetsBindingObserver {
  late String _currentVideoUrl;
  VideoPlayerController? _videoController;

  // Audio mode: 'audio' (Record/Upload Audio) or 'clone' (Voice Cloning)
  String _audioMode = 'audio';

  // Lip-Sync Engine: 'everypixel' (Everypixel Labs - Ultra Cost Efficient) or 'synclabs' (Sync.so)
  String _lipSyncEngine = 'everypixel';

  bool _isProcessingAudio = false;
  String _statusMessage = '';

  // Audio Recording State
  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _recordedAudioPath;
  String? _uploadedAudioPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  final ValueNotifier<String> _recordingDurationText = ValueNotifier('00:00');

  // Voice Cloning State
  final _cloneScriptCtrl = TextEditingController();
  String? _clonedAudioUrl;
  bool _isCloningVoice = false;

  // Audio Preview Player
  VideoPlayerController? _audioPlayerCtrl;
  bool _isPlayingAudio = false;
  double? _avatarAspectRatio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentVideoUrl = widget.initialVideoUrl ?? '';
    if (_currentVideoUrl.isNotEmpty) {
      _initVideoPlayer(_currentVideoUrl);
    }
    _initRecorder();
    _resolveAvatarAspectRatio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialMicPermission();
    });
  }

  void _resolveAvatarAspectRatio() {
    final url = widget.avatarImageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        final img = NetworkImage(url);
        final stream = img.resolve(const ImageConfiguration());
        stream.addListener(ImageStreamListener((info, _) {
          if (mounted && info.image.height > 0) {
            setState(() {
              _avatarAspectRatio = info.image.width / info.image.height;
            });
          }
        }));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialMicPermission();
    }
  }

  Future<void> _checkInitialMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isDenied) {
        await Permission.microphone.request();
      }
    } catch (e) {
      debugPrint('Initial mic permission check error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cloneScriptCtrl.dispose();
    _recordingDurationText.dispose();

    final vCtrl = _videoController;
    _videoController = null;
    vCtrl?.dispose();

    final aCtrl = _audioPlayerCtrl;
    _audioPlayerCtrl = null;
    aCtrl?.dispose();

    final rec = _audioRecorder;
    _audioRecorder = null;
    rec?.dispose();

    super.dispose();
  }

  Future<void> _initRecorder() async {
    try {
      _audioRecorder ??= AudioRecorder();
    } catch (e) {
      debugPrint('Recorder init error: $e');
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    final oldCtrl = _videoController;
    _videoController = null;
    await oldCtrl?.dispose();

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await ctrl.initialize();
    if (mounted) {
      setState(() {
        _videoController = ctrl;
      });
      ctrl.play();
      ctrl.setLooping(true);
    }
  }

  Future<void> _initAudioPreview(String pathOrUrl) async {
    final oldCtrl = _audioPlayerCtrl;
    _audioPlayerCtrl = null;
    await oldCtrl?.dispose();
    _isPlayingAudio = false;

    try {
      final ctrl = pathOrUrl.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(pathOrUrl))
          : VideoPlayerController.file(File(pathOrUrl));

      await ctrl.initialize();
      ctrl.addListener(() {
        if (mounted) {
          setState(() {
            _isPlayingAudio = ctrl.value.isPlaying;
          });
        }
      });
      if (mounted) {
        setState(() {
          _audioPlayerCtrl = ctrl;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audio preview player: $e');
    }
  }

  Future<void> _toggleAudioPlayback(String pathOrUrl) async {
    if (_audioPlayerCtrl == null) {
      await _initAudioPreview(pathOrUrl);
    }

    if (_audioPlayerCtrl != null && _audioPlayerCtrl!.value.isInitialized) {
      if (_audioPlayerCtrl!.value.isPlaying) {
        await _audioPlayerCtrl!.pause();
      } else {
        await _audioPlayerCtrl!.play();
      }
      setState(() {});
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
      final hasPermission = await PermissionHelper.checkMicrophonePermission(context);
      if (!hasPermission) return;

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/talking_head_mic_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordedAudioPath = path;
      _uploadedAudioPath = null;
      _audioPlayerCtrl?.dispose();
      _audioPlayerCtrl = null;

      _startRecordingTimer();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $e', style: AppFonts.poppins(size: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecordingTimer() {
    _recordingStartTime = DateTime.now();
    final maxSec = widget.durationSeconds;
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_recordingStartTime != null) {
        final d = DateTime.now().difference(_recordingStartTime!);
        final elapsedMs = d.inMilliseconds;
        final displaySec = (elapsedMs / 1000).clamp(0, maxSec.toDouble()).round();
        final m = (displaySec ~/ 60).toString().padLeft(2, '0');
        final s = (displaySec % 60).toString().padLeft(2, '0');
        _recordingDurationText.value = '$m:$s';

        // Include 300ms microphone hardware initialization buffer
        if (elapsedMs >= (maxSec * 1000) + 300) {
          _stopRecording();
        }
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
    if (!_isRecording) return;
    await _audioRecorder?.stop();
    _stopRecordingTimer();
    if (mounted) setState(() => _isRecording = false);

    if (_recordedAudioPath != null) {
      final file = File(_recordedAudioPath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.length < 100) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recording failed. Please try again.', style: AppFonts.poppins(size: 12)),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _recordedAudioPath = null;
          });
          return;
        }

        await _initAudioPreview(_recordedAudioPath!);
        setState(() => _statusMessage = 'Recording ready! (${widget.durationSeconds}s)');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _statusMessage = '');
        });
      }
    }
  }

  bool _isPickingAudio = false;

  Future<void> _pickAudioFromDevice() async {
    if (_isPickingAudio) return;
    _isPickingAudio = true;
    try {
      final hasPermission = await PermissionHelper.checkAudioPermission(context);
      if (!hasPermission) return;

      FilePickerResult? result;
      try {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'caf', 'ogg', 'mp4'],
        );
      } catch (e) {
        debugPrint('Custom file picker failed, trying FileType.audio: $e');
        result = await FilePicker.pickFiles(type: FileType.audio);
      }

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final pickedPath = result.files.first.path!;
        setState(() {
          _uploadedAudioPath = pickedPath;
          _recordedAudioPath = null;
          _statusMessage = 'Audio file selected!';
        });
        await _initAudioPreview(pickedPath);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _statusMessage = '');
        });
      }
    } catch (e) {
      debugPrint('❌ File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick audio: $e', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isPickingAudio = false;
    }
  }

  Future<void> _cloneVoice() async {
    final script = _cloneScriptCtrl.text.trim();
    if (script.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write the script for voice cloning first', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
      );
      return;
    }
    final samplePath = _recordedAudioPath ?? _uploadedAudioPath;
    if (samplePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record or pick a voice sample first', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isCloningVoice = true;
      _statusMessage = 'Cloning voice & generating speech...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';

      final file = File(samplePath);
      final bytes = await file.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadPath = 'users/$uid/talking_head/voice_sample_$timestamp.m4a';
      final voiceSampleUrl = await StorageService.uploadAudioBytes(bytes, uploadPath);

      final fal = FalAiService();
      final generatedAudioUrl = await fal.cloneAndGenerateSpeech(
        voiceSampleUrl: voiceSampleUrl,
        script: script,
      );

      final audioResponse = await http.get(Uri.parse(generatedAudioUrl));
      final audioPath = 'users/$uid/talking_head/cloned_audio_$timestamp.mp3';
      _clonedAudioUrl = await StorageService.uploadAudioBytes(audioResponse.bodyBytes, audioPath);

      await _initAudioPreview(_clonedAudioUrl!);

      setState(() {
        _isCloningVoice = false;
        _statusMessage = 'Voice cloned & speech generated!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _statusMessage = '');
      });
    } catch (e) {
      debugPrint('❌ Voice cloning error: $e');
      setState(() {
        _isCloningVoice = false;
        _statusMessage = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice cloning failed: $e', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stitchAudioWithVideo() async {
    final audioPath = _recordedAudioPath ?? _uploadedAudioPath;
    final activeAudio = _audioMode == 'clone' ? _clonedAudioUrl : null;

    if (activeAudio == null && audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record or select an audio file first', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
      );
      return;
    }

    final requiredCredits = widget.videoModel == 'HeyGen'
        ? CreditConfig.heygenDirectTalkPerSec * widget.durationSeconds
        : CreditConfig.getNaturalTalkCredits(
            movementModel: widget.videoModel,
            durationSec: widget.durationSeconds,
            lipSyncEngine: _lipSyncEngine,
          );

    final hasCredits = await CreditService.ensureSufficientCredits(
      context,
      requiredCredits: requiredCredits,
      featureName: 'Talking Head Generation',
    );
    if (!hasCredits) return;

    setState(() {
      _isProcessingAudio = true;
      _statusMessage = 'Uploading audio file...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String audioUrl = activeAudio ?? '';
      if (audioUrl.isEmpty && audioPath != null) {
        final file = File(audioPath);
        final bytes = await file.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'users/${user.uid}/talking_head/audio_$timestamp.m4a';
        audioUrl = await StorageService.uploadAudioBytes(bytes, storagePath);
      }

      String finalVideoUrl = '';
      String chosenProvider = 'Sync.so';
      if (widget.avatarImageUrl != null && widget.avatarImageUrl!.isNotEmpty && widget.videoModel == 'HeyGen') {
        chosenProvider = 'HeyGen';
        setState(() => _statusMessage = 'Generating talking head video... (approx 2-3 mins)');
        finalVideoUrl = await HeyGenService.generateVideoFromImage(
          imageUrl: widget.avatarImageUrl!,
          prompt: widget.prompt,
          audioUrl: audioUrl,
        );
      } else {
        if (_lipSyncEngine == 'everypixel') {
          chosenProvider = 'Everypixel Labs';
          try {
            setState(() => _statusMessage = 'Stitching audio & lip syncing video...');
            finalVideoUrl = await EverypixelAiService.generateLipSyncVideo(
              videoUrl: _currentVideoUrl,
              audioUrl: audioUrl,
              onProgress: (msg) {
                if (mounted) setState(() => _statusMessage = msg);
              },
            );
          } catch (eEverypixel) {
            debugPrint('⚠️ Everypixel failed ($eEverypixel). Falling back to Sync Labs...');
            chosenProvider = 'Sync.so';
            setState(() => _statusMessage = 'Stitching audio & lip syncing video...');
            finalVideoUrl = await _lipSyncVideo(_currentVideoUrl, audioUrl);
          }
        } else {
          chosenProvider = 'Sync.so';
          setState(() => _statusMessage = 'Stitching audio & premium lip syncing video... (approx 2-3 mins)');
          finalVideoUrl = await _lipSyncVideo(_currentVideoUrl, audioUrl);
        }
      }

      if (mounted) {
        final estUsd = widget.videoModel == 'HeyGen'
            ? CreditConfig.estimateHeyGenCostUsd(widget.durationSeconds)
            : CreditConfig.estimateSyncCostUsd(widget.durationSeconds);

        await CreditService.deductCredits(
          context: context,
          creditsToDeduct: requiredCredits,
          feature: widget.videoModel == 'HeyGen' ? 'heygen_direct_talk' : 'natural_talk_sync',
          estimatedUsdCost: estUsd,
          provider: chosenProvider,
        );

        if (!mounted) return;

        setState(() {
          _currentVideoUrl = finalVideoUrl;
          _isProcessingAudio = false;
          _statusMessage = 'Talking Head generated successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Talking Head generated successfully!', style: AppFonts.poppins(size: 12, color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate forward directly to the Review Screen showing the finished video
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TalkingHeadVideoReviewScreen(
              videoUrl: finalVideoUrl,
              durationSeconds: widget.durationSeconds,
              prompt: widget.prompt,
              hasAudioStitched: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Video generation / Lip sync error: $e');
      setState(() {
        _isProcessingAudio = false;
        _statusMessage = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation error: $e', style: AppFonts.poppins(size: 12)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String> _lipSyncVideo(String videoUrl, String audioUrl) async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    final syncKey = remoteConfig.getString('synclabs_api_key');
    if (syncKey.isEmpty) throw Exception('Sync Labs API key not configured');

    debugPrint('🎬 Starting lip sync with Sync Labs...');
    final response = await http.post(
      Uri.parse('https://api.sync.so/v2/generate'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': syncKey,
      },
      body: jsonEncode({
        'model': 'sync-3',
        'input': [
          {'type': 'video', 'url': videoUrl},
          {'type': 'audio', 'url': audioUrl},
        ],
        'options': {
          'sync_mode': 'loop',
        },
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Sync Labs API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final generationId = data['id'];
    if (generationId == null) throw Exception('No generation ID in Sync Labs response');

    String status = data['status'] ?? 'PENDING';
    int attempts = 0;
    while (status != 'COMPLETED' && status != 'FAILED' && status != 'REJECTED' && attempts < 60) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
      final statusResponse = await http.get(
        Uri.parse('https://api.sync.so/v2/generate/$generationId'),
        headers: {'x-api-key': syncKey},
      );

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        status = statusData['status'] ?? 'PROCESSING';
        debugPrint('📊 Sync Labs status: $status ($attempts/60)');
        if (status == 'PROCESSING' || status == 'PENDING') {
          setState(() => _statusMessage = 'Stitching audio & generating lip sync video...');
        }
      }
    }

    if (status == 'COMPLETED') {
      final finalResponse = await http.get(
        Uri.parse('https://api.sync.so/v2/generate/$generationId'),
        headers: {'x-api-key': syncKey},
      );
      final finalData = jsonDecode(finalResponse.body);
      final outputUrl = finalData['outputUrl'];
      if (outputUrl != null) return outputUrl;
      throw Exception('No output URL in Sync Labs completed response');
    }
    throw Exception(status == 'FAILED' ? 'Lip sync failed' : 'Lip sync timed out');
  }

  Widget _buildLipSyncEngineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIP SYNC QUALITY',
          style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildEngineOption(
                id: 'everypixel',
                title: 'Standard Lip Sync (50% cheaper)',
                subtitle: 'Fast Studio Quality',
                badge: '50% CHEAPER',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildEngineOption(
                id: 'synclabs',
                title: 'Premium Lip Sync',
                subtitle: 'High Precision Studio',
                badge: null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngineOption({
    required String id,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final isSelected = _lipSyncEngine == id;
    return GestureDetector(
      onTap: () {
        if (_isProcessingAudio) return;
        setState(() => _lipSyncEngine = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.gold.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.gold : AppColors.muted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppFonts.poppins(
                      size: 11,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.gold : AppColors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppFonts.poppins(
                size: 9,
                color: isSelected ? Colors.white70 : AppColors.muted.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: AppFonts.poppins(size: 8, weight: FontWeight.w800, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioTab(String mode, String label, IconData icon) {
    final isSelected = _audioMode == mode;
    return GestureDetector(
      onTap: () {
        if (_isProcessingAudio || _isCloningVoice) return;
        setState(() {
          _audioMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.gold.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.gold : AppColors.muted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppFonts.poppins(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.gold : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerCard(String audioPathOrUrl) {
    final hasAudio = audioPathOrUrl.isNotEmpty;
    final isInitialized = _audioPlayerCtrl != null && _audioPlayerCtrl!.value.isInitialized;
    final pos = isInitialized ? _audioPlayerCtrl!.value.position : Duration.zero;
    final dur = isInitialized ? _audioPlayerCtrl!.value.duration : Duration.zero;

    final posStr = '${pos.inMinutes.remainder(60).toString().padLeft(2, '0')}:${pos.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    final durStr = '${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}:${dur.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasAudio ? () => _toggleAudioPlayback(audioPathOrUrl) : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold,
              ),
              child: Icon(
                _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                color: AppColors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recordedAudioPath != null
                      ? 'Recorded Voice'
                      : _uploadedAudioPath != null
                          ? 'Audio File Loaded'
                          : 'Cloned Speech Audio',
                  style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$posStr / $durStr',
                  style: AppFonts.poppins(size: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () {
              setState(() {
                _recordedAudioPath = null;
                _uploadedAudioPath = null;
                _clonedAudioUrl = null;
                _audioPlayerCtrl?.dispose();
                _audioPlayerCtrl = null;
                _isPlayingAudio = false;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAudio = _audioMode == 'clone'
        ? _clonedAudioUrl
        : (_recordedAudioPath ?? _uploadedAudioPath);

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
          'TALKING HEAD REVIEW',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // 1. TOP VIDEO / AVATAR PREVIEW (DYNAMIC ASPECT RATIO FRAME)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 200,
                  maxHeight: 400,
                ),
                child: (_videoController != null && _videoController!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
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
                                    width: _videoController!.value.size.width > 0
                                        ? _videoController!.value.size.width
                                        : 1280,
                                    height: _videoController!.value.size.height > 0
                                        ? _videoController!.value.size.height
                                        : 720,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                          ? _videoController!.pause()
                                          : _videoController!.play();
                                    });
                                  },
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.gold.withValues(alpha: 0.8),
                                    ),
                                    child: Icon(
                                      _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: AppColors.black,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : (widget.avatarImageUrl != null && widget.avatarImageUrl!.isNotEmpty)
                        ? AspectRatio(
                            aspectRatio: _avatarAspectRatio ?? (3 / 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF141410),
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
                                child: Image.network(
                                  widget.avatarImageUrl!,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppColors.surface,
                                    child: const Center(child: Icon(Icons.person, color: AppColors.gold, size: 50)),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: 260,
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

            // 2. AUDIO OPTIONS SELECTOR
            Text('ADD / STITCH AUDIO', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _buildAudioTab('audio', 'Your Audio', Icons.mic)),
                  Expanded(child: _buildAudioTab('clone', 'Voice Cloning', Icons.record_voice_over)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_audioMode == 'audio') ...[
              // MODE A: YOUR AUDIO (MIC OR PICK FILE)
              Text('RECORD OR PICK AUDIO', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
              const SizedBox(height: 6),
              Text('Record audio (max ${widget.durationSeconds}s, matches video) or select an audio file.', style: AppFonts.poppins(size: 11, color: AppColors.muted.withValues(alpha: 0.7))),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: _isProcessingAudio ? null : _toggleRecording,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red.withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.1),
                      border: Border.all(color: _isRecording ? Colors.red : AppColors.gold.withValues(alpha: 0.5), width: _isRecording ? 3 : 1.5),
                      boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isRecording ? Icons.stop_rounded : Icons.mic, color: _isRecording ? Colors.red : AppColors.gold, size: 32),
                        if (_isRecording) ...[
                          const SizedBox(height: 2),
                          ValueListenableBuilder<String>(
                            valueListenable: _recordingDurationText,
                            builder: (context, value, _) => Text(value, style: AppFonts.poppins(size: 10, color: Colors.red, weight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Opacity(
                opacity: _isRecording ? 0.3 : 1.0,
                child: GestureDetector(
                  onTap: (_isProcessingAudio || _isRecording) ? null : _pickAudioFromDevice,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.audio_file_outlined, color: AppColors.muted, size: 18),
                        const SizedBox(width: 8),
                        Text('SELECT AUDIO FILE FROM DEVICE', style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // MODE B: VOICE CLONING
              Text('VOICE CLONING SCRIPT', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
              const SizedBox(height: 8),
              TextField(
                controller: _cloneScriptCtrl,
                maxLines: 3,
                style: AppFonts.poppins(size: 13, color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Write what your AI twin will say...',
                  hintStyle: AppFonts.poppins(size: 12, color: AppColors.muted.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              Text('RECORD VOICE SAMPLE', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 2)),
              const SizedBox(height: 6),
              Text('Record your voice sample (max ${widget.durationSeconds}s).', style: AppFonts.poppins(size: 11, color: AppColors.muted.withValues(alpha: 0.7))),
              const SizedBox(height: 12),

              Center(
                child: GestureDetector(
                  onTap: (_isProcessingAudio || _isCloningVoice) ? null : _toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red.withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.1),
                      border: Border.all(color: _isRecording ? Colors.red : AppColors.gold.withValues(alpha: 0.5), width: _isRecording ? 3 : 1.5),
                    ),
                    child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic, color: _isRecording ? Colors.red : AppColors.gold, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (_clonedAudioUrl == null)
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: _isCloningVoice ? 'CLONING VOICE...' : 'CLONE VOICE & GENERATE SPEECH',
                    loading: _isCloningVoice,
                    onTap: (_isCloningVoice || _isRecording) ? null : _cloneVoice,
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // AUDIO PREVIEW PLAYER CARD (Shown ONLY when recording is complete)
            if (activeAudio != null && !_isRecording) ...[
              _buildAudioPlayerCard(activeAudio),
              const SizedBox(height: 16),
            ],

            // LIP SYNC ENGINE SELECTOR (For Seedance / Kling / Custom Video Stitches)
            if (widget.videoModel != 'HeyGen') ...[
              _buildLipSyncEngineSelector(),
              const SizedBox(height: 20),
            ],

            // GUIDANCE & PROGRESS BOX (Like video story creation screen)
            if (_isProcessingAudio) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.gold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage.isNotEmpty ? _statusMessage : 'Processing Talking Head video...',
                            style: AppFonts.poppins(size: 12, weight: FontWeight.w600, color: AppColors.gold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white70, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please wait: Creating your video can take 2 to 3 minutes. Do not close the app or move back.',
                            style: AppFonts.poppins(size: 11, color: Colors.white70, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.gold, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: AppFonts.poppins(size: 11, color: AppColors.gold, weight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // STATIC WARNING BOX BEFORE GENERATION
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.gold, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please wait: Creating your video can take 2 to 3 minutes. Do not close the app or move back.',
                        style: AppFonts.poppins(size: 11, color: Colors.white70, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // STITCH / LIP SYNC BUTTON (ONLY BUTTON ON THIS SCREEN)
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: _isProcessingAudio
                    ? 'GENERATING TALKING HEAD...'
                    : (widget.avatarImageUrl != null && widget.avatarImageUrl!.isNotEmpty
                        ? 'GENERATE TALKING HEAD VIDEO'
                        : 'STITCH AUDIO WITH VIDEO'),
                loading: _isProcessingAudio,
                onTap: (_isProcessingAudio || _isRecording || _isCloningVoice || activeAudio == null)
                    ? null
                    : () async {
                        await _stitchAudioWithVideo();
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
