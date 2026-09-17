import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'talking_head_voice_cloning_screen.dart';
import 'talking_head_microphone_screen.dart';

class TalkingHeadVoiceOptionsScreen extends StatefulWidget {
  const TalkingHeadVoiceOptionsScreen({super.key});

  @override
  State<TalkingHeadVoiceOptionsScreen> createState() =>
      _TalkingHeadVoiceOptionsScreenState();
}

class _TalkingHeadVoiceOptionsScreenState
    extends State<TalkingHeadVoiceOptionsScreen> {
  void _selectVoiceCloning() {
    context.read<TalkingHeadProvider>().setVoiceMode(VoiceMode.cloning);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadVoiceCloningScreen(),
      ),
    );
  }

  void _selectMicrophone() {
    context.read<TalkingHeadProvider>().setVoiceMode(VoiceMode.microphone);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadMicrophoneScreen(),
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
            'SELECT VOICE MODE',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Voice Cloning Card
                _buildVoiceOptionCard(
                  icon: Icons.person_outline,
                  title: 'VOICE CLONING',
                  subtitle: 'Upload a voice sample and script',
                  description:
                      'AI will clone your voice and generate speech from your script',
                  onTap: _selectVoiceCloning,
                ),

                const SizedBox(height: 20),

                // Microphone Card
                _buildVoiceOptionCard(
                  icon: Icons.mic_outlined,
                  title: 'RECORD VOICE',
                  subtitle: 'Record your own voice',
                  description:
                      'Record audio directly from your microphone (max ${provider.selectedDuration}s)',
                  onTap: _selectMicrophone,
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'GO BACK',
                    outlined: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.poppins(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppFonts.poppins(
                          size: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.gold.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppFonts.poppins(
                size: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
