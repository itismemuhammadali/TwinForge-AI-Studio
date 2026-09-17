import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

// ── Reusable Image Source Selection Bottom Sheet ─────────────────────────────
class ImageSourceBottomSheet extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;
  final String title;
  final String subtitle;

  const ImageSourceBottomSheet({
    super.key,
    required this.onSourceSelected,
    this.title = 'SELECT IMAGE SOURCE',
    this.subtitle = 'Choose how to upload your photo',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppFonts.poppins(
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppFonts.poppins(
              size: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 28),
          
          // Camera option
          _SourceOptionCard(
            title: 'Take a Photo',
            subtitle: 'Open camera and take a selfie',
            icon: Icons.camera_alt,
            isPrimary: true,
            onTap: () {
              onSourceSelected(ImageSource.camera);
              Navigator.pop(context);
            },
          ),
          
          const SizedBox(height: 12),
          
          // Gallery option
          _SourceOptionCard(
            title: 'Choose from Gallery',
            subtitle: 'Pick an existing photo',
            icon: Icons.photo_library,
            isPrimary: false,
            onTap: () {
              onSourceSelected(ImageSource.gallery);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _SourceOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _SourceOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isPrimary 
              ? AppColors.gold.withValues(alpha: 0.08)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary 
                ? AppColors.gold.withValues(alpha: 0.3)
                : AppColors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary 
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isPrimary ? AppColors.gold : AppColors.white.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.poppins(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.poppins(
                    size: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: isPrimary 
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable brand header bar ─────────────────────────────────────────────
class AimrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const AimrAppBar({super.key, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'TWIN',
              style: AppFonts.playfair(
                  size: 18, weight: FontWeight.w900, color: AppColors.white),
            ),
            TextSpan(
              text: 'ORA',
              style: AppFonts.playfair(
                  size: 18, weight: FontWeight.w900, color: AppColors.gold),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.white.withValues(alpha: 0.05)),
      ),
      actions: actions ?? [],
    );
  }
}

// ── Phase label + section heading ────────────────────────────────────────────
class PhaseHeader extends StatelessWidget {
  final String phase;
  final String title;

  const PhaseHeader({super.key, required this.phase, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(phase,
            style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 6)),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: AppFonts.playfair(
                size: 48,
                weight: FontWeight.w900,
                color: AppColors.white,
                letterSpacing: -1)),
        const SizedBox(height: 16),
        Container(width: 60, height: 1.5,
            color: AppColors.gold.withValues(alpha: 0.4)),
      ],
    );
  }
}

// ── Gold primary button ───────────────────────────────────────────────────────
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  final double height;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outlined = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppColors.gold,
          borderRadius: BorderRadius.circular(24),
          border: outlined
              ? Border.all(color: AppColors.gold, width: 0.8)
              : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: outlined ? AppColors.gold : AppColors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w900,
                  color: outlined ? AppColors.gold : AppColors.black,
                  letterSpacing: 4,
                ),
              ),
      ),
    );
  }
}

// ── Dark card container ───────────────────────────────────────────────────────
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final VoidCallback? onTap;

  const DarkCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.poppins(
          size: 10,
          weight: FontWeight.w700,
          color: AppColors.gold,
          letterSpacing: 3),
    );
  }
}

// ── Styled text field ─────────────────────────────────────────────────────────
class AimrField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final String? hint;
  final int maxLines;

  const AimrField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.maxLines = 1,
  });

  @override
  State<AimrField> createState() => _AimrFieldState();
}

class _AimrFieldState extends State<AimrField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 3)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscure && _obscured,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          style: AppFonts.poppins(size: 14, color: AppColors.text),
          cursorColor: AppColors.gold,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppFonts.poppins(
                size: 13, color: AppColors.muted.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.white.withValues(alpha: 0.06), width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
            ),
            suffixIcon: widget.obscure
                ? GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                        _obscured ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.muted,
                        size: 18),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// ── Dropdown selector (matches OptionSelector from web) ──────────────────────
class AimrDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const AimrDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon = Icons.tune,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 14),
            const SizedBox(width: 8),
            Text(label,
                style: AppFonts.poppins(
                    size: 10,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : (options.isNotEmpty ? options.first : null),
              isExpanded: true,
              dropdownColor: const Color(0xFF111111),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              icon: Icon(Icons.keyboard_arrow_down,
                  color: AppColors.gold.withValues(alpha: 0.6), size: 20),
              style: AppFonts.poppins(size: 13, color: AppColors.text),
              items: options
                  .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.poppins(
                              size: 13, color: AppColors.text))))
                  .toList(),
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog allowing users to report objectionable UGC or AI-generated media (Apple Guideline 1.2)
Future<void> showReportContentDialog(
  BuildContext context, {
  required String contentId,
  required String contentType,
  String? previewUrl,
}) async {
  final reasons = [
    'Inappropriate or sexually explicit',
    'Violence, hate speech, or harassment',
    'Intellectual property infringement',
    'Spam, misleading, or fraudulent',
    'Other objectionable content',
  ];
  String selectedReason = reasons.first;
  final TextEditingController detailsCtrl = TextEditingController();
  bool isSubmitting = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141410),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.orangeAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Report Content',
                style: AppFonts.poppins(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twinora has zero tolerance for objectionable material. Please choose a reason:',
                  style: AppFonts.poppins(size: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E1E18),
                      style: AppFonts.poppins(size: 12, color: AppColors.text),
                      items: reasons
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r, style: AppFonts.poppins(size: 12, color: AppColors.text)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedReason = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: detailsCtrl,
                  maxLines: 3,
                  style: AppFonts.poppins(size: 12, color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)...',
                    hintStyle: AppFonts.poppins(size: 12, color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'CANCEL',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        await FirebaseFirestore.instance.collection('reports').add({
                          'contentId': contentId,
                          'contentType': contentType,
                          'previewUrl': previewUrl,
                          'reporterUid': user?.uid ?? 'anonymous',
                          'reporterEmail': user?.email ?? 'anonymous',
                          'reason': selectedReason,
                          'details': detailsCtrl.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'status': 'pending',
                        });

                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Report submitted. Our moderation team reviews flagged items within 24 hours.',
                                style: AppFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit report: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'SUBMIT REPORT',
                      style: AppFonts.poppins(
                        size: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}
