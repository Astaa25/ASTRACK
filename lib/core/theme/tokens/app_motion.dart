import 'package:flutter/material.dart';

/// Centralized Motion & Animation Tokens for ASTRACK
/// Based on Emil Kowalski's Design Engineering & Taste Principles
class AppMotion {
  AppMotion._();

  // Durations (Restrained, responsive, physical)
  static const Duration tap = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration sheet = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 320);

  // Curves
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve moveCurve = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.easeOutBack;

  // Press Scale factor (Micro-scale physical feedback)
  static const double activeScale = 0.97;
  static const double subheaderEnterScale = 0.96;

  /// Helper to resolve duration with respect to Reduce Motion accessibility setting.
  /// If user enabled reduce-motion on device, animations become immediate.
  static Duration getDuration(BuildContext context, Duration standardDuration) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduceMotion ? Duration.zero : standardDuration;
  }

  /// Whether reduce motion is requested by system
  static bool isReduceMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }
}
