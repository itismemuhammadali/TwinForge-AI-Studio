import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _hasUpload = false;
  bool _hasResult = false;
  int _selectedStyle = 0;
  bool _generating = false;

  final _styles = [
    _VideoStyle('lifestyle',  Color(0xFF2a1a0a)),
    _VideoStyle('luxury',     Color(0xFF1a1a0a)),
    _VideoStyle('business',   Color(0xFF0a1020)),
    _VideoStyle('travel',     Color(0xFF0a1a10)),
    _VideoStyle('podcast',    Color(0xFF1a0a1a)),
    _VideoStyle('editorial',  Color(0xFF1a1a1a)),
  ];

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    void push(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Stack(children: [
        // Warm gold radial glow behind everything
        Positioned(
          top: -100, left: -80, right: -80,
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
        ),

        Column(children: [
          PremiumHeader(
            onProfileTap: () => push(const ProfileScreen()),
            onSettingsTap: () => push(const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(children: [
                // Section Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIDEO',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Turn your selfie into a VIRAL VIDEO',
                      style: AppFonts.playfair(
                        size: 32,
                        weight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Generate studio-quality videos from your photos',
                      style: AppFonts.poppins(
                        size: 13,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildGlowCard(),
                const SizedBox(height: 24),
                _buildFilmstrip(),
                const SizedBox(height: 32),
                GoldButton(
                  label: _generating ? 'GENERATING...' : 'GENERATE VIDEO',
                  loading: _generating,
                  onTap: () {
                    if (!_hasUpload) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text('Upload a photo first.',
                            style: AppFonts.poppins(size: 12, color: AppColors.text)),
                      ));
                      return;
                    }
                    setState(() => _generating = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                        _generating = false;
                        _hasResult = true;
                      });
                      }
                    });
                  },
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildGlowCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        // Gold glow effect — multiple layered shadows
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(children: [
            // ── Top panel — upload ──────────────────────────────
            GestureDetector(
              onTap: () => setState(() {
                _hasUpload = !_hasUpload;
                if (!_hasUpload) _hasResult = false;
              }),
              child: Container(
                height: 195,
                width: double.infinity,
                color: const Color(0xFF1a1a14),
                child: Stack(fit: StackFit.expand, children: [
                  if (_hasUpload)
                    Container(
                      color: const Color(0xFF2a2010),
                      child: const Icon(Icons.person, color: AppColors.muted, size: 80),
                    )
                  else
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.gold, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text('tap to upload photo',
                          style: AppFonts.poppins(size: 13, color: AppColors.muted)),
                    ]),

                  // "upload photo" pill label
                  Positioned(
                    bottom: 12, right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('upload photo',
                          style: AppFonts.poppins(
                              size: 13, weight: FontWeight.w400, color: AppColors.white)),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Gold arrow divider ──────────────────────────────
            Container(
              color: const Color(0xFF0E0E0A),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 50, height: 0.5,
                    color: AppColors.gold.withValues(alpha: 0.4)),
                const SizedBox(width: 10),
                Icon(Icons.south_east,
                    color: AppColors.gold.withValues(alpha: 0.8), size: 20),
                const SizedBox(width: 10),
                Container(width: 50, height: 0.5,
                    color: AppColors.gold.withValues(alpha: 0.4)),
              ]),
            ),

            // ── Bottom panel — result ───────────────────────────
            Container(
              height: 195,
              width: double.infinity,
              color: const Color(0xFF111108),
              child: Stack(fit: StackFit.expand, children: [
                if (_hasResult)
                  Container(
                    color: const Color(0xFF1a1a10),
                    child: const Icon(Icons.movie, color: AppColors.muted, size: 80),
                  )
                else
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.video_camera_back_outlined,
                        color: AppColors.muted.withValues(alpha: 0.2), size: 52),
                    const SizedBox(height: 8),
                    Text('result appears here',
                        style: AppFonts.poppins(
                            size: 12, color: AppColors.muted.withValues(alpha: 0.3))),
                  ]),

                // Play button
                if (_hasResult)
                  Center(
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.6),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: AppColors.black, size: 28),
                    ),
                  ),

                // "apply style" / "create viral podcast clips" label
                Positioned(
                  bottom: 12, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'create ',
                            style: AppFonts.poppins(size: 12, color: AppColors.white)),
                        TextSpan(text: _styles[_selectedStyle].label,
                            style: AppFonts.poppins(
                                size: 12, weight: FontWeight.w700, color: AppColors.white)),
                        TextSpan(text: ' clips',
                            style: AppFonts.poppins(size: 12, color: AppColors.white)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilmstrip() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _styles.length,
        itemBuilder: (context, i) {
          final style = _styles[i];
          final isSelected = _selectedStyle == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedStyle = i),
            child: Container(
              width: 72,
              margin: EdgeInsets.only(right: i < _styles.length - 1 ? 10 : 0),
              decoration: BoxDecoration(
                color: style.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.white.withValues(alpha: 0.1),
                  width: isSelected ? 1.5 : 0.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline,
                      color: isSelected ? AppColors.gold : AppColors.muted.withValues(alpha: 0.5),
                      size: 24),
                  const SizedBox(height: 4),
                  Text(style.label,
                      style: AppFonts.poppins(
                          size: 9,
                          weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? AppColors.gold : AppColors.muted),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoStyle {
  final String label;
  final Color bgColor;
  const _VideoStyle(this.label, this.bgColor);
}
