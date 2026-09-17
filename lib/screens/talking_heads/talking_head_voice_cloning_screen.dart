import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../services/fal_ai_service.dart';
import '../../services/storage_service.dart';
import 'talking_head_stitch_screen.dart';

class TalkingHeadVoiceCloningScreen extends StatefulWidget {
  const TalkingHeadVoiceCloningScreen({super.key});

  @override
  State<TalkingHeadVoiceCloningScreen> createState() =>
      _TalkingHeadVoiceCloningScreenState();
}

class _TalkingHeadVoiceCloningScreenState
    extends State<TalkingHeadVoiceCloningScreen> {
  late TextEditingController _scriptController;
  bool _isGeneratingVoice = false;

  @override
  void initState() {
    super.initState();
    _scriptController = TextEditingController();
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioSample() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMedia();

      if (result == null) return;
      if (!mounted) return;

      if (!result.path.endsWith('.mp3') &&
          !result.path.endsWith('.m4a') &&
          !result.path.endsWith('.wav')) {
        _showError('Please select an audio file (mp3, m4a, or wav)');
        return;
      }

      context.read<TalkingHeadProvider>().setVoiceSampleFile(File(result.path));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice sample uploaded',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to pick audio: $e');
    }
  }

  Future<void> _generateVoice() async {
    final provider = context.read<TalkingHeadProvider>();

    if (provider.voiceSampleFile == null) {
      _showError('Please upload a voice sample');
      return;
    }

    if (_scriptController.text.trim().isEmpty) {
      _showError('Please enter a script');
      return;
    }

    setState(() => _isGeneratingVoice = true);

    try {
      debugPrint('🎤 Generating voice with FAL AI...');

      // Upload voice sample to Firebase first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final fileName = 'voice_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = 'users/${user.uid}/talking_heads/$fileName';
      final voiceSampleBytes = await provider.voiceSampleFile!.readAsBytes();
      final voiceSampleUrl = await StorageService.uploadAudioBytes(voiceSampleBytes, path);

      final voiceUrl = await FalAiService().cloneAndGenerateSpeech(
        voiceSampleUrl: voiceSampleUrl,
        script: _scriptController.text.trim(),
      );

      if (mounted) {
        provider.setGeneratedVoiceUrl(voiceUrl);
        provider.setUploadedAudioUrl(voiceUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voice generated successfully!',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to stitch screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TalkingHeadStitchScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Voice generation error: $e');
      if (mounted) {
        _showError('Failed to generate voice: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingVoice = false);
      }
    }
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
          leading: _isGeneratingVoice
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            'VOICE CLONING',
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

                if (_isGeneratingVoice)
                  _buildGeneratingState()
                else ...[
                  // Voice Sample Upload
                  _buildSampleUploadSection(provider),

                  const SizedBox(height: 24),

                  // Script Input
                  _buildScriptInputSection(),

                  const SizedBox(height: 32),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: 'GENERATE VOICE',
                      onTap: _generateVoice,
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppColors.gold,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating Voice...',
            style: AppFonts.poppins(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creating AI voice with your sample',
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleUploadSection(TalkingHeadProvider provider) {
    return Container(
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
            'VOICE SAMPLE',
            style: AppFonts.poppins(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          if (provider.voiceSampleFile == null)
            GestureDetector(
              onTap: _pickAudioSample,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.gold,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TAP TO UPLOAD SAMPLE',
                      style: AppFonts.poppins(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MP3, M4A, or WAV',
                      style: AppFonts.poppins(
                        size: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample Ready',
                              style: AppFonts.poppins(
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              provider.voiceSampleFile!.path.split('/').last,
                              style: AppFonts.poppins(
                                size: 10,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickAudioSample,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'CHANGE SAMPLE',
                        style: AppFonts.poppins(
                          size: 11,
                          weight: FontWeight.w600,
                          color: AppColors.gold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScriptInputSection() {
    return Container(
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
            'SCRIPT',
            style: AppFonts.poppins(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scriptController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter the script for the AI to speak...',
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
    );
  }
}
