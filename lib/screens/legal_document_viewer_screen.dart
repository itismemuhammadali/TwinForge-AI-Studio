import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../constants/legal_links.dart';

enum LegalDocumentType {
  privacyPolicy,
  termsOfService,
  accountDeletion,
  aboutUs,
}

class LegalDocumentViewerScreen extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalDocumentViewerScreen({
    super.key,
    required this.documentType,
  });

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open external link: $e', style: AppFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getTitle();
    final contentWidgets = _buildContent(context);

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
          title,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contentWidgets,
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (documentType) {
      case LegalDocumentType.privacyPolicy:
        return 'PRIVACY POLICY';
      case LegalDocumentType.termsOfService:
        return 'TERMS & EULA';
      case LegalDocumentType.accountDeletion:
        return 'ACCOUNT DELETION';
      case LegalDocumentType.aboutUs:
        return 'ABOUT US';
    }
  }

  List<Widget> _buildContent(BuildContext context) {
    switch (documentType) {
      case LegalDocumentType.privacyPolicy:
        return _buildPrivacyPolicy(context);
      case LegalDocumentType.termsOfService:
        return _buildTermsOfService(context);
      case LegalDocumentType.accountDeletion:
        return _buildAccountDeletion();
      case LegalDocumentType.aboutUs:
        return _buildAboutUs();
    }
  }

  // --- PRIVACY POLICY ---
  List<Widget> _buildPrivacyPolicy(BuildContext context) {
    return [
      _buildHeaderCard(
        title: 'TWINORA PRIVACY NOTICE',
        subtitle: 'Effective: August 25, 2026 | Version 2.0\nOperating Entity: Digital Passive Academy LTD',
      ),
      _buildExternalLinkButton(
        context,
        label: 'OPEN OFFICIAL PRIVACY POLICY (GOOGLE DOCS)',
        url: LegalLinks.privacyPolicyUrl,
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('1. Scope & Legal Basis'),
      _buildParagraph(
        'Digital Passive Academy LTD ("Twinora", "Company", "we", "us", or "our") is committed to protecting your privacy. This policy governs how we collect, process, and secure data in the Twinora app.',
      ),
      _buildParagraph(
        'We process personal data in compliance with GDPR (EU/UK), CCPA/CPRA, and Apple App Store Review Guidelines (Section 5.1) under GDPR Article 6 lawful bases: Performance of a Contract, User Consent, and Legitimate Interests.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('2. Information We Collect'),
      _buildBulletItem('Account Data', 'Email address, user ID (UID), and authentication tokens via Firebase Authentication (Google, Apple, or Email).'),
      _buildBulletItem('User Media', 'Uploaded reference photos, audio recordings, custom text prompts, and descriptions used for AI generation.'),
      _buildBulletItem('Generated Library', 'Rendered AI portraits, carousel slides, talking head videos, and video stories stored in your private library.'),
      _buildBulletItem('In-App Purchases', 'Subscription status and credit top-up records. Financial details and credit cards are processed strictly by Apple StoreKit; Twinora never stores payment card details.'),
      _buildBulletItem('Diagnostic Logs', 'Device model, OS version, and crash stack traces via Firebase Crashlytics to diagnose errors.'),
      const SizedBox(height: 16),
      _buildSectionTitle('3. AI Processing & Biometric Disclaimers'),
      _buildBulletItem('Transient Processing', 'Uploaded photos and audio are processed solely to generate the requested output.'),
      _buildBulletItem('No Biometric Profiles', 'Facial features are analyzed temporarily during generation to preserve consistency. We do NOT build persistent biometric identification templates or cross-platform tracking databases.'),
      _buildBulletItem('Zero Model Training', 'Your photos, generated images, and voice recordings are NEVER used to train public or commercial foundational AI models.'),
      _buildBulletItem('Encrypted Storage', 'All user media is encrypted in transit (TLS 1.3) and stored in private Google Cloud / Firebase Cloud Storage buckets.'),
      const SizedBox(height: 16),
      _buildSectionTitle('4. Third-Party AI API Providers & Consent (Apple 5.1.1/5.1.2)'),
      _buildParagraph('To execute AI creation workflows, Twinora interfaces with secure cloud AI providers. User consent is explicitly collected in-app prior to transmitting any user media (photos, audio, or prompts). All third-party partners are bound by confidentiality and data protection agreements providing equal protection to our policy:'),
      _buildBulletItem('Google Gemini API', 'High-resolution AI image rendering and reference image consistency.'),
      _buildBulletItem('Fal.ai / Kling 3.0', 'High-definition cinematic video story motion rendering.'),
      _buildBulletItem('Everypixel Labs & Sync.so', 'Lip-sync animation and audio-visual synchronization.'),
      _buildBulletItem('HeyGen API', 'Talking head avatar video creation and facial motion generation.'),
      _buildBulletItem('OpenAI API (GPT-4o Vision)', 'Template layout analysis and prompt intelligence optimization.'),
      _buildBulletItem('Equal Protection Guarantee', 'Third-party AI partners process media transiently and are strictly prohibited from using user photos, videos, audio, or prompts to train foundational AI models.'),
      const SizedBox(height: 16),
      _buildSectionTitle('5. Zero-Tolerance Child Safety (CSAM/CSAE)'),
      _buildCallout(
        'STRICT ZERO-TOLERANCE POLICY',
        'Twinora prohibits any Child Sexual Abuse Material (CSAM), Child Sexual Exploitation and Abuse (CSAE), non-consensual media, or deepfakes. Violations result in immediate permanent account termination, IP ban, and reporting to NCMEC and law enforcement authorities.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('6. Contact & Data Protection'),
      _buildParagraph('For inquiries or data protection requests:\nEmail: support@twinora.com\nEntity: Digital Passive Academy LTD\nWebsite: https://twinora.com'),
      const SizedBox(height: 30),
    ];
  }

  // --- TERMS OF SERVICE & EULA ---
  List<Widget> _buildTermsOfService(BuildContext context) {
    return [
      _buildHeaderCard(
        title: 'TERMS OF SERVICE & EULA',
        subtitle: 'Effective: August 25, 2026 | Digital Passive Academy LTD',
      ),
      _buildExternalLinkButton(
        context,
        label: 'OPEN APPLE STANDARD EULA (APPLE.COM)',
        url: LegalLinks.termsOfUseUrl,
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('1. End User License Agreement (EULA)'),
      _buildParagraph(
        'This Agreement is concluded between you and Digital Passive Academy LTD, not with Apple Inc. We grant you a limited, non-exclusive, non-transferable, revocable license to use Twinora on your Apple devices.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('2. Subscription Plans & Pricing'),
      _buildBulletItem('Starter Plan', '\$27.00 / month (Includes 600 monthly credits).'),
      _buildBulletItem('Plus Plan', '\$47.00 / month (Includes 1,200 monthly credits).'),
      _buildBulletItem('Pro Plan ⭐', '\$97.00 / month (Includes 3,000 monthly credits).'),
      _buildBulletItem('Business Plan', '\$197.99 / month (Includes 6,000 monthly credits).'),
      const SizedBox(height: 12),
      _buildParagraph('Credit Top-Up Packs (Consumables):'),
      _buildBulletItem('250 Credits', '\$14.99'),
      _buildBulletItem('500 Credits', '\$28.99'),
      _buildBulletItem('1,000 Credits', '\$54.99'),
      _buildBulletItem('2,000 Credits', '\$104.99'),
      _buildBulletItem('4,000 Credits', '\$198.99'),
      const SizedBox(height: 16),
      _buildSectionTitle('3. Auto-Renewal & Cancellation'),
      _buildCallout(
        'AUTO-RENEWAL DISCLAIMER',
        'Subscriptions automatically renew monthly unless auto-renew is turned off at least 24 hours before the end of the current billing cycle. Manage or cancel subscriptions anytime in your Apple ID Account Settings.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('4. Credit Engine & Zero-Balance Rules'),
      _buildParagraph(
        'Twinora meters compute resources via credits (e.g., 2 credits per Gemini photo, 4 credits/sec for talking head video). Before generation, the app checks credit balance. Deductions occur in atomic database transactions, preventing negative balances. Credits hold no cash value and are non-refundable.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('5. Acceptable Use Policy'),
      _buildParagraph('You agree not to upload or render: CSAM/CSAE material, sexually explicit content, deepfakes, unconsented photos of real persons, hate speech, or violent content.'),
      const SizedBox(height: 30),
    ];
  }

  // --- ACCOUNT DELETION ---
  List<Widget> _buildAccountDeletion() {
    return [
      _buildHeaderCard(
        title: 'ACCOUNT & DATA DELETION',
        subtitle: 'Apple App Store Guideline 5.1.1(v) Compliance',
      ),
      const SizedBox(height: 20),
      _buildSectionTitle('1. Your Right to Erasure'),
      _buildParagraph(
        'In compliance with Apple App Store Review Guidelines, you can permanently delete your account and all associated data at any time directly within the app.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('2. How to Delete Your Account'),
      _buildCallout(
        'METHOD 1: INSTANT IN-APP DELETION',
        '1. Open Twinora -> Go to Profile Screen.\n2. Tap the Settings icon.\n3. Tap "Delete Account" and confirm.\n\nEffect: Your authentication account, profile, credit records, uploaded media, and generated library are instantly and permanently erased.',
      ),
      const SizedBox(height: 16),
      _buildCallout(
        'METHOD 2: EMAIL / WEB REQUEST',
        'Send an email to support@twinora.com with the subject line "Account Deletion Request" from your registered email address. Requests are processed within 3 business days.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('3. Data Subject to Permanent Erasure'),
      _buildBulletItem('Authentication Data', 'Firebase Auth user record, email, and password credentials.'),
      _buildBulletItem('User Profile', 'Firestore profile document, subscription tier, and credit balances.'),
      _buildBulletItem('Uploaded Media', 'Uploaded reference face photos, voice recordings, and text prompts.'),
      _buildBulletItem('Generated Content', 'All rendered AI portraits, carousel slides, talking head videos, and stories in Cloud Storage.'),
      const SizedBox(height: 30),
    ];
  }

  // --- ABOUT US ---
  List<Widget> _buildAboutUs() {
    return [
      _buildHeaderCard(
        title: 'ABOUT TWINORA',
        subtitle: 'AI Photo & Video Creation Studio\nOperated by Digital Passive Academy LTD',
      ),
      const SizedBox(height: 20),
      _buildSectionTitle('1. Welcome to Twinora'),
      _buildParagraph(
        'Twinora is a premier AI-powered creative studio designed for creators, brands, influencers, and entrepreneurs. Our platform delivers ultra-realistic AI photoshoots, dynamic carousels, natural talking head videos, and cinematic AI video stories with consistent character identity.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('2. Core Features'),
      _buildBulletItem('AI Photoshoot Studio', 'Generate hyper-realistic studio portraits preserving lighting, facial consistency, outfits, and angles.'),
      _buildBulletItem('Talking Head Video', 'Turn photos into realistic speaking avatars with voice cloning and natural lip-syncing.'),
      _buildBulletItem('Cinematic Video Stories', 'Create high-definition B-roll motion stories powered by Kling 3.0.'),
      _buildBulletItem('Carousel Generator', 'Generate slide layouts and cover art analyzed by OpenAI Vision and Gemini.'),
      const SizedBox(height: 16),
      _buildSectionTitle('3. Company & Support Details'),
      _buildBulletItem('Entity', 'Digital Passive Academy LTD'),
      _buildBulletItem('Country', 'United Kingdom'),
      _buildBulletItem('Support Email', 'support@twinora.com'),
      _buildBulletItem('Website', 'https://twinora.com'),
      const SizedBox(height: 30),
    ];
  }

  // --- REUSABLE UI BUILDER HELPERS ---

  Widget _buildHeaderCard({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.playfair(
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppFonts.poppins(
          size: 15,
          weight: FontWeight.w700,
          color: AppColors.gold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppFonts.poppins(
          size: 13,
          color: const Color(0xFFCCCCCC),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppFonts.poppins(size: 13, color: const Color(0xFFCCCCCC), height: 1.4),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: AppFonts.poppins(weight: FontWeight.w600, color: Colors.white),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallout(String header, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 3.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: AppFonts.poppins(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppFonts.poppins(
              size: 12,
              color: const Color(0xFFBBBBBB),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalLinkButton(BuildContext context, {required String label, required String url}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      child: OutlinedButton.icon(
        onPressed: () => _openUrl(context, url),
        icon: const Icon(Icons.open_in_new, color: AppColors.gold, size: 16),
        label: Text(
          label,
          style: AppFonts.poppins(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 1.1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gold, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

