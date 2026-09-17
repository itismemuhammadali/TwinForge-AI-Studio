import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'talking_head_setup_screen.dart';

class TalkingHeadImageReviewScreen extends StatefulWidget {
  final String imageSource; // 'file', 'url', or 'base64'
  final dynamic imageData; // File, String URL, or base64 string
  final String? title;

  const TalkingHeadImageReviewScreen({
    super.key,
    required this.imageSource,
    required this.imageData,
    this.title,
  });

  @override
  State<TalkingHeadImageReviewScreen> createState() =>
      _TalkingHeadImageReviewScreenState();
}

class _TalkingHeadImageReviewScreenState
    extends State<TalkingHeadImageReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TalkingHeadProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: const Color(0xFF0E0E0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title ?? 'TALKING HEAD REVIEW',
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

                // Image Preview
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _buildImagePreview(),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Info Box
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Image Selected',
                            style: AppFonts.poppins(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This image will be used to generate your talking head video. You can now proceed to customize the duration and prompt.',
                        style: AppFonts.poppins(
                          size: 12,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'TURN INTO TALKING HEAD',
                    onTap: () {
                      _proceedToSetup(provider);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'GO BACK',
                    outlined: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    try {
      if (widget.imageSource == 'file' && widget.imageData is File) {
        return Image.file(
          widget.imageData as File,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300,
        );
      } else if (widget.imageSource == 'url' && widget.imageData is String) {
        return Image.network(
          widget.imageData as String,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      } else if (widget.imageSource == 'base64' && widget.imageData is String) {
        // For base64, show placeholder since we can't directly display it
        return Container(
          width: double.infinity,
          height: 300,
          color: AppColors.surface,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.muted,
              size: 60,
            ),
          ),
        );
      }
    } catch (e) {
      return _buildErrorPlaceholder();
    }
    return _buildErrorPlaceholder();
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.muted,
          size: 60,
        ),
      ),
    );
  }

  void _proceedToSetup(TalkingHeadProvider provider) {
    // Set the image in provider
    if (widget.imageSource == 'file' && widget.imageData is File) {
      provider.setSelectedImage(widget.imageData as File);
    } else if (widget.imageSource == 'url' && widget.imageData is String) {
      provider.setSelectedImageUrl(widget.imageData as String);
    }

    // Navigate to setup screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadSetupScreen(),
      ),
    );
  }
}
