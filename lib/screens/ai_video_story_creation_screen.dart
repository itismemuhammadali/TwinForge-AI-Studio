import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/generated_content.dart';
import '../services/open_ai_service.dart';
import '../services/fal_ai_service.dart';
import '../services/storage_service.dart';
import '../services/credit_service.dart';
import '../models/credit_config.dart';
import 'ai_video_story_result_screen.dart';
import '../utils/ai_consent_helper.dart';

class AiVideoStoryCreationScreen extends StatefulWidget {
  final GeneratedContent? content;
  final File? initialImage;
  final String? initialImageUrl;

  const AiVideoStoryCreationScreen({
    super.key,
    this.content,
    this.initialImage,
    this.initialImageUrl,
  });

  @override
  State<AiVideoStoryCreationScreen> createState() => _AiVideoStoryCreationScreenState();
}

class _StyleOption {
  final String title;
  final IconData icon;

  const _StyleOption({required this.title, required this.icon});
}

class _AiVideoStoryCreationScreenState extends State<AiVideoStoryCreationScreen> {
  final _promptCtrl = TextEditingController(text: 'Cinematic slow-motion shot enjoying the moment with a gentle breeze.');
  final OpenAiService _openAiService = OpenAiService();

  String _selectedStyle = 'Cinematic';
  final String _selectedVideoModel = 'Kling 1.6';
  double _durationSeconds = 5.0;

  bool _isGenerating = false;
  String _statusMessage = '';
  late final Widget _cachedImage;

