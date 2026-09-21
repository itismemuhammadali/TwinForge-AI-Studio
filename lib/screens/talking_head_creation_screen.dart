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
import 'talking_head_audio_screen.dart';
import 'talking_head_video_review_screen.dart';
import '../utils/ai_consent_helper.dart';

class TalkingHeadCreationScreen extends StatefulWidget {
  final GeneratedContent? content;
  final File? initialImage;

  const TalkingHeadCreationScreen({
    super.key,
    this.content,
    this.initialImage,
  });

  @override
  State<TalkingHeadCreationScreen> createState() => _TalkingHeadCreationScreenState();
}

class _StyleOption {
  final String title;
  final IconData icon;

  const _StyleOption({required this.title, required this.icon});
}

class _TalkingHeadCreationScreenState extends State<TalkingHeadCreationScreen> {
  final _promptCtrl = TextEditingController(text: 'Talk passionately with natural hand gestures and subtle head tilts.');
  final OpenAiService _openAiService = OpenAiService();

  String _selectedStyle = 'Cinematic';
  String _selectedVideoModel = 'HeyGen';
  double _durationSeconds = 5.0;

  bool _isGenerating = false;
  String _statusMessage = '';
  late Widget _cachedImage;
  double? _imageAspectRatio;

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
    _resolveImageAspectRatio();
  }

  void _resolveImageAspectRatio() async {
    try {
      if (widget.initialImage != null) {
        final bytes = await widget.initialImage!.readAsBytes();
        final decoded = await decodeImageFromList(bytes);
        if (mounted && decoded.height > 0) {
          setState(() {
            _imageAspectRatio = decoded.width / decoded.height;
            _cachedImage = _buildImageDisplay();
          });
        }
      } else {
        final url = _imageUrl;
        if (url.startsWith('data:image')) {
          final base64Str = url.split(',')[1];
          final bytes = base64Decode(base64Str);
          final decoded = await decodeImageFromList(bytes);
          if (mounted && decoded.height > 0) {
            setState(() {
              _imageAspectRatio = decoded.width / decoded.height;
              _cachedImage = _buildImageDisplay();
            });
          }
        } else if (url.startsWith('http')) {
          final image = NetworkImage(url);
          final stream = image.resolve(const ImageConfiguration());
          stream.addListener(ImageStreamListener((info, _) {
            if (mounted && info.image.height > 0) {
              setState(() {
                _imageAspectRatio = info.image.width / info.image.height;
                _cachedImage = _buildImageDisplay();
              });
            }
          }));
        } else if (url.isNotEmpty) {
          final bytes = await File(url).readAsBytes();
          final decoded = await decodeImageFromList(bytes);
          if (mounted && decoded.height > 0) {
            setState(() {
              _imageAspectRatio = decoded.width / decoded.height;
              _cachedImage = _buildImageDisplay();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error resolving image aspect ratio: $e');
    }
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
    return '';
  }

  Future<void> _generateTalkingHeadVideo() async {
    final promptText = _promptCtrl.text.trim();
    if (_selectedVideoModel != 'HeyGen' && promptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe what your character should do first', style: AppFonts.poppins(size: 12)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Pre-generation Gatekeeper: Apple Guidelines 5.1.1(i) & 5.1.2(i)
    final hasConsent = await AiConsentHelper.ensureConsent(context);
    if (!hasConsent || !mounted) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = _selectedVideoModel == 'HeyGen'
          ? 'Uploading reference photo...'
          : 'Optimizing dynamic motion prompt...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String optimizedPrompt = '';
      if (_selectedVideoModel != 'HeyGen') {
        optimizedPrompt = await _openAiService.generateOptimizedVideoPrompt(
          userPrompt: promptText,
          style: _selectedStyle,
          videoModel: _selectedVideoModel,
        );
      }

      setState(() => _statusMessage = 'Uploading reference photo...');
      final uploadedImageUrl = await _uploadImageToStorage();

      if (_selectedVideoModel == 'HeyGen') {
        // HEYGEN DIRECT FLOW: Proceed directly to Audio Recording Screen!
        setState(() {
          _isGenerating = false;
          _statusMessage = '';
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TalkingHeadAudioScreen(
                avatarImageUrl: uploadedImageUrl,
                durationSeconds: _durationSeconds.toInt(),
                prompt: '',
                videoModel: 'HeyGen',
              ),
            ),
          );
        }
      } else {
        // Dynamic Motion Flow: Generate silent motion video first
        setState(() => _statusMessage = 'Generating dynamic talking head video...');
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TalkingHeadVideoReviewScreen(
                videoUrl: generatedVideoUrl,
                durationSeconds: _durationSeconds.toInt(),
                prompt: optimizedPrompt,
                hasAudioStitched: false,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Video generation error: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video generation error: $e', style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String> _uploadImageToStorage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = 'users/${user.uid}/talking_head/$timestamp.jpg';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CREATE TALKING HEAD',
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
            // 1. DYNAMIC IMAGE PREVIEW FRAME
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 200,
                  maxHeight: 340,
                ),
                child: AspectRatio(
                  aspectRatio: _imageAspectRatio ?? (3 / 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141410),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
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
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. CHOOSE VIDEO STYLE
            Row(
              children: [
                Text(
                  'CHOOSE VIDEO STYLE',
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
            Row(
              children: [
                Expanded(
                  child: _buildModelCard(
                    title: 'Talking Head',
                    subtitle: 'Podcast & Static Videos',
                    icon: Icons.person_outline_rounded,
                    isSelected: _selectedVideoModel == 'HeyGen',
                    onTap: () => setState(() => _selectedVideoModel = 'HeyGen'),
                    iconColor: const Color(0xFFD4AF37),
                    subtitleColor: const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModelCard(
                    title: 'Dynamic Talking',
                    subtitle: 'Natural Motion + Lip Sync',
                    icon: Icons.directions_walk_rounded,
                    isSelected: _selectedVideoModel == 'Kling 3.0 Pro' || _selectedVideoModel == 'Seedance 2.0',
                    onTap: () => setState(() => _selectedVideoModel = 'Kling 3.0 Pro'),
                    iconColor: const Color(0xFFA855F7),
                    subtitleColor: const Color(0xFFC084FC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedVideoModel == 'HeyGen' ? const Color(0xFF0D1527) : const Color(0xFF160E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedVideoModel == 'HeyGen' ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : const Color(0xFFA855F7).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _selectedVideoModel == 'HeyGen' ? Icons.record_voice_over_rounded : Icons.directions_walk_rounded,
                    size: 18,
                    color: _selectedVideoModel == 'HeyGen' ? const Color(0xFF3B82F6) : const Color(0xFFA855F7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedVideoModel == 'HeyGen'
                        ? Text(
                            'Perfect for podcast style clips and static talking videos with natural facial expressions and accurate lip sync.\nNo motion prompt needed.',
                            style: AppFonts.poppins(size: 11, color: const Color(0xFFD1D5DB), height: 1.4),
                          )
                        : Text.rich(
                            TextSpan(
                              style: AppFonts.poppins(size: 11, color: const Color(0xFFD1D5DB), height: 1.4),
                              children: const [
                                TextSpan(text: 'Create dynamic talking videos with natural body movement and gestures. Walk, sit, stand or interact naturally while speaking.\nIncludes '),
                                TextSpan(text: 'Motion Library', style: TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.w600)),
                                TextSpan(text: ' and custom motion control.'),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            if (_selectedVideoModel != 'HeyGen') ...[
              const SizedBox(height: 24),

              // 3. PROMPT / DESCRIPTION INPUT
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
                    hintText: 'Talk passionately with natural hand gestures...',
                    hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    counterStyle: AppFonts.poppins(size: 10, color: AppColors.muted),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. CHOOSE VISUAL STYLE
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
            ],

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

            // STATUS MESSAGE OVERLAY
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
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
                        style: AppFonts.poppins(size: 12, color: AppColors.gold, weight: FontWeight.w500),
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
                onPressed: _isGenerating ? null : _generateTalkingHeadVideo,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedVideoModel == 'HeyGen' ? Icons.mic_rounded : Icons.auto_awesome,
                      color: Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isGenerating
                              ? (_selectedVideoModel == 'HeyGen' ? 'PREPARING AUDIO RECORDING...' : 'GENERATING DYNAMIC TALKING HEAD...')
                              : (_selectedVideoModel == 'HeyGen' ? 'NEXT: RECORD AUDIO' : 'GENERATE DYNAMIC TALKING HEAD'),
                          style: AppFonts.poppins(
                            size: 13.5,
                            weight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 0.8,
                          ),
                        ),
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
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color iconColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: _isGenerating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.08) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? iconColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? iconColor : AppColors.muted.withValues(alpha: 0.6),
              size: 16,
            ),
            const SizedBox(width: 6),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.poppins(
                      size: 8.5,
                      weight: FontWeight.w500,
                      color: isSelected ? subtitleColor : AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        fit: BoxFit.contain,
        alignment: Alignment.center,
      );
    }

    final url = _imageUrl;
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',')[1];
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      );
    } else if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Center(child: Icon(Icons.broken_image, color: AppColors.muted, size: 40)),
        ),
      );
    } else if (url.isNotEmpty) {
      return Image.file(
        File(url),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Center(child: Icon(Icons.person, color: AppColors.gold, size: 40)),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: const Center(child: Icon(Icons.image, color: AppColors.gold, size: 40)),
    );
  }
}
