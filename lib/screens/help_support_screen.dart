import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late TextEditingController _messageCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a message',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user?.uid ?? 'anonymous',
        'email': user?.email ?? 'anonymous',
        'message': text,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'platform': Platform.isAndroid ? 'Android' : 'iOS',
      });

      if (mounted) {
        _messageCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message sent! Our support team will get back to you soon.',
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
            content: Text(
              'Failed to submit ticket: $e',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              Text(
                'SUPPORT',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Help & Support',
                style: AppFonts.playfair(
                  size: 28,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'re here to help. Contact us anytime.',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // FAQ Section
              _sectionHeader('Frequently Asked Questions'),
              const SizedBox(height: 12),
              _faqItem(
                question: 'How do I generate my first image?',
                answer:
                    'Upload a selfie, add prompts to customize it, and choose your conversion type.',
              ),
              const SizedBox(height: 12),
              _faqItem(
                question: 'What are credits used for?',
                answer:
                    'Credits are used to generate images and videos. You get free credits daily.',
              ),
              const SizedBox(height: 12),
              _faqItem(
                question: 'Can I upgrade my plan?',
                answer:
                    'Yes! Visit the subscription section to upgrade to a premium plan.',
              ),
              const SizedBox(height: 32),

              // Contact Section
              _sectionHeader('Contact Us'),
              const SizedBox(height: 12),
              _contactItem(
                icon: Icons.mail_outline,
                title: 'Email',
                value: 'support@twinora.ai',
              ),
              const SizedBox(height: 12),
              _contactItem(
                icon: Icons.language,
                title: 'Website',
                value: 'www.twinora.ai',
              ),
              const SizedBox(height: 32),

              // Report AI Content Card
              _sectionHeader('Report AI Content (Policy Compliance)'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined, color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Flag Inappropriate AI Content',
                          style: AppFonts.poppins(
                            size: 13,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Encountered offensive, harmful, or policy-violating AI generated content? Flag it immediately for moderation review.',
                      style: AppFonts.poppins(size: 11, color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orangeAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.flag, color: Colors.orangeAccent, size: 16),
                        label: Text(
                          'REPORT OFFENSIVE CONTENT',
                          style: AppFonts.poppins(
                            size: 11,
                            weight: FontWeight.w700,
                            color: Colors.orangeAccent,
                            letterSpacing: 1,
                          ),
                        ),
                        onPressed: () => showReportContentDialog(
                          context,
                          contentId: 'support_flag_${DateTime.now().millisecondsSinceEpoch}',
                          contentType: 'Support In-App Report',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Message Form
              _sectionHeader('Send us a Message'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  style: AppFonts.poppins(
                    size: 14,
                    color: AppColors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Type your message here...',
                    hintStyle: AppFonts.poppins(
                      size: 14,
                      color: AppColors.muted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'SEND MESSAGE',
                loading: _loading,
                onTap: _sendMessage,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppFonts.poppins(
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.gold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _faqItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppFonts.poppins(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.poppins(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppFonts.poppins(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
