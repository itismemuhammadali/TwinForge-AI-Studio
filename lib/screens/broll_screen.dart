import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../services/stock_image_service.dart';
import '../services/fal_ai_service.dart';
import '../services/storage_service.dart';
import 'package:video_player/video_player.dart';
import 'broll_video_review_screen.dart';

class BrollScreen extends StatefulWidget {
  final GeneratedContent? content;
  final File? initialImage;
  const BrollScreen({super.key, this.content, this.initialImage});
  @override
  State<BrollScreen> createState() => _BrollScreenState();
}

class _BrollScreenState extends State<BrollScreen> {
  bool _hasImage = false;
  File? _localImage;
  int? _selectedTemplateIndex;
  bool _isGenerating = false;
  
  List<StockVideo> _templates = [];
  bool _isLoadingTemplates = true;

  @override
  void initState() {
    super.initState();
    if (widget.content != null || widget.initialImage != null) {
      _hasImage = true;
      if (widget.initialImage != null) {
        _localImage = widget.initialImage;
      }
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final videos = await StockImageService.searchBRollVideos(perPage: 10);
      if (mounted) {
        setState(() {
          _templates = videos;
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTemplates = false);
      }
    }
  }

  Future<void> _generateBRoll() async {
    if (_selectedTemplateIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video template first')),
      );
      return;
    }

    if (!_hasImage && _localImage == null && widget.content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your face photo')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    debugPrint('🚀 Starting _generateBRoll process...');

    try {
      final templateVideoUrl = _templates[_selectedTemplateIndex!].videoUrl;
      debugPrint('🎥 Template Video URL: $templateVideoUrl');
      String faceImageUrl = '';

      // 1. Handle Face Image Source
      if (_localImage != null) {
        debugPrint('📤 Uploading local image to Firebase Storage...');
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        final fileName = 'broll_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
        faceImageUrl = await StorageService.uploadImage(
          _localImage!, 
          'users/$uid/referenceImages/$fileName'
        );
        debugPrint('✅ Face Image Uploaded: $faceImageUrl');
      } else if (widget.content != null) {
        faceImageUrl = widget.content!.editedImageUrl ?? widget.content!.originalImageUrl;
        debugPrint('🖼️ Using existing content image: $faceImageUrl');
      }

      if (faceImageUrl.isEmpty) throw Exception('Could not resolve face image URL');

      // 2. Call Video Face Swap Service
      debugPrint('🤖 Calling FAL AI Face Swap Service...');
      final resultUrl = await FalAiService().generateBRoll(
        faceImageUrl: faceImageUrl,
        templateVideoUrl: templateVideoUrl,
      );
      debugPrint('🎊 Face Swap Success! Result URL: $resultUrl');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrollVideoReviewScreen(
              videoUrl: resultUrl,
              durationSeconds: 10,
              prompt: 'B-Roll Face Swap with template: ${_templates[_selectedTemplateIndex!].title}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _localImage = File(picked.path);
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

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourceBottomSheet(
        onSourceSelected: _pickImage,
        title: 'UPLOAD YOUR FACE',
        subtitle: 'The AI will swap your face into the selected video',
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(children: [
            // Section Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'B-ROLL STUDIO',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI Face Swap Clips',
                  style: AppFonts.playfair(
                    size: 32,
                    weight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a template and upload your face to create cinematic clips of yourself',
                  style: AppFonts.poppins(
                    size: 13,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 1. Select Template (The base video)
            _buildTemplatesSection(),

            const SizedBox(height: 40),
            
            Row(children: [
              const Expanded(child: Divider(color: AppColors.surface, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('2. UPLOAD YOUR FACE', 
                  style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
              ),
              const Expanded(child: Divider(color: AppColors.surface, thickness: 1)),
            ]),
            
            const SizedBox(height: 32),

            // Upload (The face image)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity, height: 240,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _hasImage ? AppColors.gold.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: _hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _localImage != null
                            ? Image.file(_localImage!, fit: BoxFit.cover)
                            : widget.content != null
                                ? Image.network(
                                    widget.content!.editedImageUrl ?? widget.content!.originalImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppColors.surface,
                                      child: const Icon(Icons.image, color: AppColors.muted, size: 60),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.surface,
                                    child: const Icon(Icons.image, color: AppColors.muted, size: 60),
                                  ),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.face_retouching_natural_outlined, color: AppColors.gold, size: 40),
                        const SizedBox(height: 12),
                        Text('Upload Your Photo', style: AppFonts.playfair(size: 18, style: FontStyle.italic, color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text('Clear selfie works best', style: AppFonts.poppins(size: 11, color: AppColors.muted)),
                      ]),
              ),
            ),

            const SizedBox(height: 40),

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
                          'AI FACE SWAP ANALYSIS',
                          style: AppFonts.poppins(
                            size: 10,
                            weight: FontWeight.w800,
                            color: AppColors.gold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complex video face-swapping requires deep temporal analysis, which may take an extra moment.',
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

            GoldButton(
              label: _isGenerating ? 'GENERATING MAGIC...' : 'GENERATE FACE SWAP', 
              loading: _isGenerating,
              onTap: _isGenerating ? null : _generateBRoll,
            ),

            const SizedBox(height: 16),
            _comingSoonBadge('Using FAL AI Advanced Video Face Swap technology.'),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1. CHOOSE VIDEO STYLE',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 3,
              ),
            ),
            if (_templates.isNotEmpty)
              GestureDetector(
                onTap: () => _loadTemplates(),
                child: const Icon(Icons.refresh, color: AppColors.gold, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingTemplates)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          )
        else if (_templates.isEmpty)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('No templates found', style: AppFonts.poppins(color: AppColors.muted)),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final video = _templates[index];
                final isSelected = _selectedTemplateIndex == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTemplateIndex = index;
                  }),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.gold.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 10)
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(video.thumbnailUrl, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent, 
                                  isSelected ? AppColors.gold.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.6)
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle, color: AppColors.gold, size: 24),
                            ),
                          
                          // Play/Preview Button
                          Center(
                            child: GestureDetector(
                              onTap: () => _showPreviewDialog(video.videoUrl, video.title),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                                ),
                                child: const Icon(Icons.play_arrow, color: AppColors.gold, size: 28),
                              ),
                            ),
                          ),
                          
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.poppins(size: 9, weight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showPreviewDialog(String videoUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => _TemplatePreviewDialog(videoUrl: videoUrl, title: title),
    );
  }

  Widget _comingSoonBadge(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.gold.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(msg, style: AppFonts.poppins(size: 11, color: AppColors.gold))),
    ]),
  );
}

class _TemplatePreviewDialog extends StatefulWidget {
  final String videoUrl;
  final String title;

  const _TemplatePreviewDialog({required this.videoUrl, required this.title});

  @override
  State<_TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<_TemplatePreviewDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: _initialized ? _controller.value.aspectRatio : 16 / 9,
                  child: _initialized 
                    ? VideoPlayer(_controller)
                    : const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMPLATE PREVIEW',
                      style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: AppFonts.playfair(size: 20, color: Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    GoldButton(
                      label: 'CLOSE PREVIEW',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
