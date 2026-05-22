import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import 'profile_screen.dart';
import 'generate_screen.dart';
import 'notifications_screen.dart';

class PhotoshootScreen extends StatelessWidget {
  const PhotoshootScreen({super.key});

  static const _styles = [
    _PStyle('Business',     Color(0xFF1a2a1a), Color(0xFFB8C4A0)),
    _PStyle('Podcast',      Color(0xFF1a1a2a), Color(0xFFB1946C)),
    _PStyle('Editorial BW', Color(0xFF1a1a1a), Color(0xFFAAAAAA)),
    _PStyle('Private Jet',  Color(0xFF0a1a2a), Color(0xFF6B8EC4)),
    _PStyle('Fashion',      Color(0xFF2a1a0a), Color(0xFFD4A574)),
    _PStyle('Skyline',      Color(0xFF0a1a2a), Color(0xFF4A8A9F)),
  ];

  void _push(BuildContext context, Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
            creditsText: '16 CREDITS',
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
                        'PHOTOSHOOT',
                        style: AppFonts.poppins(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate Your Twin',
                        style: AppFonts.playfair(
                          size: 32,
                          weight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a style and customize your AI-generated image',
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
        Expanded(child: SizedBox(height: 170, child: _styleCard(context, _styles[0]))),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(height: 170, child: _styleCard(context, _styles[1]))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: SizedBox(height: 170, child: _styleCard(context, _styles[2]))),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(height: 170, child: _styleCard(context, _styles[3]))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: SizedBox(height: 170, child: _styleCard(context, _styles[4]))),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(height: 170, child: _styleCard(context, _styles[5]))),
      ]),
    ]);
  }

  Widget _styleCard(BuildContext context, _PStyle style) {
    return GestureDetector(
      onTap: () => _push(context, GenerateScreen(presetStyle: style.label)),
      child: Container(
        decoration: BoxDecoration(
          color: style.bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.accentColor.withValues(alpha: 0.2), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Container(decoration: BoxDecoration(gradient: RadialGradient(
              center: Alignment.topCenter, radius: 1.0,
              colors: [style.accentColor.withValues(alpha: 0.2), style.bgColor],
            ))),
            Positioned(top: 20, left: 0, right: 0,
              child: Icon(Icons.person_outline,
                  color: style.accentColor.withValues(alpha: 0.15), size: 80)),
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                )),
                child: Text(style.label,
                    style: AppFonts.poppins(size: 14, weight: FontWeight.w600, color: AppColors.white)),
              )),
          ]),
        ),
      ),
    );
  }
}

class _PStyle {
  final String label;
  final Color bgColor;
  final Color accentColor;
  const _PStyle(this.label, this.bgColor, this.accentColor);
}
