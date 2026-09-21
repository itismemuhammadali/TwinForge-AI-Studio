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

  Future<void> _openEmail(BuildContext context, String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email client: $e', style: AppFonts.poppins(color: Colors.white)),
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
        return _buildAccountDeletion(context);
      case LegalDocumentType.aboutUs:
        return _buildAboutUs(context);
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
      _buildSectionTitle('1. Scope & Legal Basis for Data Processing'),
      _buildParagraph(
        'Digital Passive Academy LTD ("Twinora", "Company", "we", "us", or "our") is committed to safeguarding your privacy and personal data. This Privacy Policy details how we collect, use, store, process, and protect information when you install, access, or use the Twinora mobile application ("App") across iOS and Android devices.',
      ),
      _buildParagraph(
        'We process your personal data in strict compliance with applicable global privacy laws, including the European Union and United Kingdom General Data Protection Regulation (GDPR / UK GDPR), the California Consumer Privacy Act (CCPA/CPRA), the Apple App Store Review Guidelines (Section 5.1), and the Google Play Store Data Safety Policies.',
      ),
      _buildParagraph(
        'Under GDPR Article 6, our lawful bases for data processing include: (i) Performance of a Contract to render requested AI image and video outputs; (ii) Consent explicitly provided when granting camera and photo gallery permissions; and (iii) Legitimate Interests to secure the App, prevent fraudulent usage, and ensure compliance with child safety laws.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('2. Information We Collect'),
      _buildParagraph(
        'We collect only the minimum necessary data required to deliver our AI photo, carousel, talking head video, and cinematic story creation features:',
      ),
      _buildBulletItem('A. Account & Authentication Data', 'Email address, unique user ID (UID), and authentication tokens generated when registering or signing in via Firebase Authentication (Email/Password, Google Sign-In, or Apple Sign-In).'),
      _buildBulletItem('B. User-Uploaded Media Content', 'Reference facial photographs, voice audio recordings, user-written text prompts, and custom descriptions uploaded directly by you to generate personalized AI media.'),
      _buildBulletItem('C. Generated AI Media Outputs', 'AI-generated portraits, carousel slides, talking head videos, and video stories rendered by our cloud processing infrastructure and stored in your private library.'),
      _buildBulletItem('D. In-App Purchase & Transaction Data', 'Purchase history, active subscription tier, credit top-up records, transaction IDs, and credit balances. FINANCIAL NOTICE: All payment card details, billing addresses, and bank accounts are processed exclusively by Apple Inc. (StoreKit) or Google LLC (Google Play Billing). Twinora never sees, accesses, or stores your financial credit card details.'),
      _buildBulletItem('E. Technical & Diagnostic Logs', 'Device model, operating system version, unique device identifiers (IDFA/GAID), IP address, app installation ID, latency logs, and crash stack traces collected silently via Firebase Crashlytics to diagnose technical errors.'),
      const SizedBox(height: 16),
      _buildSectionTitle('3. AI Processing, Biometric Features & Media Safety Disclaimers'),
      _buildParagraph(
        'Twinora utilizes state-of-the-art artificial intelligence models to render realistic digital media. We enforce strict privacy and security guarantees regarding AI media processing:',
      ),
      _buildBulletItem('Transient Processing Only', 'Uploaded reference photos and audio recordings are processed solely and exclusively for the transient purpose of generating the specific AI image or video requested by you.'),
      _buildBulletItem('No Biometric Identification Profiles', 'Facial geometry and features in uploaded photos are analyzed temporarily during the generation pipeline to preserve subject identity and consistency. We do NOT build persistent biometric identification templates, facial recognition profiles, or biometric databases to track individuals across third-party platforms.'),
      _buildBulletItem('Zero AI Model Training Guarantee', 'Your uploaded reference photos, generated images, custom text prompts, and voice audio files are NEVER sold, rented, leased, or used to train, retrain, or improve public, commercial, or foundational AI models.'),
      _buildBulletItem('Private Encrypted Storage', 'All user media is transmitted over HTTPS utilizing TLS 1.3 encryption and stored in private Google Cloud / Firebase Cloud Storage buckets protected by strict security rules mapped to your individual authenticated User ID.'),
      const SizedBox(height: 16),
      _buildSectionTitle('4. Third-Party AI API Providers & In-App Consent (Apple Guidelines 5.1.1 & 5.1.2)'),
      _buildParagraph(
        'To execute specialized creation workflows, Twinora securely interfaces via encrypted API requests with industry-leading cloud AI providers. User consent is explicitly collected in-app prior to transmitting any user media (photos, video clips, and audio recordings). Media transmission occurs strictly and exclusively on-demand when you actively initiate an image or video generation, never in the background. All third-party partners are bound by confidentiality and data protection agreements providing equal protection to this policy:',
      ),
      _buildBulletItem('Google Gemini API (Google Cloud Platform)', 'Used for high-resolution AI image rendering and reference image consistency processing.'),
      _buildBulletItem('Fal.ai / Kling 3.0 Engine', 'Used for high-definition B-roll motion rendering and cinematic video story creation.'),
      _buildBulletItem('Everypixel Labs & Sync.so Engine', 'Used for high-fidelity facial lip-syncing, audio alignment, and audio-visual synchronization.'),
      _buildBulletItem('HeyGen API', 'Used for talking head avatar video creation and dynamic facial motion generation.'),
      _buildBulletItem('OpenAI API (GPT-4o Vision)', 'Used for template layout vision analysis and prompt intelligence optimization.'),
      _buildBulletItem('Equal Protection Guarantee', 'Third-party AI partners process media transiently and are strictly prohibited from using user photos, videos, audio, or prompts to train foundational AI models.'),
      const SizedBox(height: 16),
      _buildSectionTitle('5. Zero-Tolerance Child Safety (CSAM/CSAE) & AI Harm Prevention Policy'),
      _buildParagraph('Prohibited Content Categories Include:'),
      _buildBulletItem('CSAM / CSAE', 'Any material depicting, simulating, or suggesting minors in sexually explicit, nude, or suggestive poses.'),
      _buildBulletItem('Non-Consensual Media & Deepfakes', 'Generating sexually explicit, nude, or harassing imagery of real individuals without their documented consent.'),
      _buildBulletItem('Unauthorized Likeness Uploads', 'Uploading photos of individuals without legal authorization or intent to defame, stalk, or harass.'),
      _buildCallout(
        'STRICT ZERO-TOLERANCE POLICY',
        'Twinora maintains an absolute zero-tolerance policy against CSAM, CSAE, and non-consensual deepfakes. Violations result in immediate permanent account termination, IP ban, and reporting to the National Center for Missing & Exploited Children (NCMEC) and appropriate law enforcement agencies.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('6. User Data Rights & Account Deletion Workflows'),
      _buildParagraph(
        'In compliance with Apple App Store Review Guideline 5.1.1(ix), Google Play Data Safety Policy, and GDPR Article 17, you have the absolute right to delete your account and all associated personal data at any time:',
      ),
      _buildCallout(
        'METHOD 1: INSTANT IN-APP ACCOUNT DELETION',
        'Open Twinora -> Navigate to Profile -> Tap Settings (gear icon) -> Tap "Delete Account" -> Confirm.\n\nEffect: This immediately and permanently purges your authentication record, user profile, credit balance, uploaded photos, and generated library media from our live databases.',
      ),
      _buildCallout(
        'METHOD 2: WEB / EMAIL DELETION REQUEST',
        'Send an email to support@twinora.com with the subject line "Account Deletion Request" from your registered email address. Our engineering team will process and erase all your records within 3 business days.',
        actionLabel: 'TAP TO DRAFT DELETION EMAIL',
        onAction: () => _openEmail(context, 'support@twinora.com', subject: 'Account Deletion Request'),
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('7. Data Retention & International Data Transfers'),
      _buildParagraph(
        'Personal data is retained only for as long as your account remains active. Upon account deletion, all media and profile data are permanently erased. Anonymized transaction logs may be retained solely to comply with statutory financial auditing and tax laws.',
      ),
      _buildParagraph(
        'Data collected by Twinora may be stored and processed in secure data centers located in the United Kingdom, European Union, and United States operated by Google Cloud Platform. International data transfers are protected under Standard Contractual Clauses (SCCs) and UK International Data Transfer Agreements.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('8. Children\'s Privacy Notice'),
      _buildParagraph(
        'Twinora is intended strictly for users aged 13 and older (or 16 and older in the EEA/UK). We do not knowingly solicit or collect data from children under 13. If we discover that a child under 13 has created an account, we will immediately delete the account and purge all associated media.',
      ),
      const SizedBox(height: 16),
      _buildSectionTitle('9. Contact Information & Data Protection Officer'),
      _buildParagraph(
        'For any privacy questions, data protection inquiries, or regulatory communications, please contact our legal team:',
      ),
      _buildBulletItem('Operating Entity', 'Digital Passive Academy LTD'),
      _buildBulletItem('Attention', 'Data Protection Officer / Privacy Legal Team'),
      _buildLinkBulletItem(
        context,
        title: 'Email',
        displayValue: 'support@twinora.com',
        onTap: () => _openEmail(context, 'support@twinora.com', subject: 'Privacy Policy Inquiry'),
        icon: Icons.email_outlined,
      ),
      _buildLinkBulletItem(
        context,
        title: 'Website',
        displayValue: 'https://twinora.com',
        onTap: () => _openUrl(context, 'https://twinora.com'),
        icon: Icons.open_in_new,
      ),
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
  List<Widget> _buildAccountDeletion(BuildContext context) {
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
        actionLabel: 'TAP TO DRAFT DELETION EMAIL',
        onAction: () => _openEmail(context, 'support@twinora.com', subject: 'Account Deletion Request'),
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
  List<Widget> _buildAboutUs(BuildContext context) {
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
      _buildLinkBulletItem(
        context,
        title: 'Support Email',
        displayValue: 'support@twinora.com',
        onTap: () => _openEmail(context, 'support@twinora.com', subject: 'Twinora Support Inquiry'),
        icon: Icons.email_outlined,
      ),
      _buildLinkBulletItem(
        context,
        title: 'Website',
        displayValue: 'https://twinora.com',
        onTap: () => _openUrl(context, 'https://twinora.com'),
        icon: Icons.open_in_new,
      ),
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

  Widget _buildLinkBulletItem(
    BuildContext context, {
    required String title,
    required String displayValue,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$title: ',
            style: AppFonts.poppins(
              size: 13,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayValue,
                    style: AppFonts.poppins(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.gold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, size: 14, color: AppColors.gold),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallout(String header, String body, {String? actionLabel, VoidCallback? onAction}) {
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: AppFonts.poppins(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        decoration: TextDecoration.underline,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

