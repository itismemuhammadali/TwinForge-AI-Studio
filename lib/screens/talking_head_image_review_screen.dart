import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';
import 'talking_head_creation_screen.dart';

class TalkingHeadImageReviewScreen extends StatefulWidget {
  final GeneratedContent content;
  const TalkingHeadImageReviewScreen({super.key, required this.content});

  @override
  State<TalkingHeadImageReviewScreen> createState() => _TalkingHeadImageReviewScreenState();
}

class _TalkingHeadImageReviewScreenState extends State<TalkingHeadImageReviewScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  bool _saveToGallery = false;
  late final Widget _cachedImage;

  @override
  void initState() {
    super.initState();
    _cachedImage = _buildImageDisplay();
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
          'REVIEW IMAGE',
          style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: _buildImageReview(),
    );
  }

  Widget _buildImageReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
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

          // Save to Gallery toggle
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

          // Regenerate + Save buttons
          Row(children: [
            Expanded(child: GoldButton(label: 'REGENERATE', outlined: true, onTap: () {
              Navigator.pop(context);
            })),
            const SizedBox(width: 12),
            Expanded(child: GoldButton(
              label: _isSaved ? 'SAVED' : (_isSaving ? 'SAVING...' : 'SAVE'),
              loading: _isSaving,
              onTap: _isSaving || _isSaved ? null : _saveImage,
            )),
          ]),
          const SizedBox(height: 16),

          // Turn into Talking Head button
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'TURN INTO TALKING HEAD',
              onTap: _openTalkingHeadCreation,
            ),
          ),
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

  void _openTalkingHeadCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TalkingHeadCreationScreen(content: widget.content),
      ),
    );
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final imageUrl = widget.content.editedImageUrl ?? widget.content.originalImageUrl;

      if (_saveToGallery) {
        if (imageUrl.startsWith('http')) {
          final response = await http.get(Uri.parse(imageUrl));
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/twinora_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(response.bodyBytes);
          await Gal.putImage(tempFile.path);
        } else if (imageUrl.startsWith('data:image')) {
          final base64Str = imageUrl.split(',')[1];
          final bytes = base64Decode(base64Str);
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/twinora_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(bytes);
          await Gal.putImage(tempFile.path);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to gallery!', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: const Color(0xFF2a5a2a)),
          );
        }
      } else {
        String bytes;
        if (imageUrl.startsWith('http')) {
          final response = await http.get(Uri.parse(imageUrl));
          bytes = base64Encode(response.bodyBytes);
        } else if (imageUrl.startsWith('data:image')) {
          bytes = imageUrl.split(',')[1];
        } else {
          final file = File(imageUrl);
          final fileBytes = await file.readAsBytes();
          bytes = base64Encode(fileBytes);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'users/${user.uid}/talking_head/$timestamp.jpg';
        final savedUrl = await StorageService.uploadImageBytes(base64Decode(bytes), path);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('library').add({
          'type': 'image',
          'url': savedUrl,
          'source': 'talking_head',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to library!', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: const Color(0xFF2a5a2a)),
          );
        }
      }
      if (mounted) setState(() { _isSaved = true; _isSaving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e', style: AppFonts.poppins(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildImageDisplay() {
    final imageUrl = widget.content.editedImageUrl ?? widget.content.originalImageUrl;
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, height: 380, width: double.infinity);
      } catch (e) {
        return _imagePlaceholder();
      }
    } else if (imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 380,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => Container(
    height: 380,
    color: AppColors.surface,
    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.muted, size: 60),
  );
}
