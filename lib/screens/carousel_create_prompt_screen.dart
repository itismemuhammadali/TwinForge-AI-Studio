import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../models/carousel_models.dart';
import '../services/open_ai_service.dart';
import '../services/gemini_service.dart';
import '../services/credit_service.dart';
import '../models/credit_config.dart';
import 'carousel_template_picker_screen.dart';
import 'carousel_review_screen.dart';
import '../utils/ai_consent_helper.dart';

class CarouselCreatePromptScreen extends StatefulWidget {
  final File avatarImageFile;
  final CarouselTemplate selectedTemplate;

  const CarouselCreatePromptScreen({
    super.key,
    required this.avatarImageFile,
    required this.selectedTemplate,
  });

  @override
  State<CarouselCreatePromptScreen> createState() =>
      _CarouselCreatePromptScreenState();
}

class _CarouselCreatePromptScreenState
    extends State<CarouselCreatePromptScreen> {
  final _promptCtrl = TextEditingController();
  final OpenAiService _openAiService = OpenAiService();

  bool _isGenerating = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _createCarousel() async {
    final userPrompt = _promptCtrl.text.trim();
    if (userPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a prompt or topic for your carousel',
              style: AppFonts.poppins(size: 12)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pre-generation Gatekeeper: Apple Guidelines 5.1.1(i) & 5.1.2(i)
    final hasConsent = await AiConsentHelper.ensureConsent(context);
    if (!hasConsent || !mounted) return;

    final hasCredits = await CreditService.ensureSufficientCredits(
      context,
      requiredCredits: CreditConfig.geminiImageCredits,
      featureName: 'Carousel Generation',
    );
    if (!hasCredits) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Uploading avatar image...';
    });

    try {
      if (!mounted) return;
      setState(() => _statusMessage = 'Analyzing template layout with OpenAI Vision...');

      // Step 2: Analyze Template with OpenAI GPT-4o Vision
      final templateAnalysis = await _openAiService.analyzeCarouselTemplate(
        templateImageUrl: widget.selectedTemplate.imageUrl,
      );

      if (!mounted) return;
      setState(() => _statusMessage = 'Synthesizing topic prompt & style rules...');

      // Step 3: Synthesize User Prompt + Vision Analysis into Slide Prompt
      final synthesizedPrompt = await _openAiService.generateCarouselSynthesisPrompt(
        templateAnalysis: templateAnalysis,
        userPrompt: userPrompt,
        templateTitle: widget.selectedTemplate.title,
      );

      if (!mounted) return;
      setState(() => _statusMessage = 'Generating carousel slide image with OpenAI DALL-E 3...');

      // Step 4: Generate Carousel Slide Image using Reference Image Flow (Dynamic Magazine Solution)
      final geminiService = GeminiService();
      final results = await geminiService.generateImagesWithReference(
        referenceImage: widget.avatarImageFile,
        mood: 'Natural',
        location: 'Studio',
        outfit: 'As in photo',
        hairstyle: 'As in photo',
        makeup: 'Natural',
        skin: 'Natural',
        height: '170cm',
        bust: 'Medium',
        waist: 'Slim',
        hips: 'Medium',
        angle: 'Eye Level',
        aspectRatio: '9:16',
        numberOfImages: 1,
        customPrompt: synthesizedPrompt,
      );

      final String generatedImageUrl = (results.isNotEmpty && results.first != 'error')
          ? results.first
          : widget.selectedTemplate.imageUrl;

      // Build Carousel model with slides
      final carousel = Carousel(
        slides: [
          CarouselSlide(
            id: 1,
            backgroundImageUrl: generatedImageUrl,
            overlays: [],
          ),
        ],
      );

      if (mounted) {
        await CreditService.deductCredits(
          context: context,
          creditsToDeduct: CreditConfig.geminiImageCredits,
          feature: 'carousel_generation',
          estimatedUsdCost: CreditConfig.estimateGeminiCostUsd('Gemini 3.1 Flash', '9:16'),
          provider: 'Gemini',
        );

        if (!mounted) return;

        setState(() => _isGenerating = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CarouselReviewScreen(carousel: carousel),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Carousel generation error: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Carousel generation failed: $e',
                style: AppFonts.poppins(size: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'CAROUSEL PROMPT',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isGenerating
            ? _buildLoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Previews Row (Avatar + Template)
                    Row(
                      children: [
                        // Avatar Preview
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AVATAR',
                                style: AppFonts.poppins(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    widget.avatarImageFile,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Template Preview
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TEMPLATE',
                                style: AppFonts.poppins(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        widget.selectedTemplate.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.3),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Text(
                                          widget.selectedTemplate.title,
                                          style: AppFonts.poppins(
                                            size: 10,
                                            weight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Prompt Label
                    Text(
                      'CAROUSEL TOPIC & PROMPT',
                      style: AppFonts.poppins(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Prompt Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _promptCtrl,
                        maxLines: 5,
                        style: AppFonts.poppins(size: 13, color: AppColors.white),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. 5 secrets to scaling an AI startup in 2026',
                          hintStyle: AppFonts.poppins(
                              size: 13, color: AppColors.muted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Generate Button
                    GoldButton(
                      label: 'CREATE CAROUSEL',
                      onTap: _createCarousel,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating Your Carousel',
              style: AppFonts.playfair(
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: AppFonts.poppins(
                size: 12,
                color: AppColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Please wait 1 to 2 minutes while OpenAI Vision and AI models synthesize your template aesthetic into custom slide graphics.',
                style: AppFonts.poppins(size: 11, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
