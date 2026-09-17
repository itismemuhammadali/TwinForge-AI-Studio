import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';

class PremiumHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final String? creditsText;

  const PremiumHeader({
    super.key,
    this.onProfileTap,
    this.onSettingsTap,
    this.creditsText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0A),
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top row: Profile, Logo, Settings
              Row(
                children: [
                  // Profile Button
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final imageUrl = userProvider.profileImageUrl;
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            color: AppColors.surface.withValues(alpha: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.1),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    cacheWidth: 120,
                                    cacheHeight: 120,
                                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                      if (wasSynchronouslyLoaded || frame != null) return child;
                                      return Container(
                                        color: const Color(0xFF2a2a1a),
                                        child: const Icon(Icons.person, color: AppColors.gold, size: 22),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF2a2a1a),
                                      child: const Icon(Icons.person, color: AppColors.gold, size: 22),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF2a2a1a),
                                    child: const Icon(Icons.person, color: AppColors.gold, size: 22),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  // Center Logo
                  Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'TWIN',
                              style: AppFonts.playfair(
                                size: 24,
                                weight: FontWeight.w900,
                                color: AppColors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'ORA',
                              style: AppFonts.playfair(
                                size: 24,
                                weight: FontWeight.w900,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AI TWIN STUDIO',
                        style: AppFonts.poppins(
                          size: 7,
                          weight: FontWeight.w700,
                          color: AppColors.gold.withValues(alpha: 0.6),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Notification Bell with unread badge
                  GestureDetector(
                    onTap: onSettingsTap,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.gold,
                              size: 20,
                            ),
                          ),
                          // Unread count badge
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _UnreadBadge(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom row: Credits/Status
              if (creditsText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        creditsText!,
                        style: AppFonts.poppins(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 0.5,
                        ),
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

// ── Unread notifications badge ────────────────────────────────────────────
class _UnreadBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0E0E0A), width: 1.5),
          ),
          child: Center(
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}
