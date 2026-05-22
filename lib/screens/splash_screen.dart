import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/fcm_service.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    // Start animation immediately — no waiting
    _ctrl.forward();

    // Init Firebase in background while splash is showing
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Run Firebase init and minimum display time in parallel
    await Future.wait([
      _initFirebase(),
      Future.delayed(const Duration(milliseconds: 2800)), // min splash time
    ]);

    if (!mounted) return;
    _navigate();
  }

  Future<void> _initFirebase() async {
    try {
      await FirebaseService.initialize();
      await FCMService().initialize();
    } catch (_) {
      // Firebase already initialized or failed — continue anyway
    }
  }

  void _navigate() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }

    final destination = user != null
        ? const MainShell()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => destination,
        transitionsBuilder: (context, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/TWINORA.AI_LOGO.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 28),

                // TWINORA name
                Text(
                  'TWINORA',
                  style: AppFonts.playfair(
                    size: 48,
                    weight: FontWeight.w900,
                    color: AppColors.gold,
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'AI TWIN STUDIO',
                  style: AppFonts.poppins(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.white.withValues(alpha: 0.5),
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 20),

                // Gold divider
                Container(
                  width: 48,
                  height: 0.8,
                  color: AppColors.gold.withValues(alpha: 0.6),
                ),

                const SizedBox(height: 20),

                // Tagline
                Text(
                  'FOR HER  •  FOR HIM',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w600,
                    color: AppColors.gold.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 60),

                // Subtle loading dots
                _LoadingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animated loading dots
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.2, 1.0);
            return Container(
              width: 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
