import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class PermissionHelper {
  /// Prompts the user for initial permissions (Photos, Storage, Camera, Microphone, Audio, Videos, Notifications) on app startup.
  /// Works seamlessly on both iOS and Android.
  static Future<void> requestStartupPermissions() async {
    try {
      // Explicitly check & request microphone permission on app startup so iOS registers the capability
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }

      // Explicitly check & request Media Library / Audio permission on app startup so iOS registers the capability
      final mediaStatus = await Permission.mediaLibrary.status;
      if (!mediaStatus.isGranted) {
        await Permission.mediaLibrary.request();
      }

      final permissions = <Permission>[
        Permission.photos,
        Permission.storage,
        Permission.camera,
        Permission.audio,
        Permission.videos,
        Permission.notification,
        Permission.mediaLibrary,
      ];
      
      // Explicitly request permissions in batch sequence
      await permissions.request();
    } catch (e) {
      debugPrint('Error requesting startup permissions: $e');
    }
  }

  /// Checks permission before picking an image or using camera.
  /// Explicitly requests permission if not yet granted.
  static Future<bool> checkImagePermission(BuildContext context, ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (status.isGranted) return true;

        var result = await Permission.camera.request();
        if (result.isGranted) return true;

        if (context.mounted && result.isPermanentlyDenied) {
          handlePermissionError(context, 'camera', source);
        }
        return false;
      } else {
        // Photos / Storage
        var photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted || photosStatus.isLimited) return true;

        var photosResult = await Permission.photos.request();
        if (photosResult.isGranted || photosResult.isLimited) return true;

        // Try storage permission for Android 12 and below
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;

        var storageResult = await Permission.storage.request();
        if (storageResult.isGranted) return true;

        if (context.mounted && (photosResult.isPermanentlyDenied || storageResult.isPermanentlyDenied)) {
          handlePermissionError(context, 'photos', source);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      return true; // Fallback to let ImagePicker handle platform dialogs safely
    }
  }

  /// Checks microphone permission for voice recording.
  static Future<bool> checkMicrophonePermission(BuildContext context) async {
    try {
      var status = await Permission.microphone.status;
      if (status.isGranted) return true;

      var result = await Permission.microphone.request();
      if (result.isGranted) return true;

      if (context.mounted && result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Microphone permission is required to record voice samples. Please enable it in Settings.',
              style: AppFonts.poppins(size: 12, color: AppColors.white),
            ),
            action: SnackBarAction(
              label: 'SETTINGS',
              textColor: AppColors.gold,
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Microphone permission check error: $e');
      return false;
    }
  }

  /// Checks audio permission for picking or using audio files.
  static Future<bool> checkAudioPermission(BuildContext context) async {
    try {
      var mediaStatus = await Permission.mediaLibrary.status;
      if (mediaStatus.isGranted) return true;

      var mediaResult = await Permission.mediaLibrary.request();
      if (mediaResult.isGranted) return true;

      var audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) return true;

      var audioResult = await Permission.audio.request();
      if (audioResult.isGranted) return true;

      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      var storageResult = await Permission.storage.request();
      if (storageResult.isGranted) return true;

      if (context.mounted && (mediaResult.isPermanentlyDenied || audioResult.isPermanentlyDenied || storageResult.isPermanentlyDenied)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Audio & Media Library permission is required to access audio files. Please enable it in Settings.',
              style: AppFonts.poppins(size: 12, color: AppColors.white),
            ),
            action: SnackBarAction(
              label: 'SETTINGS',
              textColor: AppColors.gold,
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Audio permission check error: $e');
      return true; // Fallback to let system file picker handle safely
    }
  }

  /// Displays user-friendly SnackBar with direct SETTINGS button if permission is permanently denied
  static void handlePermissionError(BuildContext context, dynamic error, ImageSource source) {
    final isCamera = source == ImageSource.camera;
    final permissionName = isCamera ? 'Camera' : 'Photo Gallery';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          '$permissionName permission is required. Please grant permission in Settings.',
          style: AppFonts.poppins(size: 12, color: AppColors.white),
        ),
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: AppColors.gold,
          onPressed: () => openAppSettings(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Checks permission before saving images/videos to gallery
  static Future<bool> checkSavePermission(BuildContext context) async {
    try {
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) return true;

      var photosResult = await Permission.photos.request();
      if (photosResult.isGranted || photosResult.isLimited) return true;

      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      var storageResult = await Permission.storage.request();
      if (storageResult.isGranted) return true;

      if (context.mounted && (photosResult.isPermanentlyDenied || storageResult.isPermanentlyDenied)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text(
              'Permission is required to save photos/videos to your gallery. Please grant access in Settings.',
              style: AppFonts.poppins(size: 12, color: AppColors.white),
            ),
            action: SnackBarAction(
              label: 'SETTINGS',
              textColor: AppColors.gold,
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Save permission check error: $e');
      return true;
    }
  }
}
