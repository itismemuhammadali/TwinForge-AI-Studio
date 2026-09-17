import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/talking_head_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'talking_head_setup_screen.dart';
import '../library_screen.dart';

class TalkingHeadOptionsScreen extends StatefulWidget {
  const TalkingHeadOptionsScreen({super.key});

  @override
  State<TalkingHeadOptionsScreen> createState() => _TalkingHeadOptionsScreenState();
}

class _TalkingHeadOptionsScreenState extends State<TalkingHeadOptionsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        context.read<TalkingHeadProvider>().setSelectedImage(File(pickedFile.path));
        _navigateToSetup();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickFromLibrary() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Not authenticated');
        return;
      }

      // Navigate to library screen in selection mode
      if (!mounted) return;
      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => const LibraryScreen(isSelectionMode: true),
        ),
      );

      if (result != null && mounted) {
        context.read<TalkingHeadProvider>().setSelectedImage(result);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TalkingHeadSetupScreen(),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to load library: $e');
    }
  }

  void _navigateToSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TalkingHeadSetupScreen(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppFonts.poppins(color: AppColors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SELECT IMAGE SOURCE',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Gallery Card
              _buildOptionCard(
                icon: Icons.image_outlined,
                title: 'UPLOAD FROM GALLERY',
                subtitle: 'Pick an image from your device',
                onTap: _pickFromGallery,
              ),
              const SizedBox(height: 16),

              // Library Card
              _buildOptionCard(
                icon: Icons.collections_outlined,
                title: 'SELECT FROM LIBRARY',
                subtitle: 'Choose from your Twinora library',
                onTap: _pickFromLibrary,
              ),
              const SizedBox(height: 16),

              // Template Card
              _buildOptionCard(
                icon: Icons.palette_outlined,
                title: 'CREATE TEMPLATE',
                subtitle: 'Generate a new image',
                onTap: () {
                  // Navigate to template/image generation screen
                  // For now, just pop back
                  Navigator.pop(context);
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: GoldButton(
                  label: 'GO BACK',
                  outlined: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.gold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.poppins(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppFonts.poppins(
                      size: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
