import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:astrack/core/theme/personalization_models.dart';
import 'package:astrack/core/theme/astrack_theme_extension.dart';
import 'package:astrack/app/theme/app_theme.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/core/localization/app_localizations.dart';
import 'package:astrack/features/settings/appearance_screen.dart';
import 'package:astrack/features/settings/language_settings_screen.dart';
import 'package:astrack/features/settings/widgets/live_preview_card.dart';
import 'package:astrack/features/settings/widgets/review_appearance_sheet.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Personalization Models & Design Tokens', () {
    test('AppAccentColor provides 6 calibrated options with light & dark values', () {
      expect(AppAccentColor.values.length, 6);
      expect(AppAccentColor.emerald.id, 'emerald');
      expect(AppAccentColor.blue.id, 'blue');
      expect(AppAccentColor.violet.id, 'violet');
      expect(AppAccentColor.pink.id, 'pink');
      expect(AppAccentColor.teal.id, 'teal');
      expect(AppAccentColor.orange.id, 'orange');

      // Light vs Dark resolution
      expect(AppAccentColor.emerald.getColor(false), const Color(0xFF059669));
      expect(AppAccentColor.emerald.getColor(true), const Color(0xFF10B981));
      expect(AppAccentColor.violet.getColor(false), const Color(0xFF7C3AED));
      expect(AppAccentColor.violet.getColor(true), const Color(0xFF8B5CF6));

      // Fallback
      expect(AppAccentColor.fromId(null), AppAccentColor.emerald);
      expect(AppAccentColor.fromId('unknown'), AppAccentColor.emerald);
      expect(AppAccentColor.fromId('blue'), AppAccentColor.blue);
    });

    test('AppTextScale provides correct scale factors', () {
      expect(AppTextScale.small.factor, 0.90);
      expect(AppTextScale.normal.factor, 1.00);
      expect(AppTextScale.large.factor, 1.15);
      expect(AppTextScale.extraLarge.factor, 1.30);

      expect(AppTextScale.fromId(null), AppTextScale.normal);
      expect(AppTextScale.fromId('large'), AppTextScale.large);
    });

    test('AppUiStyle controls radii, elevations, and border widths', () {
      expect(AppUiStyle.rounded.cardRadius, 24.0);
      expect(AppUiStyle.rounded.buttonRadius, 24.0);
      expect(AppUiStyle.rounded.cardElevation, 6.0);

      expect(AppUiStyle.soft.cardRadius, 16.0);
      expect(AppUiStyle.soft.buttonRadius, 14.0);
      expect(AppUiStyle.soft.cardElevation, 3.0);

      expect(AppUiStyle.crisp.cardRadius, 6.0);
      expect(AppUiStyle.crisp.buttonRadius, 6.0);
      expect(AppUiStyle.crisp.borderWidth, 1.0);
      expect(AppUiStyle.crisp.cardElevation, 0.0);

      expect(AppUiStyle.fromId(null), AppUiStyle.soft);
      expect(AppUiStyle.fromId('crisp'), AppUiStyle.crisp);
    });

    test('PersonalizationSettings supports equality, copyWith, and diff calculation', () {
      const original = PersonalizationSettings(
        themeMode: ThemeMode.system,
        accentColor: AppAccentColor.emerald,
        textScale: AppTextScale.normal,
        uiStyle: AppUiStyle.soft,
        locale: Locale('id', 'ID'),
      );

      final same = original.copyWith();
      expect(original == same, isTrue);

      final changed = original.copyWith(
        themeMode: ThemeMode.dark,
        accentColor: AppAccentColor.violet,
        textScale: AppTextScale.large,
        uiStyle: AppUiStyle.rounded,
        locale: const Locale('en', 'US'),
      );

      expect(original == changed, isFalse);

      final diffs = changed.diff(original);
      expect(diffs.length, 5);

      expect(diffs.any((d) => d.category == 'Tema' && d.newValue.contains('Gelap')), isTrue);
      expect(diffs.any((d) => d.category == 'Aksen' && d.newValue == 'Violet'), isTrue);
      expect(diffs.any((d) => d.category == 'Tipografi' && d.newValue == 'Besar'), isTrue);
      expect(diffs.any((d) => d.category == 'Gaya UI' && d.newValue == 'Rounded'), isTrue);
      expect(diffs.any((d) => d.category == 'Bahasa' && d.newValue == 'English'), isTrue);
    });
  });

  group('AstrackThemeExtension & AppTheme Integration', () {
    test('AstrackThemeExtension.build creates tailored extension', () {
      final ext = AstrackThemeExtension.build(
        isDark: false,
        accent: AppAccentColor.blue,
        uiStyle: AppUiStyle.crisp,
      );

      expect(ext.isDark, isFalse);
      expect(ext.primaryAccent, const Color(0xFF2563EB));
      expect(ext.cardRadius, 6.0);
      expect(ext.buttonRadius, 6.0);
      expect(ext.borderWidth, 1.0);
      expect(ext.cardElevation, 0.0);
    });

    test('AppTheme generates valid light and dark themes with dynamic tokens', () {
      final light = AppTheme.buildLightTheme(
        accent: AppAccentColor.orange,
        uiStyle: AppUiStyle.rounded,
      );

      expect(light.brightness, Brightness.light);
      expect(light.colorScheme.primary, const Color(0xFFEA580C));
      final ext = light.extension<AstrackThemeExtension>();
      expect(ext, isNotNull);
      expect(ext!.cardRadius, 24.0);

      final dark = AppTheme.buildDarkTheme(
        accent: AppAccentColor.teal,
        uiStyle: AppUiStyle.soft,
      );

      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.primary, const Color(0xFF14B8A6));
    });
  });

  group('StorageService & ThemeProvider Staging & Persistence', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
    });

    test('ThemeProvider loads defaults and handles direct setters', () async {
      final provider = ThemeProvider(storage);
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.accentColor, AppAccentColor.emerald);
      expect(provider.textScale, AppTextScale.normal);
      expect(provider.uiStyle, AppUiStyle.soft);
      expect(provider.locale.languageCode, 'id');

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(storage.getThemeMode(), 'dark');

      await provider.setAccentColor(AppAccentColor.pink);
      expect(provider.accentColor, AppAccentColor.pink);
      expect(storage.getAccentColor(), 'pink');

      await provider.setTextScale(AppTextScale.large);
      expect(provider.textScale, AppTextScale.large);
      expect(storage.getTextScale(), 'large');

      await provider.setUiStyle(AppUiStyle.crisp);
      expect(provider.uiStyle, AppUiStyle.crisp);
      expect(storage.getUiStyle(), 'crisp');

      await provider.setLocale(const Locale('en', 'US'));
      expect(provider.locale.languageCode, 'en');
      expect(storage.getLanguage(), 'en');
    });

    test('ThemeProvider handles staging workflow: start, update, discard, apply', () async {
      final provider = ThemeProvider(storage);
      expect(provider.hasUnsavedChanges, isFalse);
      expect(provider.changeCount, 0);

      // Start staging
      provider.startStaging();
      expect(provider.hasUnsavedChanges, isFalse);

      // Update staged
      final staged = provider.currentSettings.copyWith(
        themeMode: ThemeMode.dark,
        accentColor: AppAccentColor.violet,
      );
      provider.updateStaged(staged);

      expect(provider.hasUnsavedChanges, isTrue);
      expect(provider.changeCount, 2);
      expect(provider.activeSettings.themeMode, ThemeMode.system); // active remains untouched!

      // Discard
      provider.discardStaged();
      expect(provider.hasUnsavedChanges, isFalse);
      expect(provider.changeCount, 0);

      // Stage again and Apply
      provider.startStaging();
      provider.updateStaged(provider.currentSettings.copyWith(
        accentColor: AppAccentColor.teal,
        uiStyle: AppUiStyle.rounded,
      ));
      expect(provider.hasUnsavedChanges, isTrue);

      await provider.applyStaged();
      expect(provider.hasUnsavedChanges, isFalse);
      expect(provider.accentColor, AppAccentColor.teal);
      expect(provider.uiStyle, AppUiStyle.rounded);
      expect(storage.getAccentColor(), 'teal');
      expect(storage.getUiStyle(), 'rounded');

      // Restart persistence test
      final reloadedProvider = ThemeProvider(storage);
      expect(reloadedProvider.accentColor, AppAccentColor.teal);
      expect(reloadedProvider.uiStyle, AppUiStyle.rounded);
    });
  });

  group('LivePreviewCard Widget Tests', () {
    testWidgets('Renders real ASTRACK components inside LivePreviewCard', (tester) async {
      const settings = PersonalizationSettings(
        themeMode: ThemeMode.dark,
        accentColor: AppAccentColor.blue,
        textScale: AppTextScale.normal,
        uiStyle: AppUiStyle.rounded,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LivePreviewCard(settings: settings),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Total Saldo'), findsOneWidget);
      expect(find.text('Rp 14.850.000'), findsOneWidget);
      expect(find.text('Dompet Utama'), findsOneWidget);
      expect(find.text('Kopi Kenangan Mantan'), findsOneWidget);
      expect(find.text('Catat Pengeluaran'), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
    });
  });

  group('ReviewAppearanceSheet Widget Tests', () {
    testWidgets('Displays changes and executes atomic apply or discard callbacks', (tester) async {
      bool applied = false;
      bool discarded = false;

      final diffs = [
        const SettingDiffItem(
          category: 'Tema',
          label: 'Mode Tampilan',
          oldValue: 'Sistem',
          newValue: 'Gelap (Dark)',
          icon: Icons.brightness_6_rounded,
        ),
        const SettingDiffItem(
          category: 'Aksen',
          label: 'Warna Aksen',
          oldValue: 'Emerald',
          newValue: 'Violet',
          icon: Icons.palette_rounded,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ReviewAppearanceSheet(
              diffs: diffs,
              onDiscard: () => discarded = true,
              onApply: () => applied = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tinjau Perubahan Tampilan'), findsOneWidget);
      expect(find.text('Mode Tampilan'), findsOneWidget);
      expect(find.text('Warna Aksen'), findsOneWidget);
      expect(find.text('Gelap (Dark)'), findsOneWidget);
      expect(find.text('Violet'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Terapkan Perubahan'));
      await tester.pumpAndSettle();
      expect(applied, isTrue);
      expect(discarded, isFalse);
    });
  });

  group('AppearanceScreen Full Integration Tests', () {
    late StorageService storage;
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      themeProvider = ThemeProvider(storage);
    });

    Widget createTestApp({Size size = const Size(390, 844)}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: themeProvider.lightThemeData,
          darkTheme: themeProvider.darkThemeData,
          themeMode: themeProvider.themeMode,
          locale: themeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: const AppearanceScreen(),
          ),
        ),
      );
    }

    testWidgets('Renders all controls and toggles unsaved changes on selection', (tester) async {
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(size: const Size(500, 2400)));
      await tester.pumpAndSettle();

      // Verify sections are present
      expect(find.text('PRATINJAU LANGSUNG'), findsOneWidget);
      expect(find.text('TEMA APLIKASI'), findsOneWidget);
      expect(find.text('WARNA AKSEN'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('GAYA TAMPILAN'), findsOneWidget);

      // Verify options
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);

      expect(find.text('Emerald'), findsWidgets);
      expect(find.text('Blue'), findsWidgets);
      expect(find.text('Violet'), findsWidgets);
      expect(find.text('Pink'), findsWidgets);
      expect(find.text('Teal'), findsWidgets);
      expect(find.text('Orange'), findsWidgets);

      expect(find.text('Rounded'), findsWidgets);
      expect(find.text('Soft'), findsWidgets);
      expect(find.text('Crisp'), findsWidgets);

      // No unsaved changes initially
      expect(find.text('Tinjau'), findsNothing);

      // Tap "Gelap"
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      // Now sticky bar appears!
      expect(find.text('Tinjau'), findsOneWidget);
      expect(find.text('1 perubahan'), findsOneWidget);

      // Tap "Violet"
      await tester.tap(find.text('Violet').first);
      await tester.pumpAndSettle();
      expect(find.text('2 perubahan'), findsOneWidget);

      // Tap "Batal"
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Unsaved changes cleared
      expect(find.text('Tinjau'), findsNothing);
    });

    testWidgets('Tablet/iPad responsive layout renders two panes', (tester) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(size: const Size(1024, 1366)));
      await tester.pumpAndSettle();

      // Both Controls and Live Preview are visible without overlapping
      expect(find.text('PRATINJAU LANGSUNG'), findsOneWidget);
      expect(find.text('TEMA APLIKASI'), findsOneWidget);
      expect(find.text('WARNA AKSEN'), findsOneWidget);
      expect(find.text('UKURAN TEKS'), findsOneWidget);
      expect(find.text('GAYA TAMPILAN'), findsOneWidget);
    });
  });

  group('LanguageSettingsScreen Integration Tests', () {
    late StorageService storage;
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      themeProvider = ThemeProvider(storage);
    });

    testWidgets('Selects English and applies language atomically', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: themeProvider.lightThemeData,
            locale: themeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const LanguageSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Select English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Sticky bar appears with "1 perubahan" and "Terapkan Perubahan"
      expect(find.text('1 perubahan'), findsOneWidget);
      expect(find.text('Terapkan Perubahan'), findsOneWidget);

      // Apply
      await tester.tap(find.text('Terapkan Perubahan'));
      await tester.pumpAndSettle();

      expect(themeProvider.locale.languageCode, 'en');
      expect(storage.getLanguage(), 'en');
    });
  });
}
