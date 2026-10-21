import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/carousel_models.dart';
import '../providers/content_provider.dart';
import '../services/carousel_export_service.dart';

class CarouselReviewScreen extends StatefulWidget {
  final Carousel carousel;

  const CarouselReviewScreen({
    super.key,
    required this.carousel,
  });

  @override
  State<CarouselReviewScreen> createState() => _CarouselReviewScreenState();
}

class _CarouselReviewScreenState extends State<CarouselReviewScreen> {
  bool _downloadToDownloads = false;
  bool _isSaving = false;
  int _currentSlidePreview = 0;

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 1. Generate ZIP Bytes
      final zipBytes = await CarouselExportService.exportCarouselToZipBytes(widget.carousel);

      // 2. Upload to Firebase Storage
      final fileName = 'carousel_${DateTime.now().millisecondsSinceEpoch}.zip';
      final storageRef = FirebaseStorage.instance.ref('users/${user.uid}/generatedCarousels/$fileName');
      
      final uploadTask = await storageRef.putData(
        zipBytes,
        SettableMetadata(contentType: 'application/zip'),
      );
      final firebaseZipUrl = await uploadTask.ref.getDownloadURL();

      // 3. Create GeneratedContent for database
      // Using the first slide as a representative thumbnail/image
      final firstSlideUrl = widget.carousel.slides.isNotEmpty 
          ? widget.carousel.slides[0].backgroundImageUrl ?? '' 
          : '';

      final carouselData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'carousel',
        'carouselZipUrl': firebaseZipUrl,
        'imageUrl': firstSlideUrl, // Used for library preview
        'prompt': 'AI Carousel: ${widget.carousel.slides.length} slides',
        'createdAt': FieldValue.serverTimestamp(),
        'slides': widget.carousel.slides.map((s) => {
          'backgroundImageUrl': s.backgroundImageUrl,
          'overlaysCount': s.overlays.length,
        }).toList(),
        'metadata': {
          'source': 'carousel_studio',
          'storagePath': 'users/${user.uid}/generatedCarousels/$fileName',
        },
      };

      // 4. Save to Firestore
      if (!mounted) return;
      final contentProvider = context.read<ContentProvider>();
      await contentProvider.saveContent(user.uid, carouselData);

      // 5. Download to local storage if checked
      if (_downloadToDownloads) {
        try {
          if (Platform.isAndroid) {
            final status = await Permission.storage.request();
            if (!status.isGranted) {
               final manageStatus = await Permission.manageExternalStorage.request();
               if (!manageStatus.isGranted) {
                 debugPrint('Storage permission denied');
               }
            }
          }
          
          final downloadsDir = await CarouselExportService.getDownloadsDirectory();
          if (downloadsDir != null) {
            final localFile = File('${downloadsDir.path}/$fileName');
            await localFile.writeAsBytes(zipBytes);
            debugPrint('✅ Downloaded to: ${localFile.path}');
          }
        } catch (e) {
          debugPrint('Local download error: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carousel saved${_downloadToDownloads ? ' and downloaded' : ''}!',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(
        actions: [
          ReportContentIconButton(
            contentId: 'carousel_${widget.carousel.hashCode}',
            contentType: 'AI Generated Carousel',
            previewUrl: widget.carousel.slides.isNotEmpty ? widget.carousel.slides.first.backgroundImageUrl : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              Text('REVIEW CAROUSEL',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 3,
                  )),
              const SizedBox(height: 8),
              Text('Your AI Carousel',
                  style: AppFonts.playfair(
                    size: 32,
                    weight: FontWeight.w900,
                    color: AppColors.white,
                  )),
              const SizedBox(height: 8),
              Text(
                'Review your ${widget.carousel.slides.length} slides before saving.',
                textAlign: TextAlign.center,
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 32),

              // Slide Preview (Showing first slide)
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      // Slides PageView
                      PageView.builder(
                        itemCount: widget.carousel.slides.length,
                        onPageChanged: (idx) => setState(() => _currentSlidePreview = idx),
                        itemBuilder: (context, index) {
                          final slide = widget.carousel.slides[index];
                          return Image.network(
                            slide.backgroundImageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(color: AppColors.surface),
                          );
                        },
                      ),
                      
                      // Overlay indicator
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentSlidePreview + 1} / ${widget.carousel.slides.length}',
                            style: AppFonts.poppins(size: 10, color: Colors.white, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ReportContentTextButton(
                contentId: 'carousel_${widget.carousel.hashCode}',
                contentType: 'AI Generated Carousel',
                previewUrl: widget.carousel.slides.isNotEmpty ? widget.carousel.slides.first.backgroundImageUrl : null,
              ),
              const SizedBox(height: 16),

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
                      value: _downloadToDownloads,
                      onChanged: (value) => setState(() => _downloadToDownloads = value ?? false),
                      activeColor: AppColors.gold,
                      checkColor: AppColors.black,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download to Downloads Folder (ZIP)',
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  GoldButton(
                    label: _isSaving ? 'SAVING...' : 'SAVE CAROUSEL',
                    loading: _isSaving,
                    onTap: _isSaving ? null : _handleSave,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          'DISCORD',
                          style: AppFonts.poppins(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.redAccent,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
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
