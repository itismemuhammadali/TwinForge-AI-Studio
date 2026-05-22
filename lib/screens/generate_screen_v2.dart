import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/custom_dropdown.dart';
import '../constants/generation_options.dart';
import '../services/gemini_service.dart';
import '../providers/user_provider.dart';
import 'generated_images_screen.dart';

class GenerateScreenV2 extends StatefulWidget {
  const GenerateScreenV2({super.key});

  @override
  State<GenerateScreenV2> createState() => _GenerateScreenV2State();
}

class _GenerateScreenV2State extends State<GenerateScreenV2> {
  late GeminiService _geminiService;
  bool _isGenerating = false;
  File? _selectedImage;
  int _numberOfImages = 1;
  String _selectedGender = 'Female';
  final TextEditingController _propEnhancersCtrl = TextEditingController();

  // Dropdown values - always use first item from the actual list
  String _outfit = GenerationOptions.femaleOutfitStyles[0];
  String _location = GenerationOptions.locations[0];
  String _hairstyle = GenerationOptions.hairstyles[0];
  String _makeup = GenerationOptions.makeupLooks[0];
  String _angle = GenerationOptions.cameraAngles[0];
  String _skin = GenerationOptions.skinStyles[0];
  String _mood = GenerationOptions.moods[0];
  String _height = GenerationOptions.heights[0];
  String _bust = GenerationOptions.bustSizes[0];
  String _waist = GenerationOptions.waistSizes[0];
  String _hips = GenerationOptions.hipsSizes[0];
  String _aspectRatio = GenerationOptions.aspectRatios[0];

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    
    // Get user gender from UserProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userGender != null) {
        final gender = userProvider.userGender!;
        setState(() {
          _selectedGender = gender;
          if (gender == 'Male') {
            _outfit = GenerationOptions.maleOutfitStyles[0];
            _location = GenerationOptions.maleLocations[0];
            _hairstyle = GenerationOptions.maleHairstyles[0];
            _mood = GenerationOptions.maleMoods[0];
            _height = GenerationOptions.maleHeights[0];
            _makeup = GenerationOptions.maleGrooming[0];
            _bust = GenerationOptions.maleChestSizes[0];
            _waist = GenerationOptions.maleWaistSizes[0];
            _hips = GenerationOptions.malePhysique[0];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _propEnhancersCtrl.dispose();
    super.dispose();
  }

  List<String> _getOutfitOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleOutfitStyles
        : GenerationOptions.femaleOutfitStyles;
  }

  List<String> _getLocationOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleLocations
        : GenerationOptions.locations;
  }

