import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../constants/studio_options.dart';
import '../models/generated_content.dart';
import 'image_edit_screen.dart';

class GenerateScreen extends StatefulWidget {
  final String? presetStyle;
  const GenerateScreen({super.key, this.presetStyle});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late String _mood;
  late String _location;
  late String _outfit;
  String _hairstyle = StudioOptions.hairstyles[0];
  String _makeup    = StudioOptions.makeupLooks[0];
  String _skin      = StudioOptions.skinStyles[0];
  String _height    = StudioOptions.heightOptions[0];
  String _bust      = StudioOptions.bustSizes[0];
  String _waist     = StudioOptions.waistSizes[0];
  String _hips      = StudioOptions.hipsSizes[0];
  String _angle     = StudioOptions.cameraAngles[0];
  String _ratio     = StudioOptions.aspectRatios[0];
  int    _batch     = 4;
  bool   _hasImage  = false;
  bool   _generating = false;
  final  _enhCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mood     = StudioOptions.moods[0];
    _location = StudioOptions.locations[0];
    _outfit   = StudioOptions.outfitStyles[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AimrAppBar(actions: []),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const SizedBox(height: 32),
          if (widget.presetStyle != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Using Template: ${widget.presetStyle}',
                    style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.gold))),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.gold.withValues(alpha: 0.6), size: 18),
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const GenerateScreen())),
                ),
              ]),
            ),
            const SizedBox(height: 24),
          ],
          _buildPhase01(),
          const SizedBox(height: 56),
          _buildPhase02(),
          const SizedBox(height: 56),
          _buildPhase03(),
          const SizedBox(height: 56),
          _buildPhase04(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildPhase01() => Column(children: [
    const PhaseHeader(phase: 'PHASE 01', title: 'Upload Source'),
    const SizedBox(height: 32),
    GestureDetector(
      onTap: () => setState(() => _hasImage = !_hasImage),
      child: Container(
        width: double.infinity, height: 300,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _hasImage ? AppColors.gold.withValues(alpha: 0.4) : AppColors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: _hasImage
            ? Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Container(color: AppColors.surface,
                      child: const Icon(Icons.person, color: AppColors.muted, size: 80)),
                ),
                Positioned(bottom: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Text('Replace Image',
                        style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.white)),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.06),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.gold, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Drop Source', style: AppFonts.playfair(size: 22, style: FontStyle.italic, color: AppColors.white)),
                const SizedBox(height: 6),
                Text('EDITORIAL REFERENCE',
                    style: AppFonts.poppins(size: 9, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
              ]),
      ),
    ),
  ]);

  Widget _buildPhase02() => Column(children: [
    const PhaseHeader(phase: 'PHASE 02', title: 'Customize Your Scene'),
    const SizedBox(height: 32),
    AimrDropdown(label: 'The Vibe', value: _mood, options: StudioOptions.moods,
        icon: Icons.wb_sunny_outlined, onChanged: (v) => setState(() => _mood = v)),
    const SizedBox(height: 20),
    AimrDropdown(label: 'The Scene', value: _location, options: StudioOptions.locations,
        icon: Icons.location_on_outlined, onChanged: (v) => setState(() => _location = v)),
    const SizedBox(height: 20),
    AimrDropdown(label: 'The Outfit', value: _outfit, options: StudioOptions.outfitStyles,
        icon: Icons.checkroom_outlined, onChanged: (v) => setState(() => _outfit = v)),
  ]);

  Widget _buildPhase03() => Column(children: [
    const PhaseHeader(phase: 'PHASE 03', title: 'Refine Your Twin'),
    const SizedBox(height: 32),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Hair Style', value: _hairstyle,
          options: StudioOptions.hairstyles, icon: Icons.face_retouching_natural,
          onChanged: (v) => setState(() => _hairstyle = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Makeup', value: _makeup,
          options: StudioOptions.makeupLooks, icon: Icons.brush_outlined,
          onChanged: (v) => setState(() => _makeup = v))),
    ]),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Skin Style', value: _skin,
          options: StudioOptions.skinStyles, icon: Icons.spa_outlined,
          onChanged: (v) => setState(() => _skin = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Height', value: _height,
          options: StudioOptions.heightOptions, icon: Icons.height,
          onChanged: (v) => setState(() => _height = v))),
    ]),
    const SizedBox(height: 20),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Bust', value: _bust,
          options: StudioOptions.bustSizes, icon: Icons.straighten,
          onChanged: (v) => setState(() => _bust = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Waist', value: _waist,
          options: StudioOptions.waistSizes, icon: Icons.straighten,
          onChanged: (v) => setState(() => _waist = v))),
    ]),
    const SizedBox(height: 20),
    AimrDropdown(label: 'Hips Sculpt', value: _hips,
        options: StudioOptions.hipsSizes, icon: Icons.straighten,
        onChanged: (v) => setState(() => _hips = v)),
  ]);

  Widget _buildPhase04() => Column(children: [
    const PhaseHeader(phase: 'PHASE 04', title: 'Final Touches'),
    const SizedBox(height: 32),
    Row(children: [
      Expanded(child: AimrDropdown(label: 'Camera Angle', value: _angle,
          options: StudioOptions.cameraAngles, icon: Icons.camera_alt_outlined,
          onChanged: (v) => setState(() => _angle = v))),
      const SizedBox(width: 16),
      Expanded(child: AimrDropdown(label: 'Aspect Ratio', value: _ratio,
          options: StudioOptions.aspectRatios, icon: Icons.crop_outlined,
          onChanged: (v) => setState(() => _ratio = v))),
    ]),
    const SizedBox(height: 24),
    // Batch size slider
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('BATCH SIZE',
            style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
        Text('$_batch Images',
            style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold)),
      ]),
      const SizedBox(height: 12),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.gold,
          inactiveTrackColor: AppColors.white.withValues(alpha: 0.1),
          thumbColor: AppColors.gold,
          overlayColor: AppColors.gold.withValues(alpha: 0.1),
          trackHeight: 2,
        ),
        child: Slider(
          value: _batch.toDouble(),
          min: 1, max: 4, divisions: 3,
          onChanged: (v) => setState(() => _batch = v.round()),
        ),
      ),
    ]),
    const SizedBox(height: 24),
    // Custom enhancer
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('OPTIONAL: MAKE IT CUSTOM',
          style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
      const SizedBox(height: 12),
      TextField(
        controller: _enhCtrl,
        maxLines: 4,
        style: AppFonts.poppins(size: 14, color: AppColors.text, height: 1.6),
        cursorColor: AppColors.gold,
        decoration: InputDecoration(
          hintText: '"Golden hour glow", "holding a vintage camera"...',
          hintStyle: AppFonts.poppins(size: 13, color: AppColors.muted.withValues(alpha: 0.3), height: 1.6),
          filled: true,
          fillColor: AppColors.inputBg,
          contentPadding: const EdgeInsets.all(20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.08), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 1),
          ),
        ),
      ),
    ]),
    const SizedBox(height: 40),
    // Credits info
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('STUDIO CREDIT USAGE: ',
          style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.white.withValues(alpha: 0.4), letterSpacing: 2)),
      Text('0 / 16 CREDITS',
          style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)),
    ]),
    const SizedBox(height: 20),
    GoldButton(
      label: _generating ? 'MANIFESTING...' : 'RENDER TWIN',
      loading: _generating,
      onTap: () async {
        if (!_hasImage) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('Please upload a source photo first.',
                style: AppFonts.poppins(size: 12, color: AppColors.text)),
          ));
          return;
        }
        
        setState(() => _generating = true);
        
        try {
          // Simulate generation
          await Future.delayed(const Duration(seconds: 2));
          
          // Create generated content
          final generatedContent = GeneratedContent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            originalImageUrl: 'https://via.placeholder.com/512x512?text=Generated+Image',
            prompt: _enhCtrl.text.isNotEmpty ? _enhCtrl.text : '$_mood, $_location, $_outfit',
            createdAt: DateTime.now(),
            contentType: 'original',
            metadata: {
              'mood': _mood,
              'location': _location,
              'outfit': _outfit,
              'hairstyle': _hairstyle,
              'makeup': _makeup,
              'skin': _skin,
              'height': _height,
              'bust': _bust,
              'waist': _waist,
              'hips': _hips,
              'angle': _angle,
              'ratio': _ratio,
              'batch': _batch,
            },
          );
          
          if (mounted) {
            setState(() => _generating = false);
            
            // Navigate to edit screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageEditScreen(content: generatedContent),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _generating = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppColors.surface,
              content: Text('Generation failed: $e',
                  style: AppFonts.poppins(size: 12, color: AppColors.text)),
            ));
          }
        }
      },
    ),
  ]);
}
