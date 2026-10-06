import 'package:flutter/material.dart';
import 'personalization_models.dart';

/// Centralized ThemeExtension for ASTRACK Design System
class AstrackThemeExtension extends ThemeExtension<AstrackThemeExtension> {
  final Color primaryEmerald;
  final Color primaryAccent;
  final Color primaryAccentTint;
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color income;
  final Color expense;
  final Color transfer;
  final Color saving;
  final Color warning;
  final Color goldAccent;
  final bool isDark;
  final AppUiStyle uiStyle;
  final double cardRadius;
  final double buttonRadius;
  final double chipRadius;
  final double inputRadius;
  final double cardElevation;
  final double borderWidth;

  const AstrackThemeExtension({
    required this.primaryEmerald,
    required this.primaryAccent,
    required this.primaryAccentTint,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.saving,
    required this.warning,
    required this.goldAccent,
    required this.isDark,
    this.uiStyle = AppUiStyle.soft,
    this.cardRadius = 16.0,
    this.buttonRadius = 14.0,
    this.chipRadius = 12.0,
    this.inputRadius = 14.0,
    this.cardElevation = 3.0,
    this.borderWidth = 0.75,
  });

  BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);
  BorderRadius get buttonBorderRadius => BorderRadius.circular(buttonRadius);
  BorderRadius get chipBorderRadius => BorderRadius.circular(chipRadius);
  BorderRadius get inputBorderRadius => BorderRadius.circular(inputRadius);

  /// Light Mode Preset (Emerald × Pure White/Slate)
  static const AstrackThemeExtension light = AstrackThemeExtension(
    primaryEmerald: Color(0xFF059669), // Vivid refined Emerald
    primaryAccent: Color(0xFF059669),
    primaryAccentTint: Color(0xFFECFDF5),
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF4F6F5),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    income: Color(0xFF16A34A),
    expense: Color(0xFFDC2626),
    transfer: Color(0xFF2563EB),
    saving: Color(0xFF0D9488),
    warning: Color(0xFFD97706),
    goldAccent: Color(0xFFD97706),
    isDark: false,
    uiStyle: AppUiStyle.soft,
    cardRadius: 16.0,
    buttonRadius: 14.0,
    chipRadius: 12.0,
    inputRadius: 14.0,
    cardElevation: 3.0,
    borderWidth: 0.75,
  );

  /// Dark Mode Preset (Emerald × Charcoal/Obsidian)
  static const AstrackThemeExtension dark = AstrackThemeExtension(
    primaryEmerald: Color(0xFF10B981), // Luminous Emerald accent for dark surface
    primaryAccent: Color(0xFF10B981),
    primaryAccentTint: Color(0xFF064E3B),
    background: Color(0xFF090D0B),
    surface: Color(0xFF111815),
    surfaceSubtle: Color(0xFF17221E),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF1E2E27),
    income: Color(0xFF22C55E),
    expense: Color(0xFFEF4444),
    transfer: Color(0xFF3B82F6),
    saving: Color(0xFF14B8A6),
    warning: Color(0xFFFBBF24),
    goldAccent: Color(0xFFFBBF24),
    isDark: true,
    uiStyle: AppUiStyle.soft,
    cardRadius: 16.0,
    buttonRadius: 14.0,
    chipRadius: 12.0,
    inputRadius: 14.0,
    cardElevation: 0.0,
    borderWidth: 0.75,
  );

  /// Dynamic ThemeExtension generator with customized accent color & UI style
  factory AstrackThemeExtension.build({
    required bool isDark,
    AppAccentColor accent = AppAccentColor.emerald,
    AppUiStyle uiStyle = AppUiStyle.soft,
  }) {
    final base = isDark ? AstrackThemeExtension.dark : AstrackThemeExtension.light;
    return base.copyWith(
      primaryAccent: accent.getColor(isDark),
      primaryAccentTint: accent.getTint(isDark),
      uiStyle: uiStyle,
      cardRadius: uiStyle.cardRadius,
      buttonRadius: uiStyle.buttonRadius,
      chipRadius: uiStyle.chipRadius,
      inputRadius: uiStyle.inputRadius,
      cardElevation: isDark ? 0.0 : uiStyle.cardElevation,
      borderWidth: uiStyle.borderWidth,
    );
  }

  @override
  AstrackThemeExtension copyWith({
    Color? primaryEmerald,
    Color? primaryAccent,
    Color? primaryAccentTint,
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? income,
    Color? expense,
    Color? transfer,
    Color? saving,
    Color? warning,
    Color? goldAccent,
    bool? isDark,
    AppUiStyle? uiStyle,
    double? cardRadius,
    double? buttonRadius,
    double? chipRadius,
    double? inputRadius,
    double? cardElevation,
    double? borderWidth,
  }) {
    return AstrackThemeExtension(
      primaryEmerald: primaryEmerald ?? this.primaryEmerald,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      primaryAccentTint: primaryAccentTint ?? this.primaryAccentTint,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      saving: saving ?? this.saving,
      warning: warning ?? this.warning,
      goldAccent: goldAccent ?? this.goldAccent,
      isDark: isDark ?? this.isDark,
      uiStyle: uiStyle ?? this.uiStyle,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      cardElevation: cardElevation ?? this.cardElevation,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  ThemeExtension<AstrackThemeExtension> lerp(
    covariant ThemeExtension<AstrackThemeExtension>? other,
    double t,
  ) {
    if (other is! AstrackThemeExtension) return this;
    return AstrackThemeExtension(
      primaryEmerald: Color.lerp(primaryEmerald, other.primaryEmerald, t) ?? primaryEmerald,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t) ?? primaryAccent,
      primaryAccentTint: Color.lerp(primaryAccentTint, other.primaryAccentTint, t) ?? primaryAccentTint,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t) ?? surfaceSubtle,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      border: Color.lerp(border, other.border, t) ?? border,
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      transfer: Color.lerp(transfer, other.transfer, t) ?? transfer,
      saving: Color.lerp(saving, other.saving, t) ?? saving,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t) ?? goldAccent,
      isDark: t < 0.5 ? isDark : other.isDark,
      uiStyle: t < 0.5 ? uiStyle : other.uiStyle,
      cardRadius: (cardRadius + (other.cardRadius - cardRadius) * t),
      buttonRadius: (buttonRadius + (other.buttonRadius - buttonRadius) * t),
      chipRadius: (chipRadius + (other.chipRadius - chipRadius) * t),
      inputRadius: (inputRadius + (other.inputRadius - inputRadius) * t),
      cardElevation: (cardElevation + (other.cardElevation - cardElevation) * t),
      borderWidth: (borderWidth + (other.borderWidth - borderWidth) * t),
    );
  }
}

/// BuildContext extension for effortless token retrieval
extension AstrackThemeContext on BuildContext {
  AstrackThemeExtension get astrackTheme {
    final ext = Theme.of(this).extension<AstrackThemeExtension>();
    if (ext != null) return ext;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AstrackThemeExtension.dark : AstrackThemeExtension.light;
  }
}