  List<String> _getHairstyleOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleHairstyles
        : GenerationOptions.hairstyles;
  }

  List<String> _getMoodOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleMoods
        : GenerationOptions.moods;
  }

  List<String> _getHeightOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleHeights
        : GenerationOptions.heights;
  }

  List<String> _getBustOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleChestSizes
        : GenerationOptions.bustSizes;
  }

  List<String> _getWaistOptions() {
    return _selectedGender == 'Male'
        ? GenerationOptions.maleWaistSizes
        : GenerationOptions.waistSizes;
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SELECT IMAGE SOURCE',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to upload your photo',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 28),
              // Camera option
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 90,
                  );
                  if (pickedFile != null) {
                    setState(() => _selectedImage = File(pickedFile.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take a Photo',
                            style: AppFonts.poppins(
                              size: 15,
                              weight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Open camera and take a selfie',
                            style: AppFonts.poppins(
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.gold.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Gallery option
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 90,
                  );
                  if (pickedFile != null) {
                    setState(() => _selectedImage = File(pickedFile.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.photo_library,
                          color: AppColors.white.withValues(alpha: 0.7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose from Gallery',
                            style: AppFonts.poppins(
                              size: 15,
                              weight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pick an existing photo',
                            style: AppFonts.poppins(
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.white.withValues(alpha: 0.3),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateImages() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload an image first',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate images using Gemini with reference image
      final generatedImages = await _geminiService.generateImagesWithReference(
        referenceImage: _selectedImage!,
        outfit: _outfit,
        location: _location,
        hairstyle: _hairstyle,
        makeup: _makeup,
        angle: _angle,
        skin: _skin,
        mood: _mood,
        height: _height,
        bust: _bust,
        waist: _waist,
        hips: _hips,
        aspectRatio: _aspectRatio,
        numberOfImages: _numberOfImages,
      );

      // Count successful images (not errors)
      final successCount = generatedImages.where((img) => img != 'error').length;

      // Deduct credits in Firestore
      if (successCount > 0) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({
            'credits': FieldValue.increment(-successCount),
            'imagesUsedToday': FieldValue.increment(successCount),
            'usageDate': DateTime.now().toIso8601String().split('T')[0],
          });
          if (mounted) {
            context.read<UserProvider>().refreshCredits();
          }
        }
      }

      if (mounted) {
        // Navigate to generated images screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GeneratedImagesScreen(
              generatedImages: generatedImages,
              outfit: _outfit,
              location: _location,
              hairstyle: _hairstyle,
              makeup: _makeup,
              angle: _angle,
              mood: _mood,
              skin: _skin,
              height: _height,
              bust: _bust,
              waist: _waist,
              hips: _hips,
              gender: _selectedGender,
              aspectRatio: _aspectRatio,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: const AimrAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'GENERATE',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create Your Perfect Image',
                style: AppFonts.playfair(
                  size: 32,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload a photo and customize with filters',
                style: AppFonts.poppins(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Gender Selector
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'GENDER:',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedGender = 'Female';
                                _outfit = GenerationOptions.femaleOutfitStyles[0];
                                _location = GenerationOptions.locations[0];
                                _hairstyle = GenerationOptions.hairstyles[0];
                                _mood = GenerationOptions.moods[0];
                                _height = GenerationOptions.heights[0];
                                _makeup = GenerationOptions.makeupLooks[0];
                                _bust = GenerationOptions.bustSizes[0];
                                _waist = GenerationOptions.waistSizes[0];
                                _hips = GenerationOptions.hipsSizes[0];
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Female'
                                      ? AppColors.gold.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedGender == 'Female'
                                        ? AppColors.gold
                                        : AppColors.gold.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Female',
                                    style: AppFonts.poppins(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: _selectedGender == 'Female'
                                          ? AppColors.gold
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedGender = 'Male';
                                _outfit = GenerationOptions.maleOutfitStyles[0];
                                _location = GenerationOptions.maleLocations[0];
                                _hairstyle = GenerationOptions.maleHairstyles[0];
                                _mood = GenerationOptions.maleMoods[0];
                                _height = GenerationOptions.maleHeights[0];
                                _makeup = GenerationOptions.maleGrooming[0];
                                _bust = GenerationOptions.maleChestSizes[0];
                                _waist = GenerationOptions.maleWaistSizes[0];
                                _hips = GenerationOptions.malePhysique[0];
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Male'
                                      ? AppColors.gold.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedGender == 'Male'
                                        ? AppColors.gold
                                        : AppColors.gold.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Male',
                                    style: AppFonts.poppins(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: _selectedGender == 'Male'
                                          ? AppColors.gold
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Image Upload Placeholder
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.gold,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.gold
                                                .withValues(alpha: 0.6),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.black,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'TAP TO CHANGE IMAGE',
                                      style: AppFonts.poppins(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: AppColors.gold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: AppColors.gold,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'TAP TO UPLOAD PHOTO',
                              style: AppFonts.poppins(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.gold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Take a selfie or upload from gallery',
                              style: AppFonts.poppins(
                                size: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Number of Images Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUMBER OF IMAGES',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus Button
                        GestureDetector(
                          onTap: _numberOfImages > 1
                              ? () => setState(() => _numberOfImages--)
                              : null,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _numberOfImages > 1
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : AppColors.gold.withValues(alpha: 0.05),
                              border: Border.all(
                                color: _numberOfImages > 1
                                    ? AppColors.gold.withValues(alpha: 0.4)
                                    : AppColors.gold.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: _numberOfImages > 1
                                  ? AppColors.gold
                                  : AppColors.gold.withValues(alpha: 0.3),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Number Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _numberOfImages.toString(),
                            style: AppFonts.playfair(
                              size: 32,
                              weight: FontWeight.w900,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Plus Button
                        GestureDetector(
                          onTap: _numberOfImages < 4
                              ? () => setState(() => _numberOfImages++)
                              : null,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _numberOfImages < 4
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : AppColors.gold.withValues(alpha: 0.05),
                              border: Border.all(
                                color: _numberOfImages < 4
                                    ? AppColors.gold.withValues(alpha: 0.4)
                                    : AppColors.gold.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: _numberOfImages < 4
                                  ? AppColors.gold
                                  : AppColors.gold.withValues(alpha: 0.3),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Dropdowns Grid
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'ATMOSPHERIC MOOD' : 'MOOD / VIBE',
                value: _mood,
                options: _getMoodOptions(),
                onChanged: (value) => setState(() => _mood = value),
                icon: Icons.mood,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'GEOGRAPHIC NODE' : 'LOCATION',
                value: _location,
                options: _getLocationOptions(),
                onChanged: (value) => setState(() => _location = value),
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'ELITE ATTIRE' : 'OUTFIT STYLE',
                value: _outfit,
                options: _getOutfitOptions(),
                onChanged: (value) => setState(() => _outfit = value),
                icon: Icons.checkroom,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'SIGNATURE HAIR' : 'HAIRSTYLE',
                value: _hairstyle,
                options: _getHairstyleOptions(),
                onChanged: (value) => setState(() => _hairstyle = value),
                icon: Icons.face,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'GROOMING' : 'MAKEUP LOOK',
                value: _makeup,
                options: _selectedGender == 'Male'
                    ? GenerationOptions.maleGrooming
                    : GenerationOptions.makeupLooks,
                onChanged: (value) => setState(() => _makeup = value),
                icon: Icons.palette,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'LENS ANGLE',
                value: _angle,
                options: GenerationOptions.cameraAngles,
                onChanged: (value) => setState(() => _angle = value),
                icon: Icons.camera_alt,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'SKIN STYLE',
                value: _skin,
                options: GenerationOptions.skinStyles,
                onChanged: (value) => setState(() => _skin = value),
                icon: Icons.spa,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'VERTICALITY' : 'HEIGHT',
                value: _height,
                options: _getHeightOptions(),
                onChanged: (value) => setState(() => _height = value),
                icon: Icons.height,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'CHEST SIZE' : 'BUST SIZE',
                value: _bust,
                options: _getBustOptions(),
                onChanged: (value) => setState(() => _bust = value),
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'WAIST SIZE',
                value: _waist,
                options: _getWaistOptions(),
                onChanged: (value) => setState(() => _waist = value),
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: _selectedGender == 'Male' ? 'PHYSIQUE' : 'HIPS SIZE',
                value: _hips,
                options: _selectedGender == 'Male'
                    ? GenerationOptions.malePhysique
                    : GenerationOptions.hipsSizes,
                onChanged: (value) => setState(() => _hips = value),
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'FRAME RATIO',
                value: _aspectRatio,
                options: GenerationOptions.aspectRatios,
                onChanged: (value) => setState(() => _aspectRatio = value),
                icon: Icons.aspect_ratio,
              ),
              const SizedBox(height: 16),

              // Prop Enhancers / Detail Prompts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PROP ENHANCERS / DETAIL PROMPTS',
                          style: AppFonts.poppins(
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _propEnhancersCtrl,
                      maxLines: 3,
                      style: AppFonts.poppins(
                        size: 13,
                        color: AppColors.white,
                      ),
                      cursorColor: AppColors.gold,
                      decoration: InputDecoration(
                        hintText: 'E.g. Holding a vintage Leica, wearing a Rolex Daytona...',
                        hintStyle: AppFonts.poppins(
                          size: 12,
                          color: AppColors.muted.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.05),
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Generate Button
              GoldButton(
                label: _isGenerating ? 'GENERATING...' : 'GENERATE IMAGES',
                loading: _isGenerating,
                onTap: _isGenerating ? null : _generateImages,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
