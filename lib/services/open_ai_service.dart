import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'gemini_service.dart';

class OpenAiService {
  static String apiKey = '';
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize OpenAI Service with API key from Firebase Remote Config or fallback
  static Future<void> initialize() async {
    try {
      debugLog('🔍 Initializing OpenAI Service...');
      
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );

      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      apiKey = _remoteConfig.getString('openai_api_key');

      if (apiKey.isEmpty) {
        debugLog('⚠️ Remote Config openai_api_key is empty. Runtime override or fallback will be used.');
      } else {
        debugLog('✅ OpenAI API key loaded from Remote Config (${apiKey.length} chars)');
      }
    } catch (e) {
      debugLog('❌ Error initializing OpenAI Service: $e');
    }
  }

  /// Debug logging helper
  static void debugLog(String message) {
    developer.log('[OpenAiService] $message');
    debugPrint('[OpenAiService] $message');
  }

  /// Prompt Intelligence Layer
  /// Converts a user's simple instruction + chosen style + target video model (Kling vs Seedance)
  /// into a model-optimized, professional video generation prompt.
  Future<String> generateOptimizedVideoPrompt({
    required String userPrompt,
    required String style,
    required String videoModel,
  }) async {
    try {
      debugLog('🧠 Generating prompt for model: $videoModel, style: $style');
      debugLog('📝 Original User Request: "$userPrompt"');

      final effectiveApiKey = apiKey.isNotEmpty ? apiKey : _remoteConfig.getString('openai_api_key');
      
      if (effectiveApiKey.isEmpty) {
        debugLog('⚠️ OpenAI API Key not found. Generating fallback optimized prompt.');
        return _fallbackPromptBuilder(userPrompt, style, videoModel);
      }

      final isSeedance = videoModel.toLowerCase().contains('seedance');
      final isHeyGen = videoModel.toLowerCase().contains('heygen');
      final isKling = videoModel.toLowerCase().contains('kling');

      String systemInstruction = '';

      if (isKling) {
        systemInstruction = '''
You are Twinora's Master AI Video Prompt Intelligence Engine specialized in Kling 3.0 Pro Talking Head and Video Generation.
Your mission is to convert the user's request into an ultra-realistic, cinematic, physically plausible Kling 3.0 Pro video prompt.

MASTER KLING PROMPTING RULES:
1. REALISTIC HUMAN PERFORMANCE:
   - Always focus on realistic talking performance: subtle organic breathing rhythm, natural eye contact with the camera, soft micro-expressions, gentle smiles, and expressive fluid hand gestures while speaking.
2. CRITICAL ACTION TRANSLATION (PREVENT MORPHING):
   - This is an Image-to-Video generation using a portrait reference photo. NEVER instruct the model to perform impossible full-body locomotion (such as "walking into a room", "running outside", or "jumping").
   - If the user requests scene locomotion or an impossible action (e.g. "$userPrompt"), REALISTICALLY TRANSLATE it into confident upper-body presence: the subject speaks with executive poise, turns shoulders and head naturally, gestures with authentic hand movements, and conveys the atmosphere of the user's intent.
3. ABSOLUTE IDENTITY & ATTIRE PRESERVATION:
   - Always anchor the subject as "the person from the reference image", preserving their exact facial geometry, natural skin texture, hair styling, and clothing.
4. CAMERA & CINEMATOGRAPHY:
   - Static locked medium portrait composition (35mm or 50mm cinema lens).
   - Natural shallow depth of field, authentic soft lighting with gentle shadow contrast, zero artificial lens flare.
   - Absolutely NO camera zoom-ins, lens pushes, shaky cam, or abrupt camera panning.
5. TEXTURE & REALISM ANCHORS:
   - Emphasize authentic skin pores, natural subsurface scattering, soft organic motion blur, and zero plastic airbrushing.
6. SILENT PERFORMANCE:
   - Describe pure physical, expressive visual motion only. NEVER include spoken words, dialogue quotes, text overlays, or sound descriptions.
7. LENGTH & FORMAT:
   - Write a single continuous, flowing paragraph between 40 to 65 words. NO line breaks, NO quotes, NO bullet points.

VISUAL STYLE ADAPTATION ($style):
- Cinematic: 35mm lens depth of field, warm key lighting, soft studio contrast, elegant static framing.
- UGC: Authentic smartphone portrait framing, natural soft daylight, organic micro-expressions, casual candid feel.
- Luxury: High-end executive poise, golden hour ambient glow, crisp commercial texture, sophisticated presence.
- Viral Reel: Engaging eye contact, vibrant dynamic posture, energetic talking expressions.
- Netflix Documentary: Raw natural lighting, authentic skin texture, neutral background tone, documentary film realism.

OUTPUT REQUIREMENTS:
- Return ONLY the final prompt text. No preamble, no markdown, no quotes.
''';
      } else if (isHeyGen) {
        systemInstruction = '''
You are Twinora's Master AI Prompt Intelligence Engine specialized in HeyGen v3 Talking Head and Video Generation.
Your task is to take a simple user request and visual style preference, then convert it into a world-class, highly detailed HeyGen video prompt.

HEYGEN V3 PROMPTING FRAMEWORK GUIDELINES:
- CRITICAL IDENTITY PRESERVATION: Maintain exact character facial features, skin texture, hair styling, and outfit from the reference image.
- FACIAL FIDELITY & LIP-SYNC: Emphasize natural micro-facial movements, realistic eye blinks, subtle head tilts, and fluid lip movement.
- SCENE & LIGHTING COHERENCE: Describe harmonious ambient lighting, soft key lights, subtle background blur, and high commercial realism.
- NATURAL MOTION: Keep posture shifts fluid and organic; avoid aggressive camera warping or erratic shifts.

STYLE SPECIFIC GUIDELINES:
- Cinematic: 35mm lens depth of field, warm key lighting, soft studio shadow contrast, elegant static framing.
- UGC: Smartphone portrait framing, natural soft daylight, organic micro-expressions, authentic casual setting.
- Luxury: High-end executive backdrop, golden hour illumination, flawless texture detail, crisp commercial presentation.
- Viral Reel: Vibrant portrait composition, high visual contrast, energetic posture, punchy aesthetic.
- Netflix Documentary: Raw natural lighting, authentic skin texture, neutral background tone, documentary film feel.

OUTPUT REQUIREMENTS:
- Return ONLY the final prompt text. No quotes, no preamble, no markdown headers, no conversational filler.
- Keep prompt between 35 to 60 descriptive words in a SINGLE paragraph with NO line breaks.
''';
      } else if (isSeedance) {
        systemInstruction = '''
You are Twinora's AI Prompt Intelligence Engine specialized in Seedance 2.0 video generation.
Your task is to take a simple user request and a visual style preference, then convert it into a world-class, highly detailed Seedance 2.0 image-to-video prompt.

SEEDANCE 2.0 PROMPTING FRAMEWORK GUIDELINES:
- CRITICAL: This is an Image-to-Video task. Always preserve the exact person, face, outfit, hair, and visual identity from the provided starting image.
- Do NOT invent a new character or change their existing outfit unless explicitly requested.
- Focus on smooth physical subject motion, realistic fluid movement, character action, and natural clothing and hair physics.
- CAMERA DIRECTIVE: Maintain locked, static camera framing or smooth tracking. DO NOT describe camera zoom-ins, lens pushes, or camera forward movements unless the user explicitly requested a zoom in their text.

STYLE SPECIFIC GUIDELINES:
- Cinematic: 35mm lens depth of field, dramatic lighting contrast, static locked composition, cinematic film tone.
- UGC: Authentically shot on modern smartphone, fixed handheld posture, natural micro-expressions, casual ambient lighting.
- Luxury: High-end architectural detail, golden hour ambient glow, static locked framing, glossy metallic and glass reflections.
- Viral Reel: High-energy entrance, punchy visual contrast, static portrait orientation, vibrant aesthetic.
- Netflix Documentary: Raw natural lighting, fixed observational tripod distance, authentic texture, cinematic realism.

OUTPUT REQUIREMENTS:
- Return ONLY the final prompt text. No quotes, no preamble, no markdown headers, no conversational filler.
- Keep prompt between 35 to 60 descriptive words in a SINGLE paragraph with NO line breaks.
''';
      } else {
        systemInstruction = '''
You are Twinora's AI Video Prompt Intelligence Engine.
Convert the simple user request "$userPrompt" and style "$style" into a concise 40-word video prompt describing realistic subject motion, lighting, and camera movement.
Return ONLY a single paragraph prompt text with NO line breaks.
''';
      }

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemInstruction},
          {
            'role': 'user',
            'content': 'User Request: "$userPrompt"\nSelected Style: "$style"\nTarget Video Model: "$videoModel"\n\nGenerate the single-paragraph prompt now:'
          }
        ],
        'temperature': 0.7,
        'max_tokens': 150,
      };

      debugLog('📤 Sending request to OpenAI API...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveApiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String generatedPrompt = data['choices'][0]['message']['content'].toString().trim();
        generatedPrompt = generatedPrompt.replaceAll(RegExp(r'[\r\n]+'), ' ').replaceAll('"', '').trim();
        debugLog('✨ Generated Prompt: "$generatedPrompt"');
        return generatedPrompt;
      } else {
        debugLog('⚠️ OpenAI API call returned status ${response.statusCode}: ${response.body}');
        return _fallbackPromptBuilder(userPrompt, style, videoModel);
      }
    } catch (e) {
      debugLog('❌ Error in OpenAiService: $e');
      return _fallbackPromptBuilder(userPrompt, style, videoModel);
    }
  }

  /// Rule-based fallback prompt builder if OpenAI API key is unconfigured or call fails
  String _fallbackPromptBuilder(String userPrompt, String style, String videoModel) {
    final stylePrefix = switch (style.toLowerCase()) {
      'cinematic' => 'Cinematic 35mm portrait shot. ',
      'ugc' => 'Realistic UGC smartphone portrait video. ',
      'luxury' => 'High-end luxury commercial portrait. ',
      'viral reel' => 'Dynamic viral reel video. ',
      'netflix documentary' => 'Documentary film aesthetic. ',
      _ => 'High quality realistic video. ',
    };

    final isKling = videoModel.toLowerCase().contains('kling');
    final modelSuffix = isKling
        ? 'The subject from reference image performs with natural posture, subtle head turns, expressive hand gestures while talking, natural facial micro-expressions, authentic skin pores, organic breathing, soft studio lighting, shallow depth of field, zero plastic look.'
        : (videoModel.toLowerCase().contains('seedance')
            ? 'Natural body motion, fluid movement in clothing, clear subject focus, soft natural lighting, realistic depth of field.'
            : 'Realistic body movement, subtle hair and clothing motion, crisp subject focus, natural daylight, realistic reflections, shallow depth of field, commercial quality.');

    return '$stylePrefix$userPrompt. $modelSuffix';
  }

  /// Analyze Carousel Template Image using OpenAI Vision (GPT-4o)
  Future<String> analyzeCarouselTemplate({required String templateImageUrl}) async {
    try {
      debugLog('🔍 Analyzing Carousel Template with OpenAI Vision...');
      final effectiveApiKey = apiKey.isNotEmpty ? apiKey : _remoteConfig.getString('openai_api_key');
      if (effectiveApiKey.isEmpty) {
        return 'Warmly lit modern luxury kitchen with beige wooden cabinets and warm golden under-cabinet LED strip lighting. Subject seated on the right side of a glossy marble kitchen counter, body turned 45 degrees facing towards the right in 3/4 profile posture, head tilted back looking towards the upper-right with a crinkled-eye joyful laugh. Her right hand is raised covering her smiling mouth and lips in excitement. She wears a structured cream tailored blazer suit and matching silk headscarf tied under the chin. High-contrast pure white serif text overlays directly on photo (ZERO background text boxes, ZERO grey containers): Headline 1 EXACT VERBATIM "I did" in GIANT COLOSSAL white serif font at top (Y=10%-35%); Subtitle 1 EXACT VERBATIM "something I never thought I would..." at left X=15%, Y=22% below headline; Body paragraph EXACT VERBATIM "and I\'m not sure you\'re ready for the reveal" at left X=15%, Y=60% lower-middle; Subtext CTA EXACT VERBATIM "Any guesses? 👀" at left X=15%, Y=78% bottom-left.';
      }

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final requestBody = {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': '''You are Twinora AI Vision Architect specializing in Dynamic Multi-Text Carousel Template Analysis.
Analyze the provided carousel template image in rich, granular, micro-level detail. Map out every single visual component dynamically with 100% precision:

1. SUBJECT ORIENTATION, FACING DIRECTION & HEAD TILT:
   - Exact position on frame (e.g. right side of frame, left side, or center).
   - Exact facing direction (e.g. body turned 45 degrees facing towards the right in 3/4 profile pose, head tilted back, looking towards the upper right).

2. CLOTHING & OUTFIT DETAILS:
   - Describe exact clothing garments, blazer styling (e.g. structured cream/off-white tailored blazer suit jacket with sleeve buttons), lapel cut, fabric texture, headwear (e.g. matching silk headscarf tied neatly under chin), accessories, and clothing color.

3. POSE, SEATING & EXACT HAND GESTURE:
   - Describe exact posture (e.g. seated leaning back against a glossy marble kitchen counter).
   - Describe exact hand gesture (e.g. right hand raised gently covering her laughing mouth and lips in excitement/giggle, left arm resting behind on counter edge).
   - Facial micro-expressions (crinkled eyes, joyful laughing smile).

4. COLORS, LIGHTING & ROOM ATMOSPHERE:
   - Describe exact room setting, background beige wooden cabinets, integrated wall appliances.
   - Exact lighting (warm golden under-cabinet LED bar lighting, soft warm ambient glow, warm beige color palette, glossy marble reflections).

5. ALL OVERLAY TEXT BLOCKS, TYPOGRAPHY & VERBATIM TEXT EXTRACTION:
   - CRITICAL VERBATIM TEXT RULE: Extract EVERY SINGLE text block word-for-word 100% EXACTLY as it appears on the image. DO NOT invent, generate, rephrase, or change any words!
   - NO-BOX RENDERING RULE: All text overlays MUST be pure high-contrast white serif typography rendered DIRECTLY onto the photo background. NEVER add any background text boxes, translucent grey containers, shaded rectangles, or shapes behind the text!
   - Map out exact typography sizes and positions:
     * Headline Layer: EXACT VERBATIM text (e.g. "I did"), GIANT COLOSSAL extra-large white serif headline spanning the top 35% of the image.
     * Subtitle Layer: EXACT VERBATIM text (e.g. "something I never thought I would..."), Left-aligned (X=15%), positioned under headline in elegant italic white serif font.
     * Body Paragraph Layer: EXACT VERBATIM text (e.g. "and I'm not sure you're ready for the reveal"), Left-aligned (X=15%), lower-middle area (Y=60%) in multi-line white serif font directly on photo with zero background box.
     * Subtext/CTA Layer: EXACT VERBATIM text (e.g. "Any guesses? 👀"), Left-aligned (X=15%), bottom-left area (Y=78%) in italic white serif font with emoji.

Provide an exhaustive, micro-detailed (150-220 words) dynamic breakdown mapping out facing direction, hand gesture, clothing, pose, lighting, giant headline, left-aligned text, zero background text boxes, and EXACT VERBATIM TEXT BLOCKS!''',
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Exhaustively analyze this carousel template image layout, subject facing direction, clothing, outfit, seating posture, hand covering mouth gesture, warm lighting, giant headline size, left-aligned subtext, ZERO background text boxes, and EXACT VERBATIM TEXT BLOCKS:'},
              {
                'type': 'image_url',
                'image_url': {'url': templateImageUrl}
              }
            ]
          }
        ],
        'max_tokens': 450,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveApiKey',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysis = data['choices'][0]['message']['content'].toString().trim();
        debugLog('✨ Vision Analysis Complete: "$analysis"');
        return analysis;
      }
      return 'Warmly lit modern luxury kitchen with beige wooden cabinets and warm golden under-cabinet LED strip lighting. Subject seated on the right side of a glossy marble kitchen counter, body turned 45 degrees facing towards the right in 3/4 profile posture, head tilted back looking towards the upper-right with a crinkled-eye joyful laugh. Her right hand is raised covering her smiling mouth and lips in excitement. She wears a structured cream tailored blazer suit and matching silk headscarf tied under the chin. High-contrast pure white serif text overlays directly on photo (ZERO background text boxes, ZERO grey containers): Headline 1 EXACT VERBATIM "I did" in GIANT COLOSSAL white serif font at top (Y=10%-35%); Subtitle 1 EXACT VERBATIM "something I never thought I would..." at left X=15%, Y=22% below headline; Body paragraph EXACT VERBATIM "and I\'m not sure you\'re ready for the reveal" at left X=15%, Y=60% lower-middle; Subtext CTA EXACT VERBATIM "Any guesses? 👀" at left X=15%, Y=78% bottom-left.';
    } catch (e) {
      debugLog('❌ Error analyzing carousel template: $e');
      return 'Warmly lit modern luxury kitchen with beige wooden cabinets and warm golden under-cabinet LED strip lighting. Subject seated on the right side of a glossy marble kitchen counter, body turned 45 degrees facing towards the right in 3/4 profile posture, head tilted back looking towards the upper-right with a crinkled-eye joyful laugh. Her right hand is raised covering her smiling mouth and lips in excitement. She wears a structured cream tailored blazer suit and matching silk headscarf tied under the chin. High-contrast pure white serif text overlays directly on photo (ZERO background text boxes, ZERO grey containers): Headline 1 EXACT VERBATIM "I did" in GIANT COLOSSAL white serif font at top (Y=10%-35%); Subtitle 1 EXACT VERBATIM "something I never thought I would..." at left X=15%, Y=22% below headline; Body paragraph EXACT VERBATIM "and I\'m not sure you\'re ready for the reveal" at left X=15%, Y=60% lower-middle; Subtext CTA EXACT VERBATIM "Any guesses? 👀" at left X=15%, Y=78% bottom-left.';
    }
  }

  /// Synthesize OpenAI Vision Template Analysis + User Topic Prompt into an Optimized Carousel Image Generation Prompt
  Future<String> generateCarouselSynthesisPrompt({
    required String templateAnalysis,
    required String userPrompt,
    required String templateTitle,
  }) async {
    try {
      debugLog('🧠 Synthesizing Carousel Prompt for topic: "$userPrompt" with template: "$templateTitle"');
      final effectiveApiKey = apiKey.isNotEmpty ? apiKey : _remoteConfig.getString('openai_api_key');
      if (effectiveApiKey.isEmpty) {
        return 'Warmly lit modern luxury kitchen with beige wooden cabinets and warm under-cabinet LED lighting. Subject seated on marble counter on right side facing right in 3/4 profile, head tilted back looking upper-right, right hand raised covering smiling mouth. Replace face with user face from reference image @image1. High-contrast white serif text overlays directly on photo with ZERO background boxes: Top GIANT COLOSSAL headline "I did", left-aligned subtitle "something I never thought I would...", left-aligned lower body paragraph "and I\'m not sure you\'re ready for the reveal", left-aligned CTA "Any guesses? 👀". $templateAnalysis';
      }

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final systemInstruction = '''
You are Twinora's Master Carousel Prompt Architect.
Synthesize a fully dynamic, ultra-detailed Carousel Template Generation Prompt combining vision analysis: "$templateAnalysis" and style: "$templateTitle" with user request: "$userPrompt".

DYNAMIC CAROUSEL PROMPTING FRAMEWORK (APPLIES TO ANY TEMPLATE):
1. DYNAMIC OUTFIT & CLOTHING SPECIFICATION: Describe the exact outfit garments, headwear, fabric texture, and clothing color tones directly from "$templateAnalysis".
2. DYNAMIC POSE, FACING DIRECTION & EXACT HAND GESTURE: Detail the exact seating/standing pose, posture tilt, facing direction (e.g. seated on right side facing right in 3/4 profile, head tilted back looking upper-right), and exact hand placement (right hand raised covering laughing mouth over lips) directly from "$templateAnalysis".
3. DYNAMIC ENVIRONMENT & LIGHTING: Describe the exact room setting, background cabinets/scenery, lighting sources, ambient color palette, and reflections directly from "$templateAnalysis".
4. PRECISE FACE IDENTITY REPLACEMENT: Specify that ONLY the face of the subject in the template is replaced with the user's face, skin tone, facial features, and identity from reference face image @image1, preserving the exact body pose, hand gesture covering mouth, facing direction, clothing, and environment.
5. STRICT VERBATIM TEXT OVERLAY PRESERVATION & ZERO-BOX MANDATE:
   - CRITICAL VERBATIM TEXT RULE: You MUST PRESERVE THE EXACT VERBATIM TEXT OVERLAY WORDS extracted from "$templateAnalysis" or passed in "$userPrompt" 100% UNCHANGED!
   - NEVER invent, generate, alter, rephrase, or introduce new text overlay titles (such as "MARBLE CHRONICLES", "CULINARY JOURNEY", "RECIPES", etc.). Use ONLY the exact headline, subtitle, body text, and CTA words extracted from "$templateAnalysis" or "$userPrompt".
   - NO BACKGROUND TEXT BOXES: All text overlays MUST be pure high-contrast white serif typography overlaid directly on the photo background with ZERO background text boxes, ZERO translucent grey containers, and ZERO shaded shapes behind any text block!
   - Headline 1: GIANT COLOSSAL extra-large white serif headline.
   - Subtitle 1: Left-aligned (X=15%), directly below headline in italic white serif font.
   - Body Paragraph: Left-aligned (X=15%), lower-middle left area (Y=60%) in multi-line white serif font directly on the photo without any background box.
   - Subtext CTA: Left-aligned (X=15%), bottom-left (Y=78%) in italic white serif font with emoji.

OUTPUT REQUIREMENTS:
- Return ONLY the final ultra-specific prompt text (130-170 words) as a single continuous paragraph with NO line breaks, quotes, or markdown formatting. Fully describe clothing, pose, hand gesture covering mouth, facing direction facing right, lighting, room atmosphere, face replacement, EXACT VERBATIM text overlays, and ZERO background text boxes.
''';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemInstruction},
            {'role': 'user', 'content': 'Topic: "$userPrompt"\nTemplate: "$templateTitle"\nAnalysis: "$templateAnalysis"'}
          ],
          'max_tokens': 450,
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prompt = data['choices'][0]['message']['content'].toString().replaceAll(RegExp(r'[\r\n]+'), ' ').replaceAll('"', '').trim();
        debugLog('✨ Synthesized Carousel Prompt: "$prompt"');
        return prompt;
      }
      return 'Warmly lit modern luxury kitchen with beige wooden cabinets and warm under-cabinet LED lighting. Subject seated on marble counter on right side facing right in 3/4 profile, head tilted back looking upper-right, right hand raised covering smiling mouth. Replace face with user face from reference image @image1. High-contrast white serif text overlays directly on photo with ZERO background boxes: Top GIANT COLOSSAL headline "I did", left-aligned subtitle "something I never thought I would...", left-aligned lower body paragraph "and I\'m not sure you\'re ready for the reveal", left-aligned CTA "Any guesses? 👀". $templateAnalysis';
    } catch (e) {
      debugLog('❌ Error generating carousel synthesis prompt: $e');
      return 'Warmly lit modern luxury kitchen with beige wooden cabinets and warm under-cabinet LED lighting. Subject seated on marble counter on right side facing right in 3/4 profile, head tilted back looking upper-right, right hand raised covering smiling mouth. Replace face with user face from reference image @image1. High-contrast white serif text overlays directly on photo with ZERO background boxes: Top GIANT COLOSSAL headline "I did", left-aligned subtitle "something I never thought I would...", left-aligned lower body paragraph "and I\'m not sure you\'re ready for the reveal", left-aligned CTA "Any guesses? 👀". $templateAnalysis';
    }
  }

  /// Generate Carousel Image using OpenAI Image API (with automatic Gemini dual-reference fallback if key lacks DALL-E permissions)
  Future<String> generateCarouselImage({
    required String prompt,
    File? userImageFile,
    String? templateImageUrl,
  }) async {
    try {
      debugLog('🎨 Generating Carousel image with OpenAI Image API...');
      debugLog('📝 Prompt: "$prompt"');

      final effectiveApiKey = apiKey.isNotEmpty ? apiKey : _remoteConfig.getString('openai_api_key');
      if (effectiveApiKey.isNotEmpty) {
        final url = Uri.parse('https://api.openai.com/v1/images/generations');

        // Attempt 1: DALL-E 3
        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $effectiveApiKey',
            },
            body: jsonEncode({
              'model': 'dall-e-3',
              'prompt': prompt,
              'n': 1,
              'size': '1024x1024',
              'quality': 'standard',
            }),
          ).timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['data'] != null && (data['data'] as List).isNotEmpty) {
              final imageUrl = data['data'][0]['url'];
              debugLog('✅ OpenAI DALL-E 3 image generated: $imageUrl');
              return imageUrl.toString();
            }
          }
          debugLog('⚠️ DALL-E 3 response status ${response.statusCode}: ${response.body}. Falling back to DALL-E 2...');
        } catch (dalle3Error) {
          debugLog('⚠️ DALL-E 3 attempt failed: $dalle3Error. Falling back to DALL-E 2...');
        }

        // Attempt 2: DALL-E 2 Fallback (max 1000 char prompt)
        try {
          debugLog('🎨 Attempting DALL-E 2 fallback...');
          final dalle2Prompt = prompt.length > 1000 ? prompt.substring(0, 1000) : prompt;
          final responseDalle2 = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $effectiveApiKey',
            },
            body: jsonEncode({
              'model': 'dall-e-2',
              'prompt': dalle2Prompt,
              'n': 1,
              'size': '1024x1024',
            }),
          ).timeout(const Duration(seconds: 120));

          if (responseDalle2.statusCode == 200) {
            final data = jsonDecode(responseDalle2.body);
            if (data['data'] != null && (data['data'] as List).isNotEmpty) {
              final imageUrl = data['data'][0]['url'];
              debugLog('✅ OpenAI DALL-E 2 image generated: $imageUrl');
              return imageUrl.toString();
            }
          }
          debugLog('⚠️ DALL-E 2 response status ${responseDalle2.statusCode}: ${responseDalle2.body}');
        } catch (dalle2Error) {
          debugLog('⚠️ DALL-E 2 attempt failed: $dalle2Error');
        }
      }

      // Attempt 3: High-Fidelity Dual Reference Fallback via Gemini Service using ChatGPT Prompt
      debugLog('🎨 OpenAI DALL-E models unavailable on this API key. Falling back to Gemini dual-reference generator with ChatGPT prompt...');
      if (userImageFile != null && templateImageUrl != null && templateImageUrl.isNotEmpty) {
        final geminiService = GeminiService();
        final results = await geminiService.generateImageWithTemplateAndReference(
          templateImageUrl: templateImageUrl,
          userImageFile: userImageFile,
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
          ratio: '9:16',
          batch: 1,
          customDescription: prompt,
        );
        if (results.isNotEmpty && results.first != 'error') {
          return results.first;
        }
      } else if (userImageFile != null) {
        final geminiService = GeminiService();
        final results = await geminiService.generateImagesWithReference(
          referenceImage: userImageFile,
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
          customPrompt: prompt,
        );
        if (results.isNotEmpty && results.first != 'error') {
          return results.first;
        }
      }

      throw Exception('Image generation failed on all available AI models.');
    } catch (e) {
      debugLog('❌ Error in generateCarouselImage: $e');
      rethrow;
    }
  }
}
