import 'package:flutter/material.dart';

/// Window Size Classes per Material 3 & ASTRACK Adaptive Guidelines
enum WindowSizeClass {
  /// Phone portrait, small foldable outer screen (< 600 dp)
  compact,

  /// Phone landscape, small tablet portrait, foldable unfolded (600 - 840 dp)
  medium,

  /// Tablet landscape, Desktop (> 840 dp)
  expanded,
}

/// Centralized Responsive Breakpoints & Width Thresholds
class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 600.0;
  static const double mediumMax = 840.0;

  // Maximum content readable widths (prevents horizontal over-stretching)
  static const double maxContentWidthPhone = 580.0;
  static const double maxContentWidthForm = 640.0;
  static const double maxContentWidthTablet = 840.0;
  static const double maxContentWidthWide = 1120.0;
}

/// BuildContext extension for reactive screen size queries
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  Orientation get orientation => MediaQuery.orientationOf(this);

  WindowSizeClass get windowSizeClass {
    final width = screenWidth;
    if (width < AppBreakpoints.compactMax) {
      return WindowSizeClass.compact;
    } else if (width <= AppBreakpoints.mediumMax) {
      return WindowSizeClass.medium;
    } else {
      return WindowSizeClass.expanded;
    }
  }

  bool get isCompact => windowSizeClass == WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;
  bool get isTabletOrLarger => screenWidth >= AppBreakpoints.compactMax;

  /// Responsive value selector
  T responsiveValue<T>({
    required T compact,
    T? medium,
    T? expanded,
  }) {
    switch (windowSizeClass) {
      case WindowSizeClass.compact:
        return compact;
      case WindowSizeClass.medium:
        return medium ?? compact;
      case WindowSizeClass.expanded:
        return expanded ?? medium ?? compact;
    }
  }
}