  final List<_StyleOption> _styles = const [
    _StyleOption(
      title: 'Cinematic',
      icon: Icons.movie_creation_rounded,
    ),
    _StyleOption(
      title: 'UGC',
      icon: Icons.smartphone_rounded,
    ),
    _StyleOption(
      title: 'Luxury',
      icon: Icons.auto_awesome_rounded,
    ),
    _StyleOption(
      title: 'Viral Reel',
      icon: Icons.whatshot_rounded,
    ),
    _StyleOption(
      title: 'Netflix Documentary',
      icon: Icons.camera_roll_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cachedImage = _buildImageDisplay();
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  String get _imageUrl {
    if (widget.initialImage != null) {
      return widget.initialImage!.path;
    }
    if (widget.content != null) {
      return widget.content!.editedImageUrl ?? widget.content!.originalImageUrl;
    }
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return widget.initialImageUrl!;
    }
    return '';
  }

  Future<void> _generateBrollVideo() async {
    final promptText = _promptCtrl.text.trim();
    if (promptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe what your character should do first', style: AppFonts.poppins(size: 12)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final durationSec = _durationSeconds.toInt();

    // Pre-generation Gatekeeper: Apple Guidelines 5.1.1(i) & 5.1.2(i)
    final hasConsent = await AiConsentHelper.ensureConsent(context);
    if (!hasConsent || !mounted) return;

    final requiredCredits = CreditConfig.getKlingCredits(durationSec, '1080p');
    final hasCredits = await CreditService.ensureSufficientCredits(
      context,
      requiredCredits: requiredCredits,
      featureName: 'B-Roll Video Generation',
    );
    if (!hasCredits) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Optimizing cinematic video prompt...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 1. PROMPT INTELLIGENCE LAYER
      final String optimizedPrompt = await _openAiService.generateOptimizedVideoPrompt(
        userPrompt: promptText,
        style: _selectedStyle,
        videoModel: _selectedVideoModel,
      );

      // 2. UPLOAD IMAGE
      setState(() => _statusMessage = 'Uploading reference photo...');
      final uploadedImageUrl = await _uploadImageToStorage();

      // 3. GENERATE VIDEO
      setState(() => _statusMessage = 'Generating your cinematic video story...');
      final generatedVideoUrl = await FalAiService().generateVideoFromKling(
        imageUrl: uploadedImageUrl,
        prompt: optimizedPrompt,
        durationSeconds: _durationSeconds.toInt(),
      );

      setState(() {
        _isGenerating = false;
        _statusMessage = '';
      });

      if (mounted) {
        await CreditService.deductCredits(
          context: context,
          creditsToDeduct: requiredCredits,
          feature: 'kling_video',
          estimatedUsdCost: durationSec * 0.05,
          provider: 'Kling 3.0',
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiVideoStoryResultScreen(
              videoUrl: generatedVideoUrl,
              promptUsed: promptText,
              videoModel: _selectedVideoModel,
              style: _selectedStyle,
              durationSeconds: _durationSeconds.toInt(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusMessage = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation Error: $e', style: AppFonts.poppins(size: 12)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String> _uploadImageToStorage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = 'users/$userId/broll_inputs/$timestamp.jpg';

    if (_imageUrl.startsWith('http')) {
      final response = await http.get(Uri.parse(_imageUrl));
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      return await StorageService.uploadImage(tempFile, imagePath);
    } else if (_imageUrl.startsWith('data:image')) {
      final base64Str = _imageUrl.split(',')[1];
      final bytes = base64Decode(base64Str);
      return await StorageService.uploadImageBytes(bytes, imagePath);
    } else {
      final file = File(_imageUrl);
      return await StorageService.uploadImage(file, imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: Text(
          'CREATE B-ROLL',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE PREVIEW
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 25,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _cachedImage,
              ),
            ),

            const SizedBox(height: 24),

            // 2. PROMPT / DESCRIPTION INPUT
            Text(
              'WHAT DO YOU WANT TO HAPPEN?',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.8),
              ),
              child: TextField(
                controller: _promptCtrl,
                enabled: !_isGenerating,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                style: AppFonts.poppins(size: 13, color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Cinematic slow-motion shot enjoying the moment...',
                  hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  counterStyle: AppFonts.poppins(size: 10, color: AppColors.muted),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. CHOOSE VISUAL STYLE
            Text(
              'CHOOSE VISUAL STYLE',
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _styles.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final style = _styles[index];
                  final isSelected = _selectedStyle == style.title;
                  return GestureDetector(
                    onTap: _isGenerating ? null : () => setState(() => _selectedStyle = style.title),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.18)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            style.icon,
                            size: 16,
                            color: isSelected ? AppColors.gold : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            style.title,
                            style: AppFonts.poppins(
                              size: 13,
                              weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 4. CHOOSE VIDEO MODE
            Row(
              children: [
                Text(
                  'CHOOSE VIDEO MODE',
                  style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            _buildModelCard(
              title: 'Standard B-Roll',
              badge: 'Cinematic Motion',
              isSelected: true,
              onTap: () {},
              logoColor: const Color(0xFF8B5CF6),
            ),

            const SizedBox(height: 24),

            // 5. VIDEO DURATION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VIDEO DURATION',
                        style: AppFonts.poppins(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.5),
                        ),
                        child: Text(
                          '${_durationSeconds.toInt()} sec',
                          style: AppFonts.poppins(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _isGenerating ? AppColors.muted : AppColors.gold,
                      inactiveTrackColor: AppColors.gold.withValues(alpha: 0.15),
                      thumbColor: _isGenerating ? AppColors.muted : AppColors.gold,
                      overlayColor: AppColors.gold.withValues(alpha: 0.2),
                      valueIndicatorColor: AppColors.gold,
                      valueIndicatorTextStyle: AppFonts.poppins(
                        color: AppColors.black,
                        weight: FontWeight.w700,
                        size: 11,
                      ),
                    ),
                    child: Slider(
                      value: _durationSeconds,
                      min: 1.0,
                      max: 15.0,
                      divisions: 14,
                      label: '${_durationSeconds.toInt()}s',
                      onChanged: _isGenerating
                          ? null
                          : (val) {
                              setState(() {
                                _durationSeconds = val;
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // STATUS MESSAGE OVERLAY / PROCESSING NOTICE
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.gold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.gold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please wait: Creating your video can take 2 to 3 minutes. Do not close the app.',
                              style: AppFonts.poppins(size: 11, color: Colors.white, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // GENERATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isGenerating ? null : _generateBrollVideo,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isGenerating ? 'GENERATING VIDEO...' : 'GENERATE B-ROLL VIDEO',
                      style: AppFonts.poppins(
                        size: 14,
                        weight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard({
    required String title,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
    required Color logoColor,
  }) {
    return GestureDetector(
      onTap: _isGenerating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: logoColor.withValues(alpha: 0.15),
                border: Border.all(color: logoColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Center(
                child: Icon(Icons.circle_outlined, color: logoColor, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    badge,
                    style: AppFonts.poppins(
                      size: 9,
                      weight: FontWeight.w500,
                      color: isSelected ? AppColors.gold : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (widget.initialImage != null) {
      return Image.file(
        widget.initialImage!,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final url = _imageUrl;
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',')[1];
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (url.startsWith('http')) {
      return Image.network(
        url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 220,
          color: AppColors.surface,
          child: const Center(child: Icon(Icons.broken_image, color: AppColors.muted, size: 40)),
        ),
      );
    } else if (url.isNotEmpty) {
      return Image.file(
        File(url),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 220,
          color: AppColors.surface,
          child: const Center(child: Icon(Icons.person, color: AppColors.gold, size: 40)),
        ),
      );
    }

    return Container(
      height: 220,
      color: AppColors.surface,
      child: const Center(child: Icon(Icons.image, color: AppColors.gold, size: 40)),
    );
  }
}
