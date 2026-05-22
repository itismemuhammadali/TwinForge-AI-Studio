import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  void _onReset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'ENTER YOUR EMAIL FIRST');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final success = await context.read<AuthProvider>().resetPassword(
      _emailCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() { _loading = false; _sent = true; });
    } else {
      setState(() {
        _loading = false;
        _error = context.read<AuthProvider>().errorMessage ?? 'Failed to send reset email';
      });
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text('BACK', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
                ]),
              ),
              const SizedBox(height: 24),
              Center(
                child: Image.asset(
                'assets/images/TWINORA.AI_LOGO.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(text: 'TWIN', style: AppFonts.playfair(size: 36, weight: FontWeight.w900, color: AppColors.white)),
                    TextSpan(text: 'ORA', style: AppFonts.playfair(size: 36, weight: FontWeight.w900, color: AppColors.gold)),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xCC0C0C0C),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 0.8),
                ),
                child: _sent ? _buildSentState() : _buildForm(),
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildForm() => Column(children: [
    Text('RECOVERY', style: AppFonts.playfair(size: 28, weight: FontWeight.w900, color: AppColors.gold, letterSpacing: 4)),
    const SizedBox(height: 8),
    Text('Enter your studio email and we\'ll send a reset link.',
        textAlign: TextAlign.center,
        style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
    const SizedBox(height: 32),
    AimrField(label: 'STUDIO EMAIL', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
    if (_error != null) ...[
      const SizedBox(height: 12),
      Text(_error!, style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: Colors.red.shade400)),
    ],
    const SizedBox(height: 28),
    GoldButton(label: 'RESET', loading: _loading, onTap: _onReset),
  ]);

  Widget _buildSentState() => Column(children: [
    Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: const Icon(Icons.mark_email_read_outlined, color: AppColors.gold, size: 32),
    ),
    const SizedBox(height: 20),
    Text('CHECK YOUR EMAIL', style: AppFonts.playfair(size: 22, weight: FontWeight.w900, color: AppColors.gold)),
    const SizedBox(height: 12),
    Text('A password reset link has been dispatched to your studio email.',
        textAlign: TextAlign.center,
        style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6)),
    const SizedBox(height: 28),
    GoldButton(label: 'BACK TO ENTRY', onTap: () => Navigator.pop(context)),
  ]);
}
