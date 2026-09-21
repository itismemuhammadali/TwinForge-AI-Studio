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
  bool _agreed = false;
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
                  Icons.auto_awesome,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Content Processing',
                      style: AppFonts.poppins(
                        size: 15,
                        weight: FontWeight.w800,
                        color: AppColors.gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Third-Party AI Services Disclosure',
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
            'Twinora uses third-party AI processing services to create the content you request.',
            style: AppFonts.poppins(
              size: 12,
              color: Colors.white.withValues(alpha: 0.95),
              weight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Disclosure box
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
                Text(
                  'Depending on the feature you choose, your selected images, videos, or audio recordings are securely transmitted to Google Gemini, Fal.ai (Kling AI), Everypixel Labs, Sync.so, or HeyGen solely to generate your requested images, videos, or lip-sync content.',
                  style: AppFonts.poppins(
                    size: 11.5,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.gold, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your content is strictly not sent for advertising or profiling, is encrypted via TLS 1.3, and is never used to train public or foundational AI models.',
                        style: AppFonts.poppins(
                          size: 11,
                          color: AppColors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Privacy Policy Link
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
            child: RichText(
              text: TextSpan(
                style: AppFonts.poppins(size: 11, color: AppColors.muted),
                children: [
                  const TextSpan(text: 'You can learn more in our '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppFonts.poppins(
                      size: 11,
                      color: AppColors.gold,
                      weight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Checkbox
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _agreed
                    ? AppColors.gold.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _agreed
                      ? AppColors.gold
                      : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _agreed ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreed ? AppColors.gold : Colors.white38,
                        width: 1.5,
                      ),
                    ),
                    child: _agreed
                        ? const Icon(Icons.check, size: 16, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I understand and consent to my selected content being processed by the AI providers listed above.',
                      style: AppFonts.poppins(
                        size: 11,
                        weight: FontWeight.w600,
                        color: _agreed ? AppColors.white : AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary Button: Agree & Continue
          ElevatedButton(
            onPressed: (!_agreed || _isProcessing)
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
              disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.black38,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _agreed ? 4 : 0,
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
                    'Agree & Continue',
                    style: AppFonts.poppins(
                      size: 13,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Secondary Button: Not Now / Decline
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
              widget.allowMaybeLater ? 'Not Now' : 'Decline',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
