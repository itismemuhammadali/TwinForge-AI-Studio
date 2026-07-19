import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/admin_provider.dart';

class AdminEditScreen extends StatefulWidget {
  final AdminContent content;

  const AdminEditScreen({super.key, required this.content});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  File? _newImage;
  late String _selectedCategory;
  late List<String> _selectedTags;
  late TextEditingController _promptController;
  late TextEditingController _overlayPromptController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.content.category;
    _selectedTags = List<String>.from(widget.content.tags);
    _promptController = TextEditingController(text: widget.content.prompt ?? '');
    _overlayPromptController = TextEditingController(text: widget.content.overlayPrompt ?? '');
  }

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
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final success = await context.read<AdminProvider>().updateContent(
          contentId: widget.content.id,
          category: _selectedCategory != widget.content.category ? _selectedCategory : null,
          tags: _selectedTags,
          prompt: _promptController.text.isEmpty ? '' : _promptController.text,
          overlayPrompt: _overlayPromptController.text.isEmpty ? '' : _overlayPromptController.text,
          newImageFile: _newImage,
        );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated successfully!', style: AppFonts.poppins(size: 13)),
          backgroundColor: const Color(0xFF2a5a2a),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = context.read<AdminProvider>().errorMessage ?? 'Update failed';
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
          'EDIT CONTENT',
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
            _buildImagePicker(),
            const SizedBox(height: 28),

            Text(
              'CATEGORY',
              style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            _buildCategoryDropdown(),
            const SizedBox(height: 28),

            Text(
              'SHOW IN SECTIONS',
              style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 3),
            ),
            const SizedBox(height: 4),
            Text(
              'Select where this template should appear',
              style: AppFonts.poppins(size: 11, color: AppColors.muted.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            _buildTagCheckboxes(),
            const SizedBox(height: 28),

            Text(
              'AI PROMPT',
              style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            _buildPromptField(),
            const SizedBox(height: 28),

            const SizedBox(height: 36),

            _buildSaveButton(),
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
            color: _newImage != null
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.white.withValues(alpha: 0.1),
            width: _newImage != null ? 1.5 : 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_newImage != null)
                Image.file(_newImage!, fit: BoxFit.cover)
              else
                Image.network(
                  widget.content.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppColors.surface,
                    child: Icon(Icons.broken_image, color: AppColors.muted.withValues(alpha: 0.3)),
                  ),
                ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tap to replace image',
                      style: AppFonts.poppins(size: 12, color: AppColors.gold),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05), width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.gold.withValues(alpha: 0.6)),
          items: AdminProvider.categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(cat, style: AppFonts.poppins(size: 14, color: AppColors.white)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
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
                color: isSelected ? AppColors.gold : AppColors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: AppColors.black, size: 12) : null,
                ),
                const SizedBox(width: 8),
                Text(tag, style: AppFonts.poppins(
                  size: 12,
                  color: isSelected ? AppColors.gold : AppColors.muted,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
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
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w300, color: AppColors.text),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: 'Optional prompt for AI generation...',
        hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.05), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
        ),
      ),
    );
  }

  Widget _buildOverlayPromptField() {
    return TextField(
      controller: _overlayPromptController,
      maxLines: 4,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w300, color: AppColors.text),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: 'E.g. Title "SUCCESS" at top center, large bold white font...',
        hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.05), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _isSaving ? AppColors.gold.withValues(alpha: 0.5) : AppColors.gold,
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
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
              )
            : Text(
                'SAVE CHANGES',
                style: AppFonts.poppins(size: 12, weight: FontWeight.w900, color: AppColors.black, letterSpacing: 5),
              ),
      ),
    );
  }
}
