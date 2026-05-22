import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4');
    _videoController.initialize().then((_) {
      if (mounted) {
        _videoController.setLooping(true);
        _videoController.setVolume(1.0);
        setState(() => _videoInitialized = true);
        // If user already navigated to page 2, play immediately
        if (_currentPage == 1) {
          _videoController.play();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController.pause();
    _videoController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      // If going to page 2, start video immediately without waiting for onPageChanged
      if (_currentPage == 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _videoInitialized) {
            _videoController.seekTo(Duration.zero);
            _videoController.play();
          }
        });
      }
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    _videoController.pause();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, anim2) => const LoginScreen(),
        transitionsBuilder: (context, anim, anim2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    if (index == 1) {
      // Always try to play — if not initialized yet, init callback will handle it
      if (_videoInitialized) {
        _videoController.seekTo(Duration.zero);
        _videoController.play();
      }
    } else {
      _videoController.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildWelcomePage(),
              _buildVideoPage(),
              _buildCtaPage(),
            ],
          ),

          // Skip button
          Positioned(
            top: 16, right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3), width: 0.8,
                    ),
                  ),
                  child: Text('SKIP',
                      style: AppFonts.poppins(
                        size: 11, weight: FontWeight.w700,
                        color: AppColors.gold, letterSpacing: 1.5,
                      )),
                ),
              ),
            ),
          ),

          // Bottom navigation
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Container(
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.gold
                              : AppColors.gold.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    const SizedBox(height: 24),
                    GoldButton(
                      label: _currentPage == 2 ? 'GET STARTED' : 'NEXT',
                      onTap: _nextPage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 1: Welcome ──────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Container(
      color: const Color(0xFF0E0E0A),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/TWINORA.AI_LOGO.png',
                width: 200, height: 200, fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),

              // TWINORA
              Text(
                'TWINORA',
                style: AppFonts.playfair(
                  size: 48, weight: FontWeight.w900,
                  color: AppColors.gold, letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI TWIN STUDIO',
                style: AppFonts.poppins(
                  size: 12, weight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.5),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              Container(width: 60, height: 0.5, color: AppColors.gold),
              const SizedBox(height: 20),
              Text(
                'FOR HER  •  FOR HIM',
                style: AppFonts.poppins(
                  size: 10, weight: FontWeight.w700,
                  color: AppColors.gold, letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your AI Digital Twin.',
                style: AppFonts.playfair(
                  size: 22, weight: FontWeight.w700,
                  color: AppColors.white, style: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 2: Video ────────────────────────────────────────────────────────
  Widget _buildVideoPage() {
    return Container(
      color: const Color(0xFF0E0E0A),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Image.asset(
                'assets/images/TWINORA.AI_LOGO.png',
                width: 80, height: 80, fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text('See It In Action',
                  style: AppFonts.playfair(
                    size: 28, weight: FontWeight.w900, color: AppColors.white,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Watch how Twinora transforms your photos into stunning AI content',
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Video Player
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3), width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      blurRadius: 20, spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: Colors.black,
                    height: 320,
                    child: ValueListenableBuilder(
                      valueListenable: _videoController,
                      builder: (context, VideoPlayerValue value, child) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_videoInitialized)
                              SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController.value.size.width,
                                    height: _videoController.value.size.height,
                                    child: VideoPlayer(_videoController),
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('Loading...',
                                        style: AppFonts.poppins(size: 12, color: AppColors.gold)),
                                  ],
                                ),
                              ),

                            // Tap anywhere on video to pause/play
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  if (_videoController.value.isPlaying) {
                                    _videoController.pause();
                                  } else {
                                    _videoController.play();
                                  }
                                },
                                child: Container(color: Colors.transparent),
                              ),
                            ),

                            // Show play button only when paused
                            if (!value.isPlaying)
                              Center(
                                child: Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.gold,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(alpha: 0.6),
                                        blurRadius: 24, spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      color: AppColors.black, size: 32),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100), // space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 3: CTA ──────────────────────────────────────────────────────────
  Widget _buildCtaPage() {
    return Container(
      color: const Color(0xFF0E0E0A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3), width: 1.5,
                  ),
                ),
                child: const Icon(Icons.rocket_launch_outlined,
                    color: AppColors.gold, size: 40),
              ),
              const SizedBox(height: 32),
              Text('Ready to Begin?',
                  style: AppFonts.playfair(
                    size: 32, weight: FontWeight.w900, color: AppColors.white,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Join creators using Twinora to generate stunning AI content. Start your journey today.',
                style: AppFonts.poppins(size: 14, color: AppColors.muted, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2), width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Free Trial',
                        style: AppFonts.poppins(
                          size: 12, weight: FontWeight.w700,
                          color: AppColors.gold, letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      '4 free image generations to get you started',
                      style: AppFonts.poppins(size: 13, color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
