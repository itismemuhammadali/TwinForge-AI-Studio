import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../providers/content_provider.dart';
import 'package:gal/gal.dart';

class EditReviewScreen extends StatefulWidget {
  final File editedFile;
  final File originalFile;

  const EditReviewScreen({
    super.key,
    required this.editedFile,
    required this.originalFile,
  });

  @override
  State<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  bool _downloadToGallery = false;
  bool _isSaving = false;

  Future<void> _handleKeep() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // Upload edited image to Firebase Storage
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref('users/${user.uid}/edits/$fileName');
      
      final bytes = await widget.editedFile.readAsBytes();
      await ref.putData(bytes);
      final downloadUrl = await ref.getDownloadURL();

      // Create GeneratedContent with the Firebase Storage URL
      final generatedContent = GeneratedContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalImageUrl: downloadUrl,
        prompt: 'Edited from advanced editor',
        createdAt: DateTime.now(),
        contentType: 'edited',
        metadata: {
          'source': 'advanced_editor',
          'edited': true,
        },
      );

      // Save to database
      if (!mounted) return;
      final contentProvider = context.read<ContentProvider>();
      await contentProvider.saveContent(
        user.uid,
        generatedContent.toMap(),
      );

      // Download to gallery if checked
      if (_downloadToGallery) {
        try {
          await Gal.putImage(widget.editedFile.path, album: 'TWINORA');
        } catch (e) {
          debugPrint('Download error: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image saved${_downloadToGallery ? ' and downloaded' : ''}!',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e', style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDiscard() async {
    // Just go back without saving
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              Text('REVIEW EDIT',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 3,
                  )),
              const SizedBox(height: 8),
              Text('Your Edited Image',
                  style: AppFonts.playfair(
                    size: 32,
                    weight: FontWeight.w900,
                    color: AppColors.white,
                  )),
              const SizedBox(height: 8),
              Text(
                'Keep your edits or discard them.',
                textAlign: TextAlign.center,
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 32),

              // Image Preview
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      widget.editedFile,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Checkbox for download
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _downloadToGallery,
                      onChanged: (value) => setState(() => _downloadToGallery = value ?? false),
                      activeColor: AppColors.gold,
                      checkColor: AppColors.black,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download to Gallery',
                        style: AppFonts.poppins(
                          size: 14,
                          color: AppColors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Keep and Discard Buttons
              Row(
                children: [
                  Expanded(
                    child: GoldButton(
                      label: 'DISCARD',
                      outlined: true,
                      onTap: _isSaving ? null : _handleDiscard,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GoldButton(
                      label: _isSaving ? 'SAVING...' : 'KEEP',
                      loading: _isSaving,
                      onTap: _isSaving ? null : _handleKeep,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
