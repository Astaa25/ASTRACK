import 'package:flutter/material.dart';

/// Supported Accent Colors for ASTRACK
/// Accent is applied strictly on CTAs, active nav, progress, and highlights.
/// Surfaces and backgrounds remain strictly compliant with the Dark/Light palette.
enum AppAccentColor {
  emerald(
    id: 'emerald',
    name: 'Emerald',
    subtitle: 'Default ASTRACK',
    lightColor: Color(0xFF059669),
    darkColor: Color(0xFF10B981),
    lightTint: Color(0xFFECFDF5),
    darkTint: Color(0xFF064E3B),
  ),
  blue(
    id: 'blue',
    name: 'Blue',
    subtitle: 'Electric Fintech Blue',
    lightColor: Color(0xFF2563EB),
    darkColor: Color(0xFF3B82F6),
    lightTint: Color(0xFFEFF6FF),
    darkTint: Color(0xFF1E3A8A),
  ),
  violet(
    id: 'violet',
    name: 'Violet',
    subtitle: 'Royal Amethyst Violet',
    lightColor: Color(0xFF7C3AED),
    darkColor: Color(0xFF8B5CF6),
    lightTint: Color(0xFFF5F3FF),
    darkTint: Color(0xFF4C1D95),
  ),
  pink(
    id: 'pink',
    name: 'Pink',
    subtitle: 'Vibrant Magenta Pink',
    lightColor: Color(0xFFDB2777),
    darkColor: Color(0xFFEC4899),
    lightTint: Color(0xFFFDF2F8),
    darkTint: Color(0xFF831843),
  ),
  teal(
    id: 'teal',
    name: 'Teal',
    subtitle: 'Deep Oceanic Teal',
    lightColor: Color(0xFF0D9488),
    darkColor: Color(0xFF14B8A6),
    lightTint: Color(0xFFF0FDFA),
    darkTint: Color(0xFF134E4A),
  ),
  orange(
    id: 'orange',
    name: 'Orange',
    subtitle: 'Energetic Amber Orange',
    lightColor: Color(0xFFEA580C),
    darkColor: Color(0xFFF97316),
    lightTint: Color(0xFFFFF7ED),
    darkTint: Color(0xFF7C2D12),
  );

  final String id;
  final String name;
  final String subtitle;
  final Color lightColor;
  final Color darkColor;
  final Color lightTint;
  final Color darkTint;

  const AppAccentColor({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.lightColor,
    required this.darkColor,
    required this.lightTint,
    required this.darkTint,
  });

  Color getColor(bool isDark) => isDark ? darkColor : lightColor;
  Color getTint(bool isDark) => isDark ? darkTint : lightTint;

  static AppAccentColor fromId(String? id) {
    if (id == null) return AppAccentColor.emerald;
    for (final color in AppAccentColor.values) {
      if (color.id == id) return color;
    }
    return AppAccentColor.emerald;
  }
}

/// Text Size Scaling Preference for ASTRACK
/// Scales typography properly while preserving responsiveness and layout integrity.
enum AppTextScale {
  small(
    id: 'small',
    label: 'Kecil',
    englishLabel: 'Small',
    factor: 0.90,
  ),
  normal(
    id: 'normal',
    label: 'Standar',
    englishLabel: 'Default',
    factor: 1.00,
  ),
  large(
    id: 'large',
    label: 'Besar',
    englishLabel: 'Large',
    factor: 1.15,
  ),
  extraLarge(
    id: 'extraLarge',
    label: 'Ekstra Besar',
    englishLabel: 'Extra Large',
    factor: 1.30,
  );

  final String id;
  final String label;
  final String englishLabel;
  final double factor;

  const AppTextScale({
    required this.id,
    required this.label,
    required this.englishLabel,
    required this.factor,
  });

  static AppTextScale fromId(String? id) {
    if (id == null) return AppTextScale.normal;
    for (final scale in AppTextScale.values) {
      if (scale.id == id) return scale;
    }
    return AppTextScale.normal;
  }
}

/// UI Style Presets for ASTRACK
/// Directly drives corner radius, border width, card elevation, and surface treatment.
enum AppUiStyle {
  rounded(
    id: 'rounded',
    name: 'Rounded',
    description: 'Lengkungan organik yang ramah dan lembut dengan elevasi halus.',
    cardRadius: 24.0,
    buttonRadius: 24.0,
    chipRadius: 20.0,
    inputRadius: 18.0,
    cardElevation: 6.0,
    borderWidth: 0.5,
  ),
  soft(
    id: 'soft',
    name: 'Soft',
    description: 'Keseimbangan modern fintech dengan aksen dan sudut terkalibrasi.',
    cardRadius: 16.0,
    buttonRadius: 14.0,
    chipRadius: 12.0,
    inputRadius: 14.0,
    cardElevation: 3.0,
    borderWidth: 0.75,
  ),
  crisp(
    id: 'crisp',
    name: 'Crisp',
    description: 'Presisi tinggi dengan sudut tegas dan garis hairline ala Swiss terminal.',
    cardRadius: 6.0,
    buttonRadius: 6.0,
    chipRadius: 4.0,
    inputRadius: 6.0,
    cardElevation: 0.0,
    borderWidth: 1.0,
  );

