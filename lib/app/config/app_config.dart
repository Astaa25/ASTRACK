/// ASTRACK Centralized Application Configuration
/// Versioning follows Semantic Versioning: MAJOR.MINOR.PATCH
class AppConfig {
  static const String appName = 'ASTRACK';
  static const String tagline = 'Track Your Money, Shape Your Future';
  static const String version = '2.0.0';
  static const int buildNumber = 2;
  static const String author = 'Abrar Astafaraiz';
  static const String copyright = '© 2026 ASTRACK. All rights reserved.';
  static const String website = 'https://astrack.app';
  static const String supportEmail = 'support@astrack.app';

  // Splash Configuration
  static const int splashMinDurationMs = 1200;
  static const int splashMaxDurationMs = 2000;

  // Privacy Defaults
  static const bool defaultHideBalance = true;
  static const bool defaultAutoLock = false;
  static const int autoLockMinutes = 5;

  // Currency
  static const String defaultCurrencySymbol = 'Rp';
  static const String defaultCurrencyCode = 'IDR';
  static const String defaultLocale = 'id_ID';
}
