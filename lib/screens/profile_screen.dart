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
import 'legal_document_viewer_screen.dart';
import '../providers/library_provider.dart';

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

  void _showDeleteUserDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_outlined, color: Colors.orangeAccent, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete User Data?',
                style: AppFonts.playfair(
                  size: 18,
                  weight: FontWeight.w900,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your generated AI portraits, videos, talking heads, library items, notifications, and activity records.\n\nYour account login and profile will remain active, but all created data will be wiped. This action cannot be undone.',
          style: AppFonts.poppins(
            size: 13,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
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
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting all user data and creations...', style: AppFonts.poppins(color: Colors.white)),
                  backgroundColor: Colors.orangeAccent,
                  duration: const Duration(seconds: 2),
                ),
              );

              final success = await context.read<AuthProvider>().deleteUserData();
              if (context.mounted) {
                if (success) {
                  // Refresh user provider & library provider immediately
                  context.read<UserProvider>().refreshCredits();
                  context.read<LibraryProvider>().refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All user data and creations have been permanently deleted.', style: AppFonts.poppins(color: Colors.white)),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete user data. Please try again.', style: AppFonts.poppins(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'DELETE DATA',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account?',
                style: AppFonts.playfair(
                  size: 18,
                  weight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your account?\n\nThis will immediately delete your account credentials, profile, and all associated data. You will be logged out immediately, and this account will cease to exist. This action is irreversible.',
          style: AppFonts.poppins(
            size: 13,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
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
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting account and all personal data...', style: AppFonts.poppins(color: Colors.white)),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 2),
                ),
              );

              final success = await context.read<AuthProvider>().deleteAccount();
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                } else {
                  final error = context.read<AuthProvider>().errorMessage;
                  if (error == 'requires-recent-login') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Security check: Please log out and log back in, then tap Delete Account again to verify identity.', style: AppFonts.poppins(color: Colors.white)),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Account deletion failed: $error', style: AppFonts.poppins(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              'DELETE FOREVER',
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: Colors.redAccent,
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
                                  gaplessPlayback: true,
                                  cacheWidth: 200,
                                  cacheHeight: 200,
                                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                    if (wasSynchronouslyLoaded || frame != null) return child;
                                    return Container(
                                      color: const Color(0xFF2a2a1a),
                                      child: const Icon(Icons.person, color: AppColors.gold, size: 50),
                                    );
                                  },
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
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.flag_outlined,
                    title: 'Report Offensive Content',
                    subtitle: 'Flag objectionable AI-generated media',
                    onTap: () => showReportContentDialog(
                      context,
                      contentId: 'profile_menu_report',
                      contentType: 'In-App Content Report',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data & AI Consent Section (Apple Guidelines 5.1.1(i) & 5.1.2(i))
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DATA & PRIVACY CONSENT',
                        style: AppFonts.poppins(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: userProvider.aiDataConsentGranted
                            ? AppColors.gold.withValues(alpha: 0.3)
                            : Colors.white10,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Third-Party AI Processing',
                                style: AppFonts.poppins(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userProvider.aiDataConsentGranted
                                    ? 'Allowed (Photos, Videos & Audio sent only upon generation)'
                                    : 'Disabled (Generation will require consent)',
                                style: AppFonts.poppins(
                                  size: 11,
                                  color: userProvider.aiDataConsentGranted
                                      ? AppColors.gold
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: userProvider.aiDataConsentGranted,
                          activeThumbColor: AppColors.gold,
                          activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                          onChanged: (val) async {
                            await userProvider.setAiDataConsent(val);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? 'AI data processing consent granted'
                                        : 'AI data processing consent revoked',
                                    style: AppFonts.poppins(color: Colors.white),
                                  ),
                                  backgroundColor: val ? AppColors.surface : Colors.redAccent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legal & Policies Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'LEGAL & POLICIES',
                      style: AppFonts.poppins(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  _menuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Data protection & AI processing notice',
                    color: AppColors.gold,
                    onTap: () => _push(context, const LegalDocumentViewerScreen(documentType: LegalDocumentType.privacyPolicy)),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service & EULA',
                    subtitle: 'Subscription terms & user agreement',
                    color: AppColors.gold,
                    onTap: () => _push(context, const LegalDocumentViewerScreen(documentType: LegalDocumentType.termsOfService)),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.delete_outline,
                    title: 'Account & Data Deletion',
                    subtitle: 'How to delete your account and data',
                    color: Colors.redAccent,
                    onTap: () => _push(context, const LegalDocumentViewerScreen(documentType: LegalDocumentType.accountDeletion)),
                  ),
                  const SizedBox(height: 12),
                  _menuItem(
                    icon: Icons.info_outline,
                    title: 'About Us',
                    subtitle: 'Company background & contact info',
                    color: const Color(0xFF3498DB),
                    onTap: () => _push(context, const LegalDocumentViewerScreen(documentType: LegalDocumentType.aboutUs)),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  GoldButton(
                    label: 'LOGOUT',
                    outlined: true,
                    onTap: () => _showLogoutDialog(context),
                  ),
                  const SizedBox(height: 32),

                  // Data & Account Management Section (Apple Guideline 5.1.1(v) Compliance)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'DATA & PRIVACY MANAGEMENT',
                              style: AppFonts.poppins(
                                size: 11,
                                weight: FontWeight.w800,
                                color: Colors.redAccent,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can choose to wipe your created creations and library, or permanently terminate and delete your entire account.',
                          textAlign: TextAlign.center,
                          style: AppFonts.poppins(
                            size: 11,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Button 1: Delete User Data
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteUserDataDialog(context),
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.orangeAccent, size: 18),
                          label: Text(
                            'DELETE USER DATA',
                            style: AppFonts.poppins(
                              size: 11,
                              weight: FontWeight.w800,
                              color: Colors.orangeAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orangeAccent, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Button 2: Delete Account
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteAccountDialog(context),
                          icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 18),
                          label: Text(
                            'DELETE ACCOUNT',
                            style: AppFonts.poppins(
                              size: 11,
                              weight: FontWeight.w800,
                              color: Colors.redAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
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
