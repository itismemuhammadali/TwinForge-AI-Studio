import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  File? _selectedImage;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  final _promptController = TextEditingController();
  final _overlayPromptController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _overlayPromptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image and category', style: AppFonts.poppins(size: 13)),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final success = await context.read<AdminProvider>().uploadContent(
          imageFile: _selectedImage!,
          category: _selectedCategory!,
          tags: _selectedTags,
          prompt: _promptController.text.isEmpty ? null : _promptController.text,
          overlayPrompt: _overlayPromptController.text.isEmpty ? null : _overlayPromptController.text,
          uploadedBy: uid,
        );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload successful!', style: AppFonts.poppins(size: 13)),
          backgroundColor: const Color(0xFF2a5a2a),
        ),
      );
      setState(() {
        _selectedImage = null;
        _selectedCategory = null;
        _selectedTags = [];
        _promptController.clear();
        _overlayPromptController.clear();
      });
    } else {
      final error = context.read<AdminProvider>().errorMessage ?? 'Upload failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: AppFonts.poppins(size: 13)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'UPLOAD CONTENT',
          style: AppFonts.poppins(
            size: 13,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview / Picker
            _buildImagePicker(),
            const SizedBox(height: 28),

            // Category Dropdown
            Text(
              'CATEGORY',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryDropdown(),
            const SizedBox(height: 28),

            // Template Tags (Show in multiple sections)
            Text(
              'SHOW IN SECTIONS',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select where this template should appear',
              style: AppFonts.poppins(size: 11, color: AppColors.muted.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            _buildTagCheckboxes(),
            const SizedBox(height: 28),

            // AI Prompt (Optional)
            Text(
              'AI PROMPT (OPTIONAL)',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            _buildPromptField(),
            const SizedBox(height: 28),

            const SizedBox(height: 36),

            // Upload Button
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage != null
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.white.withValues(alpha: 0.1),
            width: _selectedImage != null ? 1.5 : 0.8,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.gold.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to select image',
                    style: AppFonts.poppins(
                      size: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          hint: Text(
            'Select category',
            style: AppFonts.poppins(size: 14, color: AppColors.muted),
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.gold.withValues(alpha: 0.6),
          ),
          items: AdminProvider.categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(
                cat,
                style: AppFonts.poppins(size: 14, color: AppColors.white),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildTagCheckboxes() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AdminProvider.templateTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTags.remove(tag);
              } else {
                _selectedTags.add(tag);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: AppColors.black, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  tag,
                  style: AppFonts.poppins(
                    size: 12,
                    color: isSelected ? AppColors.gold : AppColors.muted,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPromptField() {
    return TextField(
      controller: _promptController,
      maxLines: 3,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: AppColors.text,
      ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: 'Optional prompt for AI generation...',
        hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayPromptField() {
    return TextField(
      controller: _overlayPromptController,
      maxLines: 4,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: AppColors.text,
      ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: 'E.g. Title "SUCCESS" at top center, large bold white font...\nSubtitle "Your journey starts here" at bottom, small gold font...',
        hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _upload,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _isUploading ? AppColors.gold.withValues(alpha: 0.5) : AppColors.gold,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'UPLOAD',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w900,
                  color: AppColors.black,
                  letterSpacing: 5,
                ),
              ),
      ),
    );
  }
}
