import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors — exact values from tailwind.config in index.html ────────────────
class AppColors {
  static const background = Color(0xFF121212); // brand-charcoal
  static const surface    = Color(0xFF1A1A1A); // brand-surface
  static const gold       = Color(0xFFB1946C); // brand-gold
  static const text       = Color(0xFFE8E8E8); // brand-text
  static const muted      = Color(0xFF8A8A8A); // brand-muted
  static const white      = Color(0xFFFFFFFF);
  static const black      = Color(0xFF000000);
  static const inputBg    = Color(0xFF0C0C0C);
}

// ─── Typography ──────────────────────────────────────────────────────────────
// Playfair Display → font-serif  (headings, brand title, auth card title)
// Poppins          → font-sans   (labels, buttons, body, captions)

class AppFonts {
  // Playfair Display — serif headings
  static TextStyle playfair({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.text,
    FontStyle style = FontStyle.normal,
    double letterSpacing = 0,
    double height = 1.2,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontStyle: style,
        letterSpacing: letterSpacing,
        height: height,
      );

  // Poppins — sans labels / body
  static TextStyle poppins({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double letterSpacing = 0,
    double height = 1.4,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}
