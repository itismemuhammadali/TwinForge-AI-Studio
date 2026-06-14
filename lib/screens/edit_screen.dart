import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'advanced_edit_screen.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _navigateToEditor() async {
    if (_selectedImage == null) return;
    
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => AdvancedEditScreen(image: _selectedImage!)),
    );
    
    if (result != null) {
      setState(() => _selectedImage = result);
    }
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
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
                    'Professional Editor',
                    style: AppFonts.playfair(
                      size: 32,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transform your ideas into visual masterpieces with our advanced editing tools.',
                    style: AppFonts.poppins(
                      size: 14,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (_selectedImage != null) ...[
                    // Preview Card when image is selected
                    Center(
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GoldButton(
                      label: 'ENTER EDIT SUITE',
                      onTap: _navigateToEditor,
                    ),
                  ] else ...[
                    // Upload Card
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.gold),
                            ),
                            const SizedBox(height: 20),
                            Text('Upload Image', style: AppFonts.poppins(size: 18, weight: FontWeight.w700, color: AppColors.white)),
                            const SizedBox(height: 8),
                            Text('From your device storage', style: AppFonts.poppins(size: 13, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Select from Library Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<File>(
                            context,
                            MaterialPageRoute(builder: (_) => const LibraryScreen(isSelectionMode: true)),
                          );
                          if (result != null) {
                            setState(() => _selectedImage = result);
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined, color: AppColors.gold),
                        label: Text('SELECT FROM LIBRARY', style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.gold, size: 18),
                            const SizedBox(width: 12),
                            Text('AI POWERED', style: AppFonts.poppins(size: 12, weight: FontWeight.w800, color: AppColors.gold, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our editor uses state-of-the-art AI to enhance, resize, and transform your content while preserving original quality.',
                          style: AppFonts.poppins(size: 12, color: AppColors.muted, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
