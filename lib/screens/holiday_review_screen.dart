import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../models/generated_content.dart';
import 'talking_heads/talking_head_image_review_screen.dart';

class HolidayReviewScreen extends StatefulWidget {
  final GeneratedContent content;
  const HolidayReviewScreen({super.key, required this.content});

  @override
  State<HolidayReviewScreen> createState() => _HolidayReviewScreenState();
}

class _HolidayReviewScreenState extends State<HolidayReviewScreen> {
  bool _isSaving = false;
  bool _saveToGallery = false;

  String get _imageUrl =>
      widget.content.editedImageUrl ?? widget.content.originalImageUrl;

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      if (_saveToGallery) {
        await Gal.putImage(_imageUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to gallery!', style: AppFonts.poppins(size: 13)), backgroundColor: const Color(0xFF2a5a2a)),
          );
        }
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'holiday/$uid/$timestamp.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        if (_imageUrl.startsWith('data:image')) {
          final base64Str = _imageUrl.split(',')[1];
          final data = base64Decode(base64Str);
          final uploadTask = ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          await FirebaseFirestore.instance.collection('generated_holiday').add({
            'imageUrl': downloadUrl,
            'userId': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance.collection('generated_holiday').add({
            'imageUrl': _imageUrl,
            'userId': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to your library!', style: AppFonts.poppins(size: 13)), backgroundColor: const Color(0xFF2a5a2a)),
          );
        }
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e', style: AppFonts.poppins(size: 13)), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('HOLIDAY EDITION', style: AppFonts.poppins(size: 13, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImage(),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, const Color(0xFF0E0E0A).withValues(alpha: 0.9), const Color(0xFF0E0E0A)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save option checkbox
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
                  Expanded(child: _buildButton(label: 'REGENERATE', icon: Icons.refresh, isPrimary: false, onTap: () => Navigator.pop(context, 'regenerate'))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildButton(label: _isSaving ? 'SAVING...' : 'SAVE', icon: _isSaving ? null : Icons.download, isPrimary: true, onTap: _isSaving ? null : _saveImage)),
                ]),
                const SizedBox(height: 12),
                // Turn into Talking Head
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TalkingHeadImageReviewScreen(imageSource: 'file', imageData: null))),
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.15), width: 0.8),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.videocam_outlined, color: AppColors.gold.withValues(alpha: 0.8), size: 18),
                      const SizedBox(width: 8),
                      Text('TURN INTO TALKING HEAD', style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.gold.withValues(alpha: 0.8), letterSpacing: 2)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildImage() {
    if (_imageUrl.startsWith('data:image')) {
      try {
        final base64Str = _imageUrl.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return _placeholder();
      }
    } else if (_imageUrl.startsWith('https://')) {
      return Image.network(_imageUrl, fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return Container(color: AppColors.surface, child: const Center(child: CircularProgressIndicator(color: AppColors.gold)));
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    height: 300, color: AppColors.surface,
    child: const Icon(Icons.broken_image, color: AppColors.muted, size: 48),
  );

  Widget _buildButton({required String label, IconData? icon, required bool isPrimary, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.gold : AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(26),
          border: isPrimary ? null : Border.all(color: AppColors.white.withValues(alpha: 0.15), width: 0.8),
          boxShadow: isPrimary ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))] : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) Icon(icon, color: isPrimary ? AppColors.black : AppColors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: isPrimary ? AppColors.black : AppColors.white, letterSpacing: 2)),
        ]),
      ),
    );
  }
}
