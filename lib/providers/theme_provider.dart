import 'package:flutter/material.dart';
import '../data/storage/storage_service.dart';
import '../core/theme/personalization_models.dart';
import '../app/theme/app_theme.dart';

/// Centralized Provider managing Theme, Accent Colors, Typography Scaling,
/// UI Style Tokens, and Localization Preferences with Atomic Staging Support.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;

  PersonalizationSettings _activeSettings = const PersonalizationSettings(
    themeMode: ThemeMode.light,
    accentColor: AppAccentColor.emerald,
    textScale: AppTextScale.normal,
    uiStyle: AppUiStyle.soft,
    locale: Locale('id', 'ID'),
  );

  PersonalizationSettings? _stagedSettings;

  ThemeProvider(this._storage) {
    _loadSettings();
  }

  // --- Getters ---
  PersonalizationSettings get activeSettings => _activeSettings;
  PersonalizationSettings get currentSettings => _stagedSettings ?? _activeSettings;
  PersonalizationSettings? get stagedSettings => _stagedSettings;

  ThemeMode get themeMode => _activeSettings.themeMode;
  AppAccentColor get accentColor => _activeSettings.accentColor;
  AppTextScale get textScale => _activeSettings.textScale;
  AppUiStyle get uiStyle => _activeSettings.uiStyle;
  Locale get locale => _activeSettings.locale;

  bool get hasUnsavedChanges => _stagedSettings != null && _stagedSettings != _activeSettings;
  int get changeCount => _stagedSettings == null ? 0 : _stagedSettings!.diff(_activeSettings).length;
  List<SettingDiffItem> get pendingDiffs => _stagedSettings == null ? [] : _stagedSettings!.diff(_activeSettings);

  bool get isDarkMode {
    if (_activeSettings.themeMode == ThemeMode.dark) return true;
    if (_activeSettings.themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  ThemeData get lightThemeData => AppTheme.buildLightTheme(
        accent: _activeSettings.accentColor,
        uiStyle: _activeSettings.uiStyle,
      );

  ThemeData get darkThemeData => AppTheme.buildDarkTheme(
        accent: _activeSettings.accentColor,
        uiStyle: _activeSettings.uiStyle,
      );

  // --- Load & Save ---
  void _loadSettings() {
    final savedModeStr = _storage.getThemeMode();
    ThemeMode mode = ThemeMode.light;
    if (savedModeStr == 'dark') {
      mode = ThemeMode.dark;
    } else if (savedModeStr == 'system') {
      mode = ThemeMode.system;
    } else if (savedModeStr == 'light') {
      mode = ThemeMode.light;
    }

    final savedAccent = AppAccentColor.fromId(_storage.getAccentColor());
    final savedScale = AppTextScale.fromId(_storage.getTextScale());
    final savedStyle = AppUiStyle.fromId(_storage.getUiStyle());
    final langCode = _storage.getLanguage();
    final loc = langCode == 'en' ? const Locale('en', 'US') : const Locale('id', 'ID');

    _activeSettings = PersonalizationSettings(
      themeMode: mode,
      accentColor: savedAccent,
      textScale: savedScale,
      uiStyle: savedStyle,
      locale: loc,
    );
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    String modeStr = 'system';
    if (_activeSettings.themeMode == ThemeMode.dark) modeStr = 'dark';
    if (_activeSettings.themeMode == ThemeMode.light) modeStr = 'light';

    await _storage.setThemeMode(modeStr);
    await _storage.setAccentColor(_activeSettings.accentColor.id);
    await _storage.setTextScale(_activeSettings.textScale.id);
    await _storage.setUiStyle(_activeSettings.uiStyle.id);
    await _storage.setLanguage(_activeSettings.locale.languageCode);
  }

  // --- Staging Workflow (For Appearance Screen) ---
  void startStaging() {
    _stagedSettings = _activeSettings.copyWith();
    notifyListeners();
  }

  void updateStaged(PersonalizationSettings newSettings) {
    _stagedSettings = newSettings;
    notifyListeners();
  }

  void discardStaged() {
    _stagedSettings = null;
    notifyListeners();
  }

  Future<void> applyStaged() async {
    if (_stagedSettings == null) return;
    _activeSettings = _stagedSettings!;
    _stagedSettings = null;
    await _persistSettings();
    notifyListeners();
  }

  // --- Direct Setters (Instant / Test Compatibility) ---
  Future<void> setThemeMode(ThemeMode mode) async {
    _activeSettings = _activeSettings.copyWith(themeMode: mode);
    String str = 'system';
    if (mode == ThemeMode.dark) str = 'dark';
    if (mode == ThemeMode.light) str = 'light';
    await _storage.setThemeMode(str);
    notifyListeners();
  }

  void toggleTheme() {
    if (isDarkMode) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setAccentColor(AppAccentColor color) async {
    _activeSettings = _activeSettings.copyWith(accentColor: color);
    await _storage.setAccentColor(color.id);
    notifyListeners();
  }

  Future<void> setTextScale(AppTextScale scale) async {
    _activeSettings = _activeSettings.copyWith(textScale: scale);
    await _storage.setTextScale(scale.id);
    notifyListeners();
  }

  Future<void> setUiStyle(AppUiStyle style) async {
    _activeSettings = _activeSettings.copyWith(uiStyle: style);
    await _storage.setUiStyle(style.id);
    notifyListeners();
  }

  Future<void> setLocale(Locale loc) async {
    _activeSettings = _activeSettings.copyWith(locale: loc);
    await _storage.setLanguage(loc.languageCode);
    notifyListeners();
  }
}
