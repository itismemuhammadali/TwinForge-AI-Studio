import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../services/audio_recording_service.dart';
import '../../utils/permission_helper.dart';
import 'talking_head_stitch_screen.dart';

import 'package:permission_handler/permission_handler.dart';

class TalkingHeadMicrophoneScreen extends StatefulWidget {
  const TalkingHeadMicrophoneScreen({super.key});

  @override
  State<TalkingHeadMicrophoneScreen> createState() =>
      _TalkingHeadMicrophoneScreenState();
}

class _TalkingHeadMicrophoneScreenState
    extends State<TalkingHeadMicrophoneScreen> with WidgetsBindingObserver {
  bool _isRecording = false;
  bool _isPlaying = false;
  VideoPlayerController? _audioPlayerController;
  Duration _recordingDuration = Duration.zero;
  String? _recordedAudioPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialMicPermission();
    });
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
      debugPrint('Mic permission check error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final provider = context.read<TalkingHeadProvider>();
    final maxDuration = provider.selectedDuration;

    try {
      // Check permissions with system prompt & fallback UI
      final hasPermission = await PermissionHelper.checkMicrophonePermission(context);
      if (!hasPermission) return;

      setState(() => _isRecording = true);

      await AudioRecordingService.startRecording(
        maxDurationSeconds: maxDuration,
      );

      // Update duration with 100ms precision and 300ms mic startup latency buffer
      final targetMs = (maxDuration * 1000) + 300;
      int elapsedMs = 0;
      while (_isRecording && mounted && elapsedMs < targetMs) {
        await Future.delayed(const Duration(milliseconds: 100));
        elapsedMs += 100;

        if (mounted) {
          final displaySec = (elapsedMs / 1000).clamp(0, maxDuration.toDouble()).round();
          setState(() => _recordingDuration = Duration(seconds: displaySec));

          // Auto-stop at target max duration
          if (elapsedMs >= targetMs) {
            await _stopRecording();
            break;
          }
        }
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await AudioRecordingService.stopRecording();

      if (mounted) {
        // Calculate actual duration
        final duration = await AudioRecordingService.getRecordedDuration(path);

        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
          _recordingDuration = Duration(seconds: duration);
        });

        // Update provider
        if (!mounted) return;
        context.read<TalkingHeadProvider>().setRecordedAudioUrl(
          path,
          durationSeconds: duration,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Audio recorded successfully (${duration}s)',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await AudioRecordingService.cancelRecording();
      _audioPlayerController?.dispose();
      _audioPlayerController = null;
      setState(() {
        _isRecording = false;
        _isPlaying = false;
        _recordingDuration = Duration.zero;
      });
    } catch (e) {
      _showError('Failed to cancel recording: $e');
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedAudioPath == null) return;
    try {
      if (_audioPlayerController == null) {
        _audioPlayerController =
            VideoPlayerController.file(File(_recordedAudioPath!));
        await _audioPlayerController!.initialize();
        _audioPlayerController!.addListener(() {
          if (mounted && _audioPlayerController != null) {
            final isEnded = _audioPlayerController!.value.position >=
                _audioPlayerController!.value.duration;
            if (isEnded && _isPlaying) {
              setState(() => _isPlaying = false);
            }
          }
        });
      }

      if (_isPlaying) {
        await _audioPlayerController!.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_audioPlayerController!.value.position >=
            _audioPlayerController!.value.duration) {
          await _audioPlayerController!.seekTo(Duration.zero);
        }
        await _audioPlayerController!.play();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      _showError('Audio playback error: $e');
    }
  }

  Future<void> _uploadAudio() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMedia();

      if (result == null) return;
      if (!mounted) return;

      // Check if it's audio
      if (!result.path.endsWith('.mp3') &&
          !result.path.endsWith('.m4a') &&
          !result.path.endsWith('.wav')) {
        _showError('Please select an audio file (mp3, m4a, or wav)');
        return;
      }

      setState(() => _isRecording = true); // Use as loading indicator

      final duration = await AudioRecordingService.getRecordedDuration(result.path);
      if (!mounted) return;

      // Check if audio duration exceeds video duration (with 1s margin for rounding)
      final provider = context.read<TalkingHeadProvider>();
      if (duration > provider.selectedDuration + 1) {
        _showError(
          'Audio duration (${duration}s) exceeds video duration (${provider.selectedDuration}s)',
        );
        setState(() => _isRecording = false);
        return;
      }

      setState(() {
        _recordedAudioPath = result.path;
        _recordingDuration = Duration(seconds: duration);
        _isRecording = false;
      });

      provider.setRecordedAudioUrl(result.path, durationSeconds: duration);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Audio uploaded successfully (${duration}s)',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to upload audio: $e');
      setState(() => _isRecording = false);
    }
  }

  void _proceedToStitch() {
    final provider = context.read<TalkingHeadProvider>();

    if (provider.recordedAudioUrl == null) {
      _showError('Please record or upload audio first');
      return;
    }

    if (provider.recordedAudioDuration > provider.selectedDuration + 1) {
      _showError('Audio duration exceeds video duration');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadStitchScreen(),
      ),
    );
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
          leading: _isRecording || _recordedAudioPath != null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            'RECORD VOICE',
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

                // Duration Limit Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration Limit',
                              style: AppFonts.poppins(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                            Text(
                              'Audio cannot exceed ${provider.selectedDuration} seconds',
                              style: AppFonts.poppins(
                                size: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Recording Section
                if (_recordedAudioPath == null) ...[
                  _buildRecordingOptions(provider),
                ] else ...[
                  _buildAudioPlayback(provider),
                ],

                const SizedBox(height: 32),

                // Action Buttons
                if (_recordedAudioPath != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GoldButton(
                          label: 'RECORD NEW',
                          outlined: true,
                          onTap: () {
                            _recordedAudioPath = null;
                            _recordingDuration = Duration.zero;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GoldButton(
                          label: 'PROCEED',
                          onTap: _proceedToStitch,
                        ),
                      ),
                    ],
                  ),
                ] else if (!_isRecording) ...[
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: 'GO BACK',
                      outlined: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingOptions(TalkingHeadProvider provider) {
    return Column(
      children: [
        // Recording Button
        GestureDetector(
          onTap: _isRecording ? null : _startRecording,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isRecording
                    ? Colors.red.withValues(alpha: 0.4)
                    : AppColors.gold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : AppColors.gold,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? AppColors.white : AppColors.black,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isRecording) ...[
                  Text(
                    '${_recordingDuration.inSeconds} seconds',
                    style: AppFonts.playfair(
                      size: 32,
                      weight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recording... (Max: ${provider.selectedDuration}s)',
                    style: AppFonts.poppins(
                      size: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ] else ...[
                  Text(
                    'TAP TO RECORD',
                    style: AppFonts.poppins(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maximum ${provider.selectedDuration} seconds',
                    style: AppFonts.poppins(
                      size: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (_isRecording) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'STOP RECORDING',
              onTap: _stopRecording,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'CANCEL',
              outlined: true,
              onTap: _cancelRecording,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Divider
        Container(
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.2),
        ),

        const SizedBox(height: 24),

        // Upload Option
        GestureDetector(
          onTap: _isRecording ? null : _uploadAudio,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.gold,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'OR UPLOAD AUDIO',
                  style: AppFonts.poppins(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'mp3, m4a, or wav',
                  style: AppFonts.poppins(
                    size: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayback(TalkingHeadProvider provider) {
    return Container(
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
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AUDIO READY',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w700,
                  color: Colors.green,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Duration: ${_recordingDuration.inSeconds} seconds',
            style: AppFonts.poppins(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Video limit: ${provider.selectedDuration} seconds',
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          // Play Button
          Center(
            child: GestureDetector(
              onTap: _playRecordedAudio,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.black,
                  size: 35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
