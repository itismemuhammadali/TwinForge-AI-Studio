import 'package:flutter/material.dart';

/// Utility functions for Talking Heads workflow
class TalkingHeadUtils {
  /// Format duration for display
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  /// Format duration in seconds to readable string
  static String formatSeconds(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Validate video prompt
  static String? validateVideoPrompt(String prompt) {
    if (prompt.isEmpty) {
      return 'Please enter a video prompt';
    }
    if (prompt.length < 10) {
      return 'Prompt must be at least 10 characters';
    }
    if (prompt.length > 500) {
      return 'Prompt cannot exceed 500 characters';
    }
    return null;
  }

  /// Validate audio duration against video duration
  static bool isAudioDurationValid(int audioDuration, int videoDuration) {
    return audioDuration <= videoDuration;
  }

  /// Get duration difference
  static int getDurationDifference(int audioDuration, int videoDuration) {
    return videoDuration - audioDuration;
  }

  /// Check if duration is within acceptable range
  static bool isDurationInRange(int duration) {
    return duration >= 1 && duration <= 15;
  }

  /// Get friendly error message
  static String getFriendlyErrorMessage(String error) {
    if (error.contains('Permission denied')) {
      return 'Microphone permission is required to record audio';
    } else if (error.contains('Sync Labs')) {
      return 'Failed to sync lips with audio. Please try again.';
    } else if (error.contains('timeout') || error.contains('Timeout')) {
      return 'Operation timed out. Please check your internet connection.';
    } else if (error.contains('Firebase')) {
      return 'Failed to save video. Please try again.';
    } else if (error.contains('duration')) {
      return 'Audio duration must match video duration';
    }
    return 'An error occurred. Please try again.';
  }

  /// Validate file size
  static bool isFileSizeValid(int fileSize, int maxMB) {
    final maxBytes = maxMB * 1024 * 1024;
    return fileSize <= maxBytes;
  }

  /// Get file size in MB
  static double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  /// Generate unique file name
  static String generateUniqueFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }

  /// Validate script for voice cloning
  static String? validateVoiceScript(String script) {
    if (script.isEmpty) {
      return 'Please enter a script';
    }
    if (script.length < 10) {
      return 'Script must be at least 10 characters';
    }
    if (script.length > 1000) {
      return 'Script cannot exceed 1000 characters';
    }
    return null;
  }

  /// Estimate character count to words for audio generation
  /// Rough estimation: 1 word ≈ 5 characters, speaking rate ≈ 150 words/minute
  static int estimateAudioDurationFromText(String text) {
    final words = text.split(' ').length;
    final speakingRatePerSecond = 150 / 60; // words per second
    return (words / speakingRatePerSecond).ceil();
  }

  /// Check if text will fit in given duration
  static bool willTextFitInDuration(String text, int durationSeconds) {
    final estimatedDuration = estimateAudioDurationFromText(text);
    return estimatedDuration <= durationSeconds;
  }

  /// Get warning if text might be too long
  static String? getTextDurationWarning(String text, int durationSeconds) {
    final estimatedDuration = estimateAudioDurationFromText(text);
    if (estimatedDuration > durationSeconds) {
      final excess = estimatedDuration - durationSeconds;
      return 'Your text will take approximately ${estimatedDuration}s to speak, which is ${excess}s longer than your video duration.';
    }
    return null;
  }

  /// Get color based on audio duration vs video duration
  static Color getDurationStatusColor(int audioDuration, int videoDuration) {
    if (audioDuration == 0) {
      return Colors.grey;
    }
    if (audioDuration > videoDuration) {
      return Colors.red;
    }
    if (audioDuration > (videoDuration * 0.9)) {
      return Colors.orange;
    }
    return Colors.green;
  }

  /// Format bytes to readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Debug log helper
  static void debugLog(String tag, String message) {
    debugPrint('[$tag] $message');
  }
}
