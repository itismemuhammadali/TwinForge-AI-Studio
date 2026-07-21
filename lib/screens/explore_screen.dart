import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'broll_entry_point_screen.dart';
import 'carousel_screen.dart';
import 'trending_screen.dart';
import 'notifications_screen.dart';
import 'generate_screen_v2.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.gold, size: 22),
            const SizedBox(width: 10),
            Text('Coming Soon', style: AppFonts.poppins(size: 16, weight: FontWeight.w700, color: AppColors.white)),
          ],
        ),
        content: Text(
          'This feature is currently in development and will be available soon.',
          style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppFonts.poppins(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

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
      // Community Card
      GestureDetector(
        onTap: () async {
          final url = Uri.parse('https://app.briefee.com/community/accept-link-invitation?token=6s1s9vh98u5lb2svgpx0e7v83w1ach42fmyphelw');
          await launchUrl(url, mode: LaunchMode.externalApplication);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7B68EE).withValues(alpha: 0.2),
                const Color(0xFF7B68EE).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF7B68EE).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMUNITY',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFF7B68EE),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join Twinora University',
                style: AppFonts.playfair(
                  size: 20,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.open_in_new, color: const Color(0xFF7B68EE), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'briefee.com',
                    style: AppFonts.poppins(
                      size: 12,
                      color: const Color(0xFF7B68EE),
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      // ViralFlip Card
      GestureDetector(
        onTap: () async {
          final url = Uri.parse('https://viralflip.ai');
          await launchUrl(url, mode: LaunchMode.externalApplication);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.2),
                AppColors.gold.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAN YOUR CONTENT',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Viral content with ViralFlip',
                style: AppFonts.playfair(
                  size: 20,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.open_in_new, color: AppColors.gold, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'viralflip.ai',
                    style: AppFonts.poppins(
                      size: 12,
                      color: AppColors.gold,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _card(context, label: 'Trending',
            bgColor: const Color(0xFF1a1a1a), accentColor: const Color(0xFFf39c12),
            icon: Icons.whatshot, hasTrending: true,
            onTap: () => _push(context, const TrendingScreen()))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'Podcast',
            bgColor: const Color(0xFF1a0a0a), accentColor: const Color(0xFFE74C3C),
            icon: Icons.mic, hasPodcast: true,
            onTap: () => _push(context, const TrendingScreen(category: 'Podcast', title: 'Podcast')))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _card(context, label: 'Talking Head',
            bgColor: const Color(0xFF1a0a1a), accentColor: const Color(0xFFE8A0B4),
            hasTalkingHead: true,
            onTap: () => _push(context, const TrendingScreen(fromTalkingHead: true, category: 'Talking Head', title: 'Talking Head')))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'Generate',
            bgColor: const Color(0xFF1a2a1a), accentColor: const Color(0xFF6B8EC4),
            icon: Icons.image_outlined, hasGenerate: true,
            onTap: () => _push(context, const GenerateScreenV2()))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _card(context, label: 'B-Roll',
            bgColor: const Color(0xFF1a1a2a), accentColor: const Color(0xFFE8A0B4),
            icon: Icons.movie_filter_outlined, hasBroll: true,
            onTap: () => _push(context, const BrollEntryPointScreen()))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'Carousel',
            bgColor: const Color(0xFF1a1a0a), accentColor: const Color(0xFF9B59B6),
            icon: Icons.view_carousel_outlined, hasCarouselDesc: true,
            onTap: () => _push(context, const CarouselScreen()))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _card(context, label: 'Magazine',
            bgColor: const Color(0xFF1a0a0a), accentColor: const Color(0xFFE74C3C),
            icon: Icons.newspaper_outlined, hasMagazineDesc: true,
            onTap: () => _push(context, const TrendingScreen(category: 'Magazine', title: 'Magazine')))),
        const SizedBox(width: 10),
        Expanded(child: _card(context, label: 'Manifestation AI',
            bgColor: const Color(0xFF0a0a1a), accentColor: const Color(0xFF7B68EE),
            hasManifestation: true,
            onTap: () => _push(context, const TrendingScreen(fromManifestation: true, category: 'Manifestation', title: 'Manifestation AI')))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _card(context, label: 'The Holiday Edition',
            bgColor: const Color(0xFF0a0a2a), accentColor: const Color(0xFF5B48EE),
            icon: Icons.videocam, hasHoliday: true, cardHeight: 100,
            onTap: () => _push(context, const TrendingScreen(fromHoliday: true, category: 'Holiday', title: 'Holiday Edition')))),
      ]),
    ]);
  }

  Widget _card(BuildContext context, {
    required String label, required Color bgColor, required Color accentColor,
    IconData? icon, required VoidCallback onTap,
    bool hasPlay = false, bool hasTextOverlay = false,
    bool hasTrending = false, bool hasBroll = false,
    bool hasCarouselDesc = false, bool hasMagazineDesc = false, bool hasPodcast = false,
    bool hasGenerate = false, bool hasHoliday = false, bool hasTalkingHead = false, bool hasManifestation = false, double? cardHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight ?? 170,
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            if (hasTrending)
              Image.asset(
                'assets/images/trending_cover.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasPodcast)
              Image.asset(
                'assets/images/podcast_cover.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasBroll)
              Image.asset(
                'assets/images/broll_covers.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasCarouselDesc)
              Image.asset(
                'assets/images/carousel_cover.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasMagazineDesc)
              Image.asset(
                'assets/images/magazine_cover.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasTalkingHead)
              Image.asset(
                'assets/images/talking_head_cover.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasManifestation)
              Image.asset(
                'assets/images/AI_manifestation_cover.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasGenerate)
              Image.asset(
                'assets/images/generate_cover.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else if (hasHoliday)
              Image.asset(
                'assets/images/holiday_edition_cover.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topRight, radius: 1.2,
                    colors: [accentColor.withValues(alpha: 0.18), bgColor],
                  )),
                ),
              )
            else
              Container(decoration: BoxDecoration(gradient: RadialGradient(
                center: Alignment.topRight, radius: 1.2,
                colors: [accentColor.withValues(alpha: 0.18), bgColor],
              ))),
            if (hasTextOverlay) _carouselOverlay(),
            if (!hasTextOverlay && !hasTrending && !hasBroll && !hasCarouselDesc && !hasMagazineDesc && !hasPodcast && !hasGenerate && !hasHoliday && !hasTalkingHead && !hasManifestation && icon != null)
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
      Text('Create your AI\ntwin', style: AppFonts.playfair(size: 16, weight: FontWeight.w900, color: AppColors.white, height: 1.2)),
      const SizedBox(height: 4),
      Text('Generate stunning content with AI', style: AppFonts.poppins(size: 9, color: AppColors.white.withValues(alpha: 0.5))),
    ]),
  );


}
