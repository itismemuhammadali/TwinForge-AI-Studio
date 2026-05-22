import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Reusable brand header bar ─────────────────────────────────────────────
class AimrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;

  const AimrAppBar({super.key, this.onProfileTap, this.actions});

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
      actions: actions ??
          [
            if (onProfileTap != null)
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
                    color: AppColors.gold.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.gold, size: 18),
                ),
              ),
          ],
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
              value: value,
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
