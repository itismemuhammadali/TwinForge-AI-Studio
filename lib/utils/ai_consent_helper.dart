import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../screens/legal_document_viewer_screen.dart';

/// Helper to handle Apple Guidelines 5.1.1(i) & 5.1.2(i)
/// Third-Party AI Data Disclosure & Consent flow
class AiConsentHelper {
  static const String _prefKey = 'ai_data_consent_granted';

  /// Check if user has previously granted consent (local fast check)
  static Future<bool> hasConsentedLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Ensure consent is granted before an AI operation.
  /// If not granted, presents the disclosure sheet.
  /// Returns true if granted, false if user declined or dismissed.
  static Future<bool> ensureConsent(
    BuildContext context, {
    bool allowMaybeLater = false,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.aiDataConsentGranted) {
      return true;
    }

    final localGranted = await hasConsentedLocally();
    if (localGranted) {
      await userProvider.setAiDataConsent(true);
      return true;
    }

    if (!context.mounted) return false;

    // Show the disclosure modal
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: allowMaybeLater,
      enableDrag: allowMaybeLater,
      builder: (ctx) => _AiConsentBottomSheet(allowMaybeLater: allowMaybeLater),
    );

    return result ?? false;
  }

  /// Explicitly prompt on login / app open if consent not yet granted
  static Future<void> checkAndPromptOnLogin(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.aiDataConsentGranted) return;

    final localGranted = await hasConsentedLocally();
    if (localGranted) {
      await userProvider.setAiDataConsent(true);
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => const _AiConsentBottomSheet(allowMaybeLater: true),
    );
  }
}

class _AiConsentBottomSheet extends StatefulWidget {
  final bool allowMaybeLater;

  const _AiConsentBottomSheet({required this.allowMaybeLater});

  @override
  State<_AiConsentBottomSheet> createState() => _AiConsentBottomSheetState();
}

class _AiConsentBottomSheetState extends State<_AiConsentBottomSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141410),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.gold, width: 1.2),
          left: BorderSide(color: Color(0x33D4AF37), width: 0.8),
          right: BorderSide(color: Color(0x33D4AF37), width: 0.8),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Shield Icon + Title
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI DATA & PRIVACY DISCLOSURE',
                      style: AppFonts.poppins(
                        size: 13,
                        weight: FontWeight.w800,
                        color: AppColors.gold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Apple Guidelines 5.1.1(i) & 5.1.2(i) Notice',
                      style: AppFonts.poppins(
                        size: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            'To generate high-fidelity AI twins, cinematic B-roll, and realistic talking avatars, Twinora securely interfaces with enterprise AI cloud services. Before generating content, please review and consent to our data handling practices:',
            style: AppFonts.poppins(
              size: 12,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Disclosures box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDisclosureItem(
                  icon: Icons.perm_media_outlined,
                  title: 'What Media is Processed:',
                  detail: 'Your uploaded photos (face references), video clips (motion inputs), and audio recordings (voice notes & speech).',
                ),
                const SizedBox(height: 12),
                _buildDisclosureItem(
                  icon: Icons.touch_app_outlined,
                  title: 'When It is Sent (On-Demand Only):',
                  detail: 'Media is transmitted strictly and ONLY when you actively tap "Generate" or "Render". It is NEVER accessed, monitored, or sent in the background.',
                ),
                const SizedBox(height: 12),
                _buildDisclosureItem(
                  icon: Icons.hub_outlined,
                  title: 'Who It is Sent To:',
                  detail: 'Google Gemini (Image AI), Fal.ai / Kling (Video motion), Everypixel Labs & Sync.so (Lip-sync), and HeyGen (Avatars).',
                ),
                const SizedBox(height: 12),
                _buildDisclosureItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Equal Privacy Protection:',
                  detail: 'Data is strictly encrypted via TLS 1.3, processed transiently solely to execute your request, and NEVER used to train public or foundational AI models.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Policy link
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalDocumentViewerScreen(
                    documentType: LegalDocumentType.privacyPolicy,
                  ),
                ),
              );
            },
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppFonts.poppins(size: 11, color: AppColors.muted),
                  children: [
                    const TextSpan(text: 'Read our comprehensive '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppFonts.poppins(
                        size: 11,
                        color: AppColors.gold,
                        weight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' for full details.'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary Button: AGREE & CONTINUE
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    setState(() => _isProcessing = true);
                    final userProvider =
                        Provider.of<UserProvider>(context, listen: false);
                    await userProvider.setAiDataConsent(true);
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'AGREE & ALLOW AI PROCESSING',
                    style: AppFonts.poppins(
                      size: 12,
                      weight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Secondary Button: MAYBE LATER / DECLINE
          TextButton(
            onPressed: _isProcessing
                ? null
                : () {
                    Navigator.pop(context, false);
                  },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              widget.allowMaybeLater ? 'MAYBE LATER' : 'DECLINE',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosureItem({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppFonts.poppins(
                size: 11,
                color: Colors.white70,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: AppFonts.poppins(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
