import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _resending = false;
  bool _resentSuccess = false;
  String? _resendError;

  Future<void> _resendEmail() async {
    setState(() { _resending = true; _resendError = null; _resentSuccess = false; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if (mounted) setState(() { _resending = false; _resentSuccess = true; });
      } else {
        if (mounted) setState(() { _resending = false; _resendError = 'No user found. Please sign up again.'; });
      }
    } catch (e) {
      if (mounted) setState(() { _resending = false; _resendError = 'Failed to resend. Try again later.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(fit: StackFit.expand, children: [
        Image.network(
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=2400',
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.7),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (context, error, stack) => Container(color: AppColors.black),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xBF000000), Colors.transparent, Color(0xFF000000)],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xCC111111),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                child: Column(children: [
                  // Email icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, color: AppColors.gold, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('VERIFY YOUR EMAIL',
                      style: AppFonts.playfair(size: 24, weight: FontWeight.w900, color: AppColors.gold, letterSpacing: 2),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.7),
                      children: [
                        const TextSpan(text: 'A verification link has been sent to\n'),
                        TextSpan(text: widget.email,
                            style: AppFonts.poppins(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
                        const TextSpan(text: '\n\nPlease check your inbox and click the link to activate your account.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Success / error feedback
                  if (_resentSuccess) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text('Verification email resent!',
                          style: AppFonts.poppins(size: 12, color: Colors.green, weight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_resendError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(_resendError!,
                          style: AppFonts.poppins(size: 12, color: Colors.red, weight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                  ],

                  GoldButton(
                    label: 'BACK TO LOGIN',
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (context, anim, anim2) => const LoginScreen(),
                        transitionsBuilder: (context, anim, anim2, child) => FadeTransition(opacity: anim, child: child),
                      ),
                      (_) => false,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend button
                  GestureDetector(
                    onTap: _resending ? null : _resendEmail,
                    child: _resending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                          )
                        : Text('RESEND VERIFICATION EMAIL',
                            style: AppFonts.poppins(
                              size: 10, weight: FontWeight.w700,
                              color: AppColors.gold.withValues(alpha: 0.7),
                              letterSpacing: 2,
                            )),
                  ),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }
}
