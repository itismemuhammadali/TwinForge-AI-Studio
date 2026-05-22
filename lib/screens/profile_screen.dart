import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'subscription_screen.dart';
import 'library_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout?',
          style: AppFonts.playfair(
            size: 20,
            weight: FontWeight.w900,
            color: AppColors.gold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: AppFonts.poppins(
            size: 13,
            color: AppColors.muted,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text(
              'LOGOUT',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Column(
                children: [
                  const SizedBox(height: 32),

                  // Profile Avatar
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final imageUrl = userProvider.profileImageUrl;
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFF2a2a1a),
                                    child: const Icon(Icons.person, color: AppColors.gold, size: 50),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF2a2a1a),
                                  child: const Icon(Icons.person, color: AppColors.gold, size: 50),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // User Info
                  Text(
                    userProvider.displayName ?? 'User',
                    style: AppFonts.playfair(
                      size: 28,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userProvider.email ?? 'email@example.com',
                    style: AppFonts.poppins(
                      size: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.bolt,
                          label: 'Credits',
                          value: '${userProvider.credits ?? 0}',
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.star,
                          label: 'Plan',
                          value: _planLabel(userProvider.subscription),
                          color: const Color(0xFF9B59B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.image,
                          label: 'Created',
                          value: '${userProvider.imagesUsedToday ?? 0}',
                          color: const Color(0xFF3498DB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Menu Items
                  _menuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your information',
                    onTap: () => _push(context, const EditProfileScreen()),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.photo_library_outlined,
                    title: 'My Library',
                    subtitle: 'View your generated content',
                    color: const Color(0xFF3498DB),
                    onTap: () => _push(context, const LibraryScreen()),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.workspace_premium_outlined,
                    title: 'My Plan',
                    subtitle: 'Manage your subscription',
                    color: const Color(0xFF9B59B6),
                    onTap: () => _push(context, const SubscriptionScreen()),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your security',
                    onTap: () => _push(context, const ChangePasswordScreen()),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage your alerts',
                    onTap: () => _push(context, const NotificationsScreen()),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get assistance',
                    onTap: () => _push(context, const HelpSupportScreen()),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  GoldButton(
                    label: 'LOGOUT',
                    outlined: true,
                    onTap: () => _showLogoutDialog(context),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _planLabel(String? subscription) {
    switch (subscription) {
      case 'standard': return 'Standard';
      case 'creator': return 'Creator';
      default: return 'Trial';
    }
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppFonts.playfair(
              size: 20,
              weight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.poppins(
              size: 10,
              color: AppColors.muted,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.poppins(size: 14, weight: FontWeight.w600, color: AppColors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.muted.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
