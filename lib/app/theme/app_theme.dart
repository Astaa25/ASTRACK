import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/personalization_models.dart';

class AppTheme {
  /// Builds a customized Light Theme honoring user accent color and UI style tokens
  static ThemeData buildLightTheme({
    AppAccentColor accent = AppAccentColor.emerald,
    AppUiStyle uiStyle = AppUiStyle.soft,
  }) {
    final baseTextTheme = ThemeData.light().textTheme;
    final accentColor = accent.getColor(false);
    final themeExt = AstrackThemeExtension.build(
      isDark: false,
      accent: accent,
      uiStyle: uiStyle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: AppColors.lightDarkGreen,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
        error: AppColors.expense,
      ),
      extensions: [themeExt],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: uiStyle.cardElevation,
        shadowColor: const Color(0x0F000000),
        shape: RoundedRectangleBorder(
          borderRadius: uiStyle.cardBorderRadius,
          side: BorderSide(color: AppColors.lightBorder, width: uiStyle.borderWidth),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        triggerMode: TooltipTriggerMode.manual,
        waitDuration: Duration(days: 365),
        showDuration: Duration.zero,
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: const Color(0x14000000),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: uiStyle == AppUiStyle.crisp ? 0 : 4,
          shadowColor: accentColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: uiStyle.buttonBorderRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? Colors.black26 : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: uiStyle.borderWidth > 0.8 ? 1.5 : 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: uiStyle.buttonBorderRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.lightBorder, width: uiStyle.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.lightBorder, width: uiStyle.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Builds a customized Dark Theme honoring user accent color and UI style tokens
  static ThemeData buildDarkTheme({
    AppAccentColor accent = AppAccentColor.emerald,
    AppUiStyle uiStyle = AppUiStyle.soft,
  }) {
    final baseTextTheme = ThemeData.dark().textTheme;
    final accentColor = accent.getColor(true);
    final themeExt = AstrackThemeExtension.build(
      isDark: true,
      accent: accent,
      uiStyle: uiStyle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: AppColors.darkMainBg,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
        error: AppColors.expenseDark,
      ),
      extensions: [themeExt],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: uiStyle.cardBorderRadius,
          side: BorderSide(color: AppColors.darkBorder, width: uiStyle.borderWidth),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        triggerMode: TooltipTriggerMode.manual,
        waitDuration: Duration(days: 365),
        showDuration: Duration.zero,
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: const Color(0x14FFFFFF),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: uiStyle.buttonBorderRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? Colors.white24 : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: uiStyle.buttonBorderRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevatedCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.darkBorder, width: uiStyle.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.darkBorder, width: uiStyle.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: uiStyle.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.expenseDark),
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkMuted,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Default Light Theme (Backward-compatible getter)
  static ThemeData get lightTheme => buildLightTheme();

  /// Default Dark Theme (Backward-compatible getter)
  static ThemeData get darkTheme => buildDarkTheme();

  /// Ambient background decoration with subtle emerald glow for Dark Mode
  static BoxDecoration darkBackgroundDecoration() {
    return const BoxDecoration(
      color: AppColors.darkMainBg,
      gradient: RadialGradient(
        center: Alignment(0.8, -0.9),
        radius: 1.2,
        colors: [
          Color(0x2022C55E),
          AppColors.darkMainBg,
        ],
        stops: [0.0, 0.6],
      ),
    );
  }

  /// Ambient background decoration for Light Mode
  static BoxDecoration lightBackgroundDecoration() {
    return const BoxDecoration(
      color: AppColors.lightBg,
      gradient: RadialGradient(
        center: Alignment(0.5, -0.8),
        radius: 1.5,
        colors: [
          Color(0xFFF0F5F3),
          AppColors.lightBg,
        ],
        stops: [0.0, 0.8],
      ),
    );
  }
}
