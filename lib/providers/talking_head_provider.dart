import 'dart:io';
import 'package:flutter/foundation.dart';

enum VoiceMode {
  cloning,
  microphone,
}

class TalkingHeadProvider extends ChangeNotifier {
  // ==================== Image Selection ====================
  File? _selectedImage;
  String? _selectedImageUrl; // For library images (already URLs)

  // ==================== Video Settings ====================
  int _selectedDuration = 8; // 1-15 seconds
  String _videoPrompt = '';
  String? _generatedVideoUrl;
  bool _isGeneratingVideo = false;

  // ==================== Voice Mode Selection ====================
  VoiceMode? _voiceMode;

  // ==================== Voice Cloning ====================
  File? _voiceSampleFile;
  String _voiceScript = '';
  String? _generatedVoiceUrl;
  bool _isGeneratingVoice = false;

  // ==================== Microphone Recording ====================
  String? _recordedAudioUrl; // Local file path during recording
  int _recordedAudioDuration = 0;
  String? _uploadedAudioUrl; // Firebase URL after upload
  bool _isRecordingAudio = false;

  // ==================== Final Stitching ====================
  String? _stitchedVideoUrl;
  bool _saveToGallery = false;
  bool _isStitching = false;

  // ==================== Getters ====================
  File? get selectedImage => _selectedImage;
  String? get selectedImageUrl => _selectedImageUrl;
  int get selectedDuration => _selectedDuration;
  String get videoPrompt => _videoPrompt;
  String? get generatedVideoUrl => _generatedVideoUrl;
  bool get isGeneratingVideo => _isGeneratingVideo;

  VoiceMode? get voiceMode => _voiceMode;

  File? get voiceSampleFile => _voiceSampleFile;
  String get voiceScript => _voiceScript;
  String? get generatedVoiceUrl => _generatedVoiceUrl;
  bool get isGeneratingVoice => _isGeneratingVoice;

  String? get recordedAudioUrl => _recordedAudioUrl;
  int get recordedAudioDuration => _recordedAudioDuration;
  String? get uploadedAudioUrl => _uploadedAudioUrl;
  bool get isRecordingAudio => _isRecordingAudio;

  String? get stitchedVideoUrl => _stitchedVideoUrl;
  bool get saveToGallery => _saveToGallery;
  bool get isStitching => _isStitching;

  // ==================== Setters ====================

  /// Set selected image from gallery or file picker
  void setSelectedImage(File image) {
    _selectedImage = image;
    _selectedImageUrl = null;
    notifyListeners();
  }

  /// Set selected image from library (already a URL)
  void setSelectedImageUrl(String url) {
    _selectedImageUrl = url;
    _selectedImage = null;
    notifyListeners();
  }

  /// Set video duration (1-15 seconds)
  void setDuration(int seconds) {
    if (seconds >= 1 && seconds <= 15) {
      _selectedDuration = seconds;
      notifyListeners();
    }
  }

  /// Set video prompt
  void setVideoPrompt(String prompt) {
    _videoPrompt = prompt;
    notifyListeners();
  }

  /// Set generated video URL and mark as complete
  void setGeneratedVideoUrl(String url) {
    _generatedVideoUrl = url;
    _isGeneratingVideo = false;
    notifyListeners();
  }

  /// Mark video generation as in progress
  void setIsGeneratingVideo(bool value) {
    _isGeneratingVideo = value;
    notifyListeners();
  }

  /// Set voice mode (cloning or microphone)
  void setVoiceMode(VoiceMode mode) {
    _voiceMode = mode;
    notifyListeners();
  }

  /// Set voice sample file for cloning
  void setVoiceSampleFile(File file) {
    _voiceSampleFile = file;
    notifyListeners();
  }

  /// Set voice script for cloning
  void setVoiceScript(String script) {
    _voiceScript = script;
    notifyListeners();
  }

  /// Set generated voice URL
  void setGeneratedVoiceUrl(String url) {
    _generatedVoiceUrl = url;
    _isGeneratingVoice = false;
    notifyListeners();
  }

  /// Mark voice generation as in progress
  void setIsGeneratingVoice(bool value) {
    _isGeneratingVoice = value;
    notifyListeners();
  }

  /// Set recorded audio URL (local file path) and duration
  void setRecordedAudioUrl(String url, {required int durationSeconds}) {
    _recordedAudioUrl = url;
    _recordedAudioDuration = durationSeconds;
    notifyListeners();
  }

  /// Set uploaded audio URL (Firebase)
  void setUploadedAudioUrl(String url) {
    _uploadedAudioUrl = url;
    notifyListeners();
  }

  /// Mark audio recording as in progress
  void setIsRecordingAudio(bool value) {
    _isRecordingAudio = value;
    notifyListeners();
  }

  /// Set stitched video URL
  void setStitchedVideoUrl(String url) {
    _stitchedVideoUrl = url;
    _isStitching = false;
    notifyListeners();
  }

  /// Mark stitching as in progress
  void setIsStitching(bool value) {
    _isStitching = value;
    notifyListeners();
  }

  /// Set save to gallery preference
  void setSaveToGallery(bool value) {
    _saveToGallery = value;
    notifyListeners();
  }

  /// Reset all data (after saving)
  void reset() {
    _selectedImage = null;
    _selectedImageUrl = null;
    _selectedDuration = 8;
    _videoPrompt = '';
    _generatedVideoUrl = null;
    _isGeneratingVideo = false;
    _voiceMode = null;
    _voiceSampleFile = null;
    _voiceScript = '';
    _generatedVoiceUrl = null;
    _isGeneratingVoice = false;
    _recordedAudioUrl = null;
    _recordedAudioDuration = 0;
    _uploadedAudioUrl = null;
    _isRecordingAudio = false;
    _stitchedVideoUrl = null;
    _saveToGallery = false;
    _isStitching = false;
    notifyListeners();
  }

  /// Check if ready to generate video
  bool get canGenerateVideo => _selectedImage != null || _selectedImageUrl != null;

  /// Check if ready to proceed to voice
  bool get canProceedToVoice => _generatedVideoUrl != null;

  /// Check if audio is ready for stitching
  bool get isAudioReady =>
      (_recordedAudioUrl != null && _recordedAudioDuration > 0) ||
      _generatedVoiceUrl != null;

  /// Get final audio URL (either recorded or generated)
  String? get finalAudioUrl => _uploadedAudioUrl ?? _recordedAudioUrl ?? _generatedVoiceUrl;

  /// Get final video URL for stitching
  String? get finalVideoUrl => _generatedVideoUrl;

  /// Check if ready for stitching
  bool get canStitch => _generatedVideoUrl != null && isAudioReady;
}