  final String id;
  final String name;
  final String description;
  final double cardRadius;
  final double buttonRadius;
  final double chipRadius;
  final double inputRadius;
  final double cardElevation;
  final double borderWidth;

  const AppUiStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.cardRadius,
    required this.buttonRadius,
    required this.chipRadius,
    required this.inputRadius,
    required this.cardElevation,
    required this.borderWidth,
  });

  BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);
  BorderRadius get buttonBorderRadius => BorderRadius.circular(buttonRadius);
  BorderRadius get chipBorderRadius => BorderRadius.circular(chipRadius);
  BorderRadius get inputBorderRadius => BorderRadius.circular(inputRadius);

  static AppUiStyle fromId(String? id) {
    if (id == null) return AppUiStyle.soft;
    for (final style in AppUiStyle.values) {
      if (style.id == id) return style;
    }
    return AppUiStyle.soft;
  }
}

/// Represents a single difference between original and staged settings
class SettingDiffItem {
  final String category;
  final String label;
  final String oldValue;
  final String newValue;
  final IconData icon;
  final Color? colorPreview;

  const SettingDiffItem({
    required this.category,
    required this.label,
    required this.oldValue,
    required this.newValue,
    required this.icon,
    this.colorPreview,
  });
}

/// Centralized state model for ASTRACK Personalization
class PersonalizationSettings {
  final ThemeMode themeMode;
  final AppAccentColor accentColor;
  final AppTextScale textScale;
  final AppUiStyle uiStyle;
  final Locale locale;

  const PersonalizationSettings({
    this.themeMode = ThemeMode.light,
    this.accentColor = AppAccentColor.emerald,
    this.textScale = AppTextScale.normal,
    this.uiStyle = AppUiStyle.soft,
    this.locale = const Locale('id', 'ID'),
  });

  PersonalizationSettings copyWith({
    ThemeMode? themeMode,
    AppAccentColor? accentColor,
    AppTextScale? textScale,
    AppUiStyle? uiStyle,
    Locale? locale,
  }) {
    return PersonalizationSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      textScale: textScale ?? this.textScale,
      uiStyle: uiStyle ?? this.uiStyle,
      locale: locale ?? this.locale,
    );
  }

  /// Calculates human-readable diff list against [original]
  List<SettingDiffItem> diff(PersonalizationSettings original) {
    final diffs = <SettingDiffItem>[];

    if (themeMode != original.themeMode) {
      String nameOf(ThemeMode m) {
        switch (m) {
          case ThemeMode.system:
            return 'Sistem';
          case ThemeMode.light:
            return 'Terang (Light)';
          case ThemeMode.dark:
            return 'Gelap (Dark)';
        }
      }

      diffs.add(SettingDiffItem(
        category: 'Tema',
        label: 'Mode Tampilan',
        oldValue: nameOf(original.themeMode),
        newValue: nameOf(themeMode),
        icon: Icons.brightness_6_rounded,
      ));
    }

    if (accentColor != original.accentColor) {
      diffs.add(SettingDiffItem(
        category: 'Aksen',
        label: 'Warna Aksen',
        oldValue: original.accentColor.name,
        newValue: accentColor.name,
        icon: Icons.palette_rounded,
        colorPreview: accentColor.lightColor,
      ));
    }

    if (textScale != original.textScale) {
      diffs.add(SettingDiffItem(
        category: 'Tipografi',
        label: 'Ukuran Teks',
        oldValue: original.textScale.label,
        newValue: textScale.label,
        icon: Icons.format_size_rounded,
      ));
    }

    if (uiStyle != original.uiStyle) {
      diffs.add(SettingDiffItem(
        category: 'Gaya UI',
        label: 'Gaya Tampilan',
        oldValue: original.uiStyle.name,
        newValue: uiStyle.name,
        icon: Icons.rounded_corner_rounded,
      ));
    }

    if (locale.languageCode != original.locale.languageCode) {
      String langName(Locale l) => l.languageCode == 'en' ? 'English' : 'Bahasa Indonesia';
      diffs.add(SettingDiffItem(
        category: 'Bahasa',
        label: 'Bahasa Aplikasi',
        oldValue: langName(original.locale),
        newValue: langName(locale),
        icon: Icons.language_rounded,
      ));
    }

    return diffs;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalizationSettings &&
        other.themeMode == themeMode &&
        other.accentColor == accentColor &&
        other.textScale == textScale &&
        other.uiStyle == uiStyle &&
        other.locale.languageCode == locale.languageCode;
  }

  @override
  int get hashCode => Object.hash(themeMode, accentColor, textScale, uiStyle, locale.languageCode);
}
