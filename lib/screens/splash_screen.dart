import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/fcm_service.dart';
import '../services/gemini_service.dart';
import '../services/fal_ai_service.dart';
import '../services/eleven_labs_service.dart';
import '../services/heygen_service.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';
import 'admin_portal_screen.dart';

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
    // Run init with minimum splash display time
    try {
      // Run init in background
      final initFuture = _initFirebase();
      
      // Ensure splash shows for minimum time
      await Future.delayed(const Duration(milliseconds: 2800));
      
      // Wait for init to complete
      await initFuture;
      
      debugPrint('✅ Initialization complete, proceeding to navigation');
    } catch (e) {
      debugPrint('❌ Fatal initialization error: $e');
      // Show error only for critical Firebase errors
      if (mounted && e.toString().contains('Firebase')) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Initialization Error'),
            content: Text('Failed to initialize:\n\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    _navigate();
  }

  Future<void> _initFirebase() async {
    try {
      await FirebaseService.initialize();
      
      debugPrint('🔄 Initializing GeminiService...');
      // Initialize critical services sequentially
      try {
        await GeminiService.initialize();
        debugPrint('✅ GeminiService initialization complete');
      } catch (e) {
        debugPrint('❌ GeminiService initialization failed: $e');
        // Don't rethrow — allow app to continue, generation will fail with proper error
      }
      
      // Initialize other services in parallel (non-critical, can fail gracefully)
      debugPrint('🔄 Initializing non-critical services...');
      await Future.wait([
        FCMService().initialize().catchError((e) {
          debugPrint('⚠️ FCMService initialization failed: $e');
          return null;
        }),
        FalAiService.initialize().catchError((e) {
          debugPrint('⚠️ FalAiService initialization failed: $e');
          return null;
        }),
        ElevenLabsService.initialize().catchError((e) {
          debugPrint('⚠️ ElevenLabsService initialization failed: $e');
          return null;
        }),
        HeyGenService.initialize().catchError((e) {
          debugPrint('⚠️ HeyGenService initialization failed: $e');
          return null;
        }),
      ]);
      
      debugPrint('✅ All services initialized');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  Future<void> _navigate() async {
    User? user;
    try {
      // Wait for auth state to be available (max 3 seconds additional wait)
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => FirebaseAuth.instance.currentUser);
    } catch (e) {
      debugPrint('Auth state detection error: $e');
      user = FirebaseAuth.instance.currentUser;
    }

    if (!mounted) return;

    Widget destination;
    if (user != null) {
      // Check if user is admin
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'];
        if (role == 'admin') {
          destination = const AdminPortalScreen();
        } else {
          destination = const MainShell();
        }
      } catch (_) {
        destination = const MainShell();
      }
    } else {
      destination = const OnboardingScreen();
    }

    if (!mounted) return;

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
