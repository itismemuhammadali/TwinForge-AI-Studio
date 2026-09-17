import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'talking_head_generation_screen.dart';

class TalkingHeadSetupScreen extends StatefulWidget {
  const TalkingHeadSetupScreen({super.key});

  @override
  State<TalkingHeadSetupScreen> createState() => _TalkingHeadSetupScreenState();
}

class _TalkingHeadSetupScreenState extends State<TalkingHeadSetupScreen> {
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _proceedToGeneration() {
    final provider = context.read<TalkingHeadProvider>();

    if (_promptController.text.trim().isEmpty) {
      _showError('Please enter a video prompt');
      return;
    }

    provider.setVideoPrompt(_promptController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadGenerationScreen(),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'TALKING HEAD SETUP',
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
                if (provider.selectedImage != null)
                  _buildImagePreview(File(provider.selectedImage!.path))
                else if (provider.selectedImageUrl != null)
                  _buildNetworkImagePreview(provider.selectedImageUrl!)
                else
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
                        size: 40,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Duration Selector
                Container(
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
                      Text(
                        'VIDEO DURATION',
                        style: AppFonts.poppins(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${provider.selectedDuration}s',
                            style: AppFonts.playfair(
                              size: 28,
                              weight: FontWeight.w900,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Max 15s',
                            style: AppFonts.poppins(
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                            elevation: 4,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: AppColors.gold,
                          inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
                          thumbColor: AppColors.gold,
                          overlayColor: AppColors.gold.withValues(alpha: 0.3),
                        ),
                        child: Slider(
                          value: provider.selectedDuration.toDouble(),
                          min: 1,
                          max: 15,
                          divisions: 14,
                          onChanged: (value) {
                            context.read<TalkingHeadProvider>().setDuration(value.toInt());
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Prompt Box
                Container(
                  padding: const EdgeInsets.all(16),
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
                      Text(
                        'VIDEO PROMPT',
                        style: AppFonts.poppins(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promptController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Describe what should happen in the video...',
                          hintStyle: AppFonts.poppins(
                            size: 13,
                            color: AppColors.muted,
                          ),
                          filled: true,
                          fillColor: AppColors.black.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.gold,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'GENERATE VIDEO',
                    onTap: _proceedToGeneration,
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

  Widget _buildImagePreview(File imageFile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          imageFile,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildNetworkImagePreview(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          imageUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 250,
              color: AppColors.surface,
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
