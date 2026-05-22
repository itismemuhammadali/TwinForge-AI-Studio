import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late TextEditingController _currentCtrl;
  late TextEditingController _newCtrl;
  late TextEditingController _confirmCtrl;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentCtrl = TextEditingController();
    _newCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _changePassword() {
    setState(() => _error = null);

    if (_currentCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    if (_newCtrl.text.isEmpty) {
      setState(() => _error = 'Enter a new password');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password changed successfully!',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              Text(
                'SECURITY',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Change Password',
                style: AppFonts.playfair(
                  size: 28,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Keep your account secure by using a strong password',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Icon
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
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.gold,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),

              // Current Password
              _passwordField(
                label: 'CURRENT PASSWORD',
                controller: _currentCtrl,
                obscure: !_showCurrent,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
              ),
              const SizedBox(height: 16),

              // New Password
              _passwordField(
                label: 'NEW PASSWORD',
                controller: _newCtrl,
                obscure: !_showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _passwordField(
                label: 'CONFIRM PASSWORD',
                controller: _confirmCtrl,
                obscure: !_showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
              ),

              // Error Message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: AppFonts.poppins(
                      size: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Change Button
              GoldButton(
                label: 'CHANGE PASSWORD',
                loading: _loading,
                onTap: _changePassword,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.poppins(
            size: 10,
            weight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: AppFonts.poppins(
              size: 14,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.gold.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
