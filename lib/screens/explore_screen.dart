import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'video_screen.dart';
import 'broll_screen.dart';
import 'talking_head_screen.dart';
import 'trending_screen.dart';
import 'magazine_screen.dart';
import 'notifications_screen.dart';
import 'generate_screen_v2.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  // Section Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXPLORE',
                        style: AppFonts.poppins(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create Amazing Content',
                        style: AppFonts.playfair(
                          size: 32,
                          weight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your creation style and start building',
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _card(context, label: 'Trending',
            bgColor: const Color(0xFF1a1a1a), accentColor: const Color(0xFFf39c12),
            icon: Icons.whatshot, hasTrending: true,
            onTap: () => _push(context, const TrendingScreen()))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'Generate',
            bgColor: const Color(0xFF1a2a1a), accentColor: const Color(0xFF6B8EC4),
            icon: Icons.image_outlined, hasTextOverlay: true,
            onTap: () => _push(context, const GenerateScreenV2()))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _card(context, label: 'Video',
            bgColor: const Color(0xFF0a1a0a), accentColor: const Color(0xFF4A8A6F),
            icon: Icons.play_circle_outline, hasPlay: true,
            onTap: () => _push(context, const VideoScreen()))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'B-Roll',
            bgColor: const Color(0xFF1a1a2a), accentColor: const Color(0xFFE8A0B4),
            icon: Icons.movie_filter_outlined, hasQuote: true,
            onTap: () => _push(context, const BrollScreen()))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _card(context, label: 'Magazine',
            bgColor: const Color(0xFF1a0a0a), accentColor: const Color(0xFFE74C3C),
            icon: Icons.newspaper_outlined, hasMagazine: true,
            onTap: () => _push(context, const MagazineScreen()))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'Avatar',
            bgColor: const Color(0xFF0a0a1a), accentColor: const Color(0xFF7B68EE),
            icon: Icons.face_retouching_natural,
            onTap: () => _push(context, const TalkingHeadScreen()))),
      ]),
    ]);
  }

  Widget _card(BuildContext context, {
    required String label, required Color bgColor, required Color accentColor,
    required IconData icon, required VoidCallback onTap,
    bool hasPlay = false, bool hasTextOverlay = false,
    bool hasQuote = false, bool hasMagazine = false,
    bool hasTrending = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Container(decoration: BoxDecoration(gradient: RadialGradient(
              center: Alignment.topRight, radius: 1.2,
              colors: [accentColor.withValues(alpha: 0.18), bgColor],
            ))),
            if (hasTextOverlay) _carouselOverlay(),
            if (hasQuote) _quoteOverlay(),
            if (hasMagazine) _magazineOverlay(),
            if (hasTrending) _trendingOverlay(),
            if (!hasTextOverlay && !hasQuote && !hasMagazine && !hasTrending)
              Center(child: Icon(icon, color: accentColor.withValues(alpha: 0.3), size: 52)),
            if (hasPlay)
              Center(child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.9),
                  boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)],
                ),
                child: const Icon(Icons.play_arrow, color: AppColors.black, size: 26),
              )),
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                )),
                child: Text(label, style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.white)),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _carouselOverlay() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('How to use AI\nlike crazy', style: AppFonts.playfair(size: 16, weight: FontWeight.w900, color: AppColors.white, height: 1.2)),
      const SizedBox(height: 4),
      Text('without compromising your vision', style: AppFonts.poppins(size: 9, color: AppColors.white.withValues(alpha: 0.5))),
    ]),
  );

  Widget _trendingOverlay() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Viral template', style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 1)),
      const SizedBox(height: 6),
      Text('Use this trending story style for fast social reach',
          style: AppFonts.poppins(size: 9, color: AppColors.white.withValues(alpha: 0.8), height: 1.5)),
      const SizedBox(height: 12),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Image + Video', style: AppFonts.poppins(size: 8, weight: FontWeight.w700, color: AppColors.gold)),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Trending', style: AppFonts.poppins(size: 8, color: AppColors.white.withValues(alpha: 0.8))),
        ),
      ]),
    ]),
  );

  Widget _quoteOverlay() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('2026 is the\nyear of', style: AppFonts.poppins(size: 13, weight: FontWeight.w700, color: AppColors.white, height: 1.3)),
      Text('peace', style: AppFonts.playfair(size: 20, weight: FontWeight.w700, color: const Color(0xFFE8A0B4), style: FontStyle.italic)),
      const SizedBox(height: 6),
      ...['You were born to build', 'Create overflowing income', 'Choose yourself'].map((t) =>
        Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [
          const Icon(Icons.favorite, color: Color(0xFFE8A0B4), size: 8),
          const SizedBox(width: 4),
          Flexible(child: Text(t, style: AppFonts.poppins(size: 8, color: AppColors.white.withValues(alpha: 0.7)))),
        ]))),
    ]),
  );

  Widget _magazineOverlay() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF1a0a0a), Color(0xFF2a1010)],
    )),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: const Color(0xFFE74C3C),
        child: Text('Forbes', style: AppFonts.playfair(size: 18, weight: FontWeight.w900, color: AppColors.white))),
      const Spacer(),
      Text('40 WOMEN LEADERS\nTO WATCH IN 2026', style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.white, letterSpacing: 0.5, height: 1.4)),
    ])),
  );
}
