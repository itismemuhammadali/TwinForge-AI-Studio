import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  static final AudioRecorder _recorder = AudioRecorder();
  static String? _currentRecordingPath;
  static Duration _recordingDuration = Duration.zero;
  static bool _isRecording = false;

  static void debugLog(String message) {
    developer.log('[AudioRecordingService] $message');
  }

  /// Check if recording is currently active
  static Future<bool> isRecording() async {
    return _isRecording || await _recorder.isRecording();
  }

  /// Start recording audio with max duration limit
  static Future<void> startRecording({
    required int maxDurationSeconds,
  }) async {
    try {
      debugLog('🎤 Starting audio recording (max: ${maxDurationSeconds}s)...');

      // Check permissions
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission denied');
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/audio_$timestamp.m4a';

      debugLog('📁 Recording to: $_currentRecordingPath');

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _recordingDuration = Duration.zero;
      _isRecording = true;
      debugLog('✅ Recording started');
    } catch (e) {
      debugLog('❌ Error starting recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Stop recording and return the file path
  static Future<String> stopRecording() async {
    try {
      debugLog('⏹️ Stopping recording...');

      final path = await _recorder.stop();

      if (path == null) {
        throw Exception('Failed to get recording path');
      }

      _isRecording = false;
      debugLog('✅ Recording stopped: $path');
      return path;
    } catch (e) {
      debugLog('❌ Error stopping recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Get current recording duration
  static Duration getRecordingDuration() {
    return _recordingDuration;
  }

  /// Increment recording duration (call every second)
  static void incrementRecordingDuration() {
    _recordingDuration = _recordingDuration + const Duration(seconds: 1);
  }

  /// Cancel recording (discard)
  static Future<void> cancelRecording() async {
    try {
      debugLog('❌ Canceling recording...');
      await _recorder.stop();

      // Delete the file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugLog('🗑️ Recording file deleted');
        }
      }

      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
      _isRecording = false;
    } catch (e) {
      debugLog('⚠️ Error canceling recording: $e');
    }
  }

  /// Get recording duration from file (rough estimate)
  static Future<int> getRecordedDuration(String filePath) async {
    try {
      debugLog('📊 Calculating duration for: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Estimate duration from file size
      // AAC at 128kbps: duration = (fileSize * 8) / bitRate
      final bytes = await file.length();
      const bitRate = 128000; // 128 kbps
      final durationSeconds = ((bytes * 8) / bitRate).round();

      debugLog('📊 Estimated duration: ${durationSeconds}s');
      return durationSeconds;
    } catch (e) {
      debugLog('⚠️ Error calculating duration: $e');
      return 0;
    }
  }

  /// Dispose recorder
  static Future<void> dispose() async {
    try {
      await _recorder.dispose();
      debugLog('✅ AudioRecorder disposed');
    } catch (e) {
      debugLog('⚠️ Error disposing recorder: $e');
    }
  }

  /// Check microphone permission
  static Future<bool> hasMicrophonePermission() async {
    return await _recorder.hasPermission();
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final hasPermission = await _recorder.hasPermission();
    return hasPermission;
  }
}
