import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class EditScreen extends StatelessWidget {
  const EditScreen({super.key});

  void _showTool(BuildContext context, String tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a14),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 28, right: 28, top: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(tool, style: AppFonts.playfair(
              size: 24, weight: FontWeight.w900, color: AppColors.gold)),
          const SizedBox(height: 12),
          Text('Select an image from your gallery first to use this tool.',
              textAlign: TextAlign.center,
              style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 24),
          GoldButton(
            label: 'OPEN GALLERY',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GalleryScreen()));
            },
          ),
          const SizedBox(height: 12),
          GoldButton(
            label: 'CANCEL',
            outlined: true,
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    void push(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => push(const ProfileScreen()),
            onSettingsTap: () => push(const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  // Section Header - matching ExploreScreen style
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDIT SUITE',
                        style: AppFonts.poppins(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Refine Your Content',
                        style: AppFonts.playfair(
                          size: 32,
                          weight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a generated image and apply edits.',
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Edit Tools Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _editTool(context, Icons.crop, 'Crop & Resize', AppColors.gold),
                      _editTool(context, Icons.tune, 'Filters & Tone', const Color(0xFF9B59B6)),
                      _editTool(context, Icons.text_fields, 'Add Caption', const Color(0xFF3498DB)),
                      _editTool(context, Icons.auto_fix_high, 'AI Enhance', const Color(0xFF27AE60)),
                      _editTool(context, Icons.layers_outlined, 'Overlays', const Color(0xFFE74C3C)),
                      _editTool(context, Icons.ios_share_outlined, 'Export', AppColors.gold),
                    ],
                  ),

                  const SizedBox(height: 32),

                  GoldButton(
                    label: 'OPEN GALLERY',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GalleryScreen())),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        'Full edit suite coming in Phase 2.',
                        style: AppFonts.poppins(size: 11, color: AppColors.gold, height: 1.6),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editTool(BuildContext context, IconData icon, String label, Color color) {
    return DarkCard(
      onTap: () => _showTool(context, label),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(label, textAlign: TextAlign.center,
            style: AppFonts.poppins(size: 11, weight: FontWeight.w600, color: AppColors.text)),
      ]),
    );
  }
}
