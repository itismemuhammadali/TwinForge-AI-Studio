import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  bool _loading = false;
  bool _uploadingPhoto = false;
  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _nameCtrl = TextEditingController(text: userProvider.displayName ?? '');
    _emailCtrl = TextEditingController(text: userProvider.email ?? '');
    _bioCtrl = TextEditingController(text: userProvider.bio ?? '');
    _profileImageUrl = userProvider.profileImageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() { _profileImage = File(picked.path); _uploadingPhoto = true; });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/profile/profile.jpg');

      await ref.putFile(
        _profileImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'profileImage': downloadUrl, 'lastUpdated': FieldValue.serverTimestamp()});

      // Update provider
      if (mounted) {
        context.read<UserProvider>().updateProfileImageUrl(downloadUrl);
        setState(() { _profileImageUrl = downloadUrl; _uploadingPhoto = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile photo updated!',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourceBottomSheet(
        title: 'UPDATE PHOTO',
        onSourceSelected: _pickAndUpload,
      ),
    );
  }

  void _saveProfile() {    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all fields',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    context.read<UserProvider>().updateUserProfile(
      displayName: _nameCtrl.text,
      email: _emailCtrl.text,
      bio: _bioCtrl.text,
    ).then((_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: AppFonts.poppins(color: AppColors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _loading = false);
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
                'EDIT PROFILE',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Update Your Information',
                style: AppFonts.playfair(
                  size: 28,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Avatar — camera badge bottom-right, tap badge to pick image
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Circle with person icon or actual photo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2a2a1a),
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
                        child: _uploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gold, strokeWidth: 2,
                                ),
                              )
                            : _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                    ? Image.network(_profileImageUrl!, fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.person, color: AppColors.gold, size: 50))
                                    : const Icon(Icons.person, color: AppColors.gold, size: 50),
                      ),
                    ),

                    // Gold camera badge — sits on the ring line, 50% in / 50% out
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: GestureDetector(
                        onTap: () => _showImageSourceSheet(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                            border: Border.all(
                              color: const Color(0xFF0E0E0A),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.black,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              AimrField(
                label: 'FULL NAME',
                controller: _nameCtrl,
              ),
              const SizedBox(height: 16),
              AimrField(
                label: 'EMAIL ADDRESS',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AimrField(
                label: 'BIO',
                controller: _bioCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              GoldButton(
                label: 'SAVE CHANGES',
                loading: _loading,
                onTap: _saveProfile,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
