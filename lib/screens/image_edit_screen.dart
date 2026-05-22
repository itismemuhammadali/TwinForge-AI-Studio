import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/generated_content.dart';
import '../providers/content_provider.dart';
import '../providers/auth_provider.dart';
import '../services/gemini_service.dart';
import 'conversion_screen.dart';

class ImageEditScreen extends StatefulWidget {
  final GeneratedContent content;
  const ImageEditScreen({super.key, required this.content});

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> {
  late TextEditingController _editPromptCtrl;
  bool _isEditing = false;
  String? _editedImageUrl;

  @override
  void initState() {
    super.initState();
    _editPromptCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _editPromptCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyEdit() async {
    if (_editPromptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter an edit prompt',
              style: AppFonts.poppins(size: 12, color: AppColors.text)),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    setState(() => _isEditing = true);

    try {
      // Get image bytes from URL or base64
      final imageUrl = _editedImageUrl ?? widget.content.originalImageUrl;
      Uint8List imageBytes;

      if (imageUrl.startsWith('data:image')) {
        final base64Str = imageUrl.split(',')[1];
        imageBytes = base64Decode(base64Str);
      } else if (imageUrl.startsWith('https://')) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }
        imageBytes = response.bodyBytes;
      } else {
        throw Exception('Unsupported image format');
      }

      // Call Gemini to edit the image
      final result = await _callGeminiEdit(
        imageBytes: imageBytes,
        editPrompt: _editPromptCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _editedImageUrl = result;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image edited successfully!',
              style: AppFonts.poppins(color: AppColors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Edit failed: $e',
              style: AppFonts.poppins(color: AppColors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _callGeminiEdit({
    required Uint8List imageBytes,
    required String editPrompt,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=${GeminiService.apiKey}',
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Encode(imageBytes),
              }
            },
            {
              'text':
                  'Edit this image based on the following instruction: "$editPrompt". '
                  'Preserve the person\'s face, identity, skin tone, and body exactly as they are. '
                  'Only apply the requested change. Return a photorealistic, high quality result.',
            }
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['IMAGE', 'TEXT'],
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List?;
        if (parts != null) {
          for (final part in parts) {
            if (part['inlineData'] != null) {
              final mimeType = part['inlineData']['mimeType'] ?? 'image/png';
              final imageData = part['inlineData']['data'];
              return 'data:$mimeType;base64,$imageData';
            }
          }
        }
      }
      throw Exception('No image returned from Gemini');
    } else {
      final error = jsonDecode(response.body);
      final msg = error['error']?['message'] ?? 'Unknown error';
      throw Exception('Gemini API error: $msg');
    }
  }

  Future<void> _saveAndContinue() async {
    final authProvider = context.read<AuthProvider>();
    final contentProvider = context.read<ContentProvider>();

    if (!authProvider.isAuthenticated) return;

    final editedContent = GeneratedContent(
      id: widget.content.id,
      originalImageUrl: widget.content.originalImageUrl,
      editedImageUrl: _editedImageUrl ?? widget.content.originalImageUrl,
      prompt: widget.content.prompt,
      editPrompt: _editPromptCtrl.text,
      createdAt: widget.content.createdAt,
      contentType: 'edited',
      metadata: widget.content.metadata,
    );

    await contentProvider.saveContent(
      authProvider.currentUser!.uid,
      editedContent.toMap(),
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversionScreen(content: editedContent),
        ),
      );
    }
  }

  Widget _buildImageDisplay(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, height: 380, width: double.infinity);
      } catch (e) {
        return _imagePlaceholder();
      }
    } else if (imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 380,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => Container(
    height: 380,
    color: AppColors.surface,
    child: const Icon(Icons.image_not_supported_outlined,
        color: AppColors.muted, size: 60),
  );

  @override
  Widget build(BuildContext context) {
    final displayImage = _editedImageUrl ?? widget.content.originalImageUrl;

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
              Text('REFINE IMAGE',
                  style: AppFonts.poppins(
                    size: 10, weight: FontWeight.w700,
                    color: AppColors.gold, letterSpacing: 3,
                  )),
              const SizedBox(height: 8),
              Text('Edit Your Image',
                  style: AppFonts.playfair(
                    size: 32, weight: FontWeight.w900, color: AppColors.white,
                  )),
              const SizedBox(height: 8),
              Text(
                'Describe what you want to change and Twinora will apply it with AI.',
                textAlign: TextAlign.center,
                style: AppFonts.poppins(size: 13, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 32),

              // Image Preview
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 30, spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.7), width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildImageDisplay(displayImage),
                  ),
                ),
              ),

              // Show "edited" badge if image was edited
              if (_editedImageUrl != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Text('Edit applied',
                          style: AppFonts.poppins(
                            size: 11, weight: FontWeight.w600, color: Colors.green,
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Edit Prompt Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EDIT PROMPT',
                      style: AppFonts.poppins(
                        size: 10, weight: FontWeight.w700,
                        color: AppColors.gold, letterSpacing: 3,
                      )),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editPromptCtrl,
                    maxLines: 3,
                    style: AppFonts.poppins(size: 14, color: AppColors.text, height: 1.6),
                    cursorColor: AppColors.gold,
                    decoration: InputDecoration(
                      hintText: 'e.g. "Add sunglasses", "Change background to beach", "Add a suit jacket"...',
                      hintStyle: AppFonts.poppins(
                        size: 12,
                        color: AppColors.muted.withValues(alpha: 0.4),
                        height: 1.6,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.08), width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.4), width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Apply Edit Button
              GoldButton(
                label: _isEditing ? 'APPLYING EDIT...' : 'APPLY EDIT',
                loading: _isEditing,
                onTap: _isEditing ? null : _applyEdit,
              ),
              const SizedBox(height: 16),

              // Continue Button — only show after edit applied
              if (_editedImageUrl != null)
                GoldButton(
                  label: 'CONTINUE TO CONVERSION',
                  outlined: true,
                  onTap: _saveAndContinue,
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
