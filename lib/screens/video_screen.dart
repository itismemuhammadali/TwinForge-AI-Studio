import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../services/stock_image_service.dart';



class VideoScreen extends StatefulWidget {
  final StockVideo? templateVideo;
  const VideoScreen({super.key, this.templateVideo});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _FilterOption {
  final String name;
  final IconData icon;
  final double defaultValue;
  
  const _FilterOption({
    required this.name,
    required this.icon,
    required this.defaultValue,
  });
}

class _VideoScreenState extends State<VideoScreen> {
  File? _selectedImage;
  bool _hasImage = false;
  int _selectedFilter = 0;
  final ImagePicker _imagePicker = ImagePicker();
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  final TextEditingController _promptController = TextEditingController();

  final List<_FilterOption> _filters = [
    _FilterOption(name: 'Original', icon: Icons.image, defaultValue: 0),
    _FilterOption(name: 'Brightness', icon: Icons.brightness_4, defaultValue: 0),
    _FilterOption(name: 'Contrast', icon: Icons.contrast, defaultValue: 0),
    _FilterOption(name: 'Saturation', icon: Icons.palette, defaultValue: 0),
    _FilterOption(name: 'Blur', icon: Icons.blur_on, defaultValue: 0),
    _FilterOption(name: 'Sepia', icon: Icons.filter_vintage, defaultValue: 0),
    _FilterOption(name: 'Invert', icon: Icons.invert_colors, defaultValue: 0),
    _FilterOption(name: 'Grayscale', icon: Icons.filter_b_and_w, defaultValue: 0),
  ];

  @override
  void dispose() {
    _videoController?.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() {
    if (widget.templateVideo != null && _videoController == null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.templateVideo!.videoUrl),
      )..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error loading video: $error',
                style: AppFonts.poppins(color: AppColors.white),
              ),
              backgroundColor: AppColors.surface,
            ),
          );
        }
      });
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) {
      _initializeVideoPlayer();
      return;
    }

    if (_videoController!.value.isInitialized) {
      setState(() {
        if (_isVideoPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        _isVideoPlaying = !_isVideoPlaying;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
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

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.gold),
                title: Text('Take Photo', style: AppFonts.poppins(color: AppColors.white)),
                onTap: () {
                  _pickImageFromCamera();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.gold),
                title: Text('Choose from Gallery', style: AppFonts.poppins(color: AppColors.white)),
                onTap: () {
                  _pickImage();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(
        actions: [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIDEO',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Your Video',
                      style: AppFonts.playfair(
                        size: 32,
                        weight: FontWeight.w900,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload your photo and apply filters to create amazing videos',
                      style: AppFonts.poppins(
                        size: 13,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top: Video Template Display with Player
                if (widget.templateVideo != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _videoController != null &&
                                  _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : Image.network(
                                  widget.templateVideo!.thumbnailUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 250,
                                      color: AppColors.surface,
                                      child: Center(
                                        child: Icon(
                                          Icons.video_library,
                                          color: AppColors.muted,
                                          size: 60,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Play button overlay - only show when not playing
                        if (!_isVideoPlaying)
                          GestureDetector(
                            onTap: _toggleVideoPlayback,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(alpha: 0.6),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: AppColors.black,
                                size: 40,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Middle: Photo Upload (Wider)
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hasImage
                            ? AppColors.gold.withValues(alpha: 0.4)
                            : AppColors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: _hasImage && _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'Change Photo',
                                    style: AppFonts.poppins(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold
                                      .withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: AppColors.gold
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.gold,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Upload Your Photo',
                                style: AppFonts.playfair(
                                  size: 20,
                                  style: FontStyle.italic,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'TAP TO SELECT',
                                style: AppFonts.poppins(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Filters Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPLY FILTERS',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFilter == index;
                          final filter = _filters[index];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = index),
                            child: Container(
                              width: 80,
                              margin: EdgeInsets.only(
                                right: index < _filters.length - 1 ? 12 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.gold.withValues(alpha: 0.2)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.white
                                          .withValues(alpha: 0.1),
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    filter.icon,
                                    color: isSelected
                                        ? AppColors.gold
                                        : AppColors.muted,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    filter.name,
                                    style: AppFonts.poppins(
                                      size: 8,
                                      weight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.gold
                                          : AppColors.muted,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Prompt Text Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOM PROMPT',
                      style: AppFonts.poppins(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: TextField(
                        controller: _promptController,
                        maxLines: 4,
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.white,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Describe how you want your video to look...',
                          hintStyle: AppFonts.poppins(
                            size: 13,
                            color: AppColors.muted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Generate Button
                if (widget.templateVideo != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.gold,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREMIUM VIDEO EXTRACTION',
                                style: AppFonts.poppins(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: AppColors.gold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Processing video templates requires complex frame-by-frame analysis, which may take an extra moment.',
                                style: AppFonts.poppins(
                                  size: 11,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                GoldButton(
                  label: 'CREATE VIDEO',
                  onTap: () {
                    if (!_hasImage) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please upload a photo first',
                            style: AppFonts.poppins(color: AppColors.white),
                          ),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                      return;
                    }

                    // TODO: Implement video creation with:
                    // - Selected image (_selectedImage)
                    // - Selected filter (_filters[_selectedFilter].name)
                    // - Template video (widget.templateVideo)
                    // - Custom prompt (_promptController.text)
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
