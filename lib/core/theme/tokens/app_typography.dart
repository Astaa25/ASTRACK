import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Typography System for ASTRACK
/// Powered by Plus Jakarta Sans with Tabular Figures for Financial Accuracy
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';

  /// Standard font features for financial numbers (monospace digit widths)
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // Headings & Displays
  static TextStyle displayLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.25,
        color: color,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: color,
      );

  // Financial Hero Numbers (with Tabular Figures)
  static TextStyle financialHero({Color? color, double fontSize = 34}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        fontFeatures: tabularFigures,
        height: 1.15,
        color: color,
      );

  static TextStyle financialLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        fontFeatures: tabularFigures,
        height: 1.2,
        color: color,
      );

  static TextStyle financialMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        fontFeatures: tabularFigures,
        height: 1.25,
        color: color,
      );

  static TextStyle financialSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFeatures: tabularFigures,
        height: 1.3,
        color: color,
      );

  // Titles
  static TextStyle titleLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: color,
      );

  // Body
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.45,
        color: color,
      );

  // Labels & Badges
  static TextStyle labelLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.25,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        height: 1.25,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        height: 1.2,
        color: color,
      );
}
