import 'package:flutter/material.dart';

/// Centralized Border Radius Tokens for ASTRACK Design System
class AppRadius {
  AppRadius._();

  static const double xsVal = 4.0;
  static const double smVal = 8.0;
  static const double mdVal = 12.0;
  static const double lgVal = 16.0;
  static const double xlVal = 20.0;
  static const double xxlVal = 24.0;
  static const double xxxlVal = 32.0;
  static const double fullVal = 999.0;

  // BorderRadius objects
  static const BorderRadius xs = BorderRadius.all(Radius.circular(xsVal));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smVal));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdVal));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgVal));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlVal));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(xxlVal));
  static const BorderRadius xxxl = BorderRadius.all(Radius.circular(xxxlVal));
  static const BorderRadius full = BorderRadius.all(Radius.circular(fullVal));

  // Specialized sheet radius
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xxlVal));
}
