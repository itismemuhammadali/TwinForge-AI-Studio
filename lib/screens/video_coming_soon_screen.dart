import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class VideoComingSoonScreen extends StatelessWidget {
  const VideoComingSoonScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.gold,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Video Generation',
                      style: AppFonts.playfair(
                        size: 26,
                        weight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Coming Soon',
                      style: AppFonts.poppins(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI-powered video generation is currently in development. Stay tuned for exciting updates!',
                      style: AppFonts.poppins(
                        size: 13,
                        color: AppColors.muted,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
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
}
