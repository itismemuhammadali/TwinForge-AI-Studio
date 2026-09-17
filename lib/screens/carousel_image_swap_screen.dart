import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../models/carousel_template.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'carousel_editor_screen.dart';

class CarouselImageSwapScreen extends StatefulWidget {
  final List<File> userImages;
  final CarouselTemplate template;

  const CarouselImageSwapScreen({
    super.key,
    required this.userImages,
    required this.template,
  });

  @override
  State<CarouselImageSwapScreen> createState() =>
      _CarouselImageSwapScreenState();
}

class _CarouselImageSwapScreenState extends State<CarouselImageSwapScreen> {
  late Map<int, File> _slotMappings;
  int? _selectedSlotIndex;

  @override
  void initState() {
    super.initState();
    _slotMappings = {};
    // Auto-assign first images to first slots
    for (int i = 0; i < widget.userImages.length && i < widget.template.slots.length; i++) {
      _slotMappings[i] = widget.userImages[i];
    }
    debugLog('📸 Initialized slot mappings: ${_slotMappings.length} images assigned');
  }

  static void debugLog(String message) {
    developer.log('[CarouselImageSwapScreen] $message');
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _selectSlot(int slotIndex) {
    setState(() {
      _selectedSlotIndex = _selectedSlotIndex == slotIndex ? null : slotIndex;
    });
    debugLog('📍 Selected slot: $slotIndex');
  }

  void _assignImageToSlot(int slotIndex, File imageFile) {
    setState(() {
      _slotMappings[slotIndex] = imageFile;
      _selectedSlotIndex = null;
    });
    debugLog('✅ Assigned image to slot $slotIndex');
  }

  void _removeImageFromSlot(int slotIndex) {
    setState(() {
      _slotMappings.remove(slotIndex);
      _selectedSlotIndex = null;
    });
    debugLog('❌ Removed image from slot $slotIndex');
  }

  Future<void> _proceedToOverlays() async {
    // Check if all slots are filled
    if (_slotMappings.length < widget.template.slots.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all ${widget.template.slots.length} image slots',
            style: AppFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    debugLog('✅ All slots filled. Proceeding to overlay editor...');
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarouselEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;
    final slots = widget.template.slots;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'CAROUSEL EDITOR',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Swap Images into Template',
                    style: AppFonts.playfair(
                      size: 32,
                      weight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.template.name,
                    style: AppFonts.poppins(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Template Preview with Slots
                  Text(
                    'TEMPLATE PREVIEW',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTemplatePreview(slots),
                  const SizedBox(height: 32),

                  // Image Selection
                  Text(
                    'AVAILABLE IMAGES (${widget.userImages.length})',
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImageSelection(),
                  const SizedBox(height: 32),

                  // Slot Status
                  _buildSlotStatus(slots),
                  const SizedBox(height: 40),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.surface,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'BACK',
                                style: AppFonts.poppins(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GoldButton(
                          label: 'NEXT: ADD OVERLAYS',
                          onTap: _proceedToOverlays,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreview(List<ImageSlot> slots) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          // Template background
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.template.templateImageUrl,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.2),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.inputBg,
                );
              },
            ),
          ),

          ...slots.map((slot) {
            final hasUserImage = _slotMappings.containsKey(slot.index);
            final isSelected = _selectedSlotIndex == slot.index;

            return Positioned(
              left: slot.x * 280,
              top: slot.y * 280,
              width: slot.width * 280,
              height: slot.height * 280,
              child: GestureDetector(
                onTap: () => _selectSlot(slot.index),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : hasUserImage
                              ? AppColors.gold.withValues(alpha: 0.5)
                              : AppColors.gold.withValues(alpha: 0.2),
                      width: isSelected ? 3 : 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppColors.gold.withValues(alpha: 0.1)
                        : AppColors.white.withValues(alpha: 0.05),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Show user image if swapped, otherwise show template image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: hasUserImage
                            ? Image.file(
                                _slotMappings[slot.index]!,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                slot.userImagePath ?? widget.template.templateImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.inputBg,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.gold.withValues(alpha: 0.3),
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Remove button overlay
                      if (isSelected && hasUserImage)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImageFromSlot(slot.index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.black.withValues(alpha: 0.7),
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      // Slot label
                      if (!hasUserImage)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Template',
                              style: AppFonts.poppins(
                                size: 8,
                                color: AppColors.gold,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageSelection() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.userImages.length,
        itemBuilder: (context, index) {
          final imageFile = widget.userImages[index];
          final isAssigned =
              _slotMappings.values.toList().contains(imageFile);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onLongPress: _selectedSlotIndex != null
                  ? () => _assignImageToSlot(_selectedSlotIndex!, imageFile)
                  : null,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAssigned
                        ? AppColors.gold.withValues(alpha: 0.6)
                        : AppColors.gold.withValues(alpha: 0.2),
                    width: isAssigned ? 2 : 1,
                  ),
                  boxShadow: isAssigned
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isAssigned)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Img ${index + 1}',
                          style: AppFonts.poppins(
                            size: 8,
                            color: AppColors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedSlotIndex != null)
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _assignImageToSlot(_selectedSlotIndex!, imageFile),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.gold
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'TAP',
                                  style: AppFonts.poppins(
                                    size: 10,
                                    color: AppColors.black,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotStatus(List<ImageSlot> slots) {
    final filledSlots = _slotMappings.length;
    final totalSlots = slots.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slot Status',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              Text(
                '$filledSlots/$totalSlots',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w700,
                  color: filledSlots == totalSlots
                      ? Colors.green
                      : AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: filledSlots / totalSlots,
              minHeight: 8,
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                filledSlots == totalSlots ? Colors.green : AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusMessage(filledSlots, totalSlots),
            style: AppFonts.poppins(
              size: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(int filled, int total) {
    if (filled == total) {
      return '✅ All slots filled! Ready to add overlays.';
    } else {
      final remaining = total - filled;
      return '👉 Click a slot and then tap an image to assign. $remaining more to go!';
    }
  }
}
