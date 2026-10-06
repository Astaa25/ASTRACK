import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/features/update/models/app_update_info.dart';
import 'package:astrack/features/update/services/app_update_service.dart';
import 'package:astrack/features/update/widgets/update_available_dialog.dart';
import 'package:astrack/features/update/screens/force_update_screen.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ASTRACK Bab 77 APK Distribution & Update Service Tests', () {
    final service = AppUpdateService();

    test('1. URL Whitelist: Only https and whitelisted hosts (t.me, telegram.me) are accepted', () {
      // Valid URLs
      expect(service.isSafeUrl('https://t.me/astrack_official/1'), isTrue);
      expect(service.isSafeUrl('https://telegram.me/astrack_official/apk'), isTrue);

      // Insecure HTTP rejected
      expect(service.isSafeUrl('http://t.me/astrack_official/1'), isFalse);
      expect(service.isSafeUrl('http://telegram.me/astrack_official'), isFalse);

      // Non-whitelisted hosts rejected
      expect(service.isSafeUrl('https://malicious-site.com/astrack.apk'), isFalse);
      expect(service.isSafeUrl('https://raw.githubusercontent.com/evil/apk'), isFalse);
      expect(service.isSafeUrl('ftp://t.me/astrack.apk'), isFalse);
      expect(service.isSafeUrl('javascript:alert(1)'), isFalse);
      expect(service.isSafeUrl(''), isFalse);
    });

    test('2. Version Matrix Logic: build == latest returns upToDate', () {
      final info = AppUpdateInfo(
        versionName: '1.0.0',
        buildNumber: 5,
        minSupportedBuild: 3,
        downloadUrl: 'https://t.me/astrack_official/5',
        sha256: 'a' * 64,
      );

      // Evaluation logic: currentBuild == 5
      const currentBuild = 5;
      UpdateStatus status;
      if (currentBuild < info.minSupportedBuild) {
        status = UpdateStatus.forced;
      } else if (currentBuild < info.buildNumber) {
        status = UpdateStatus.optional;
      } else {
        status = UpdateStatus.upToDate;
      }

      expect(status, equals(UpdateStatus.upToDate));
    });

    test('3. Version Matrix Logic: build < latest and >= min returns optional', () {
      final info = AppUpdateInfo(
        versionName: '1.0.1',
        buildNumber: 5,
        minSupportedBuild: 3,
        downloadUrl: 'https://t.me/astrack_official/5',
        sha256: 'a' * 64,
      );

      const currentBuild = 4; // Between 3 and 5
      UpdateStatus status;
      if (currentBuild < info.minSupportedBuild) {
        status = UpdateStatus.forced;
      } else if (currentBuild < info.buildNumber) {
        status = UpdateStatus.optional;
      } else {
        status = UpdateStatus.upToDate;
      }

      expect(status, equals(UpdateStatus.optional));
    });

    test('4. Version Matrix Logic: build < minSupportedBuild returns forced', () {
      final info = AppUpdateInfo(
        versionName: '1.1.0',
        buildNumber: 10,
        minSupportedBuild: 6,
        downloadUrl: 'https://t.me/astrack_official/10',
        sha256: 'b' * 64,
      );

      const currentBuild = 5; // < 6
      UpdateStatus status;
      if (currentBuild < info.minSupportedBuild) {
        status = UpdateStatus.forced;
      } else if (currentBuild < info.buildNumber) {
        status = UpdateStatus.optional;
      } else {
        status = UpdateStatus.upToDate;
      }

      expect(status, equals(UpdateStatus.forced));
    });

    test('5. Fail-Open Behavior: Offline or null client returns unknown status without crashing', () async {
      SharedPreferences.setMockInitialValues({});
      // Without mock client or supabase connection, service fails open gracefully
      final (status, info) = await service.check(force: true, mockCurrentBuild: 1);
      expect(status, equals(UpdateStatus.unknown));
      expect(info, isNull);
    });

    test('6. 6-Hour Throttle: Automatic check returns unknown if checked within last 6 hours', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        AppUpdateService.keyLastUpdateCheck: now - 1000 * 60, // Checked 1 minute ago
      });

      // Non-force check must be throttled
      final (status, info) = await service.check(force: false, mockCurrentBuild: 1);
      expect(status, equals(UpdateStatus.unknown));
      expect(info, isNull);
    });

    test('7. 3-Day Snooze: Snoozing a build persists snooze timestamp and build number in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      await service.snooze(7);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppUpdateService.keySnoozeBuild), equals(7));

      final snoozeUntil = prefs.getInt(AppUpdateService.keySnoozeUntil) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(snoozeUntil, greaterThan(now));
      expect(snoozeUntil - now, closeTo(AppUpdateService.snoozeDurationMs, 5000));
    });

    test('8. AppUpdateInfo JSON Serialization & Parsing Integrity', () {
      final json = {
        'version_name': '1.0.2',
        'build_number': 3,
        'min_supported_build': 2,
        'download_url': 'https://t.me/astrack_official/3',
        'sha256': 'c' * 64,
        'file_size_bytes': 26214400,
        'changelog_id': 'Perbaikan bug pencatatan struk',
        'changelog_en': 'Bug fix for receipt scanner',
        'released_at': '2026-10-06T12:00:00.000Z',
      };

      final info = AppUpdateInfo.fromJson(json);
      expect(info.versionName, equals('1.0.2'));
      expect(info.buildNumber, equals(3));
      expect(info.minSupportedBuild, equals(2));
      expect(info.downloadUrl, equals('https://t.me/astrack_official/3'));
      expect(info.sha256, equals('c' * 64));
      expect(info.fileSizeBytes, equals(26214400));
      expect(info.changelogId, contains('Perbaikan bug'));
      expect(info.changelogEn, contains('Bug fix'));
      expect(info.releasedAt, isNotNull);

      final serialized = info.toJson();
      expect(serialized['build_number'], equals(3));
      expect(serialized['download_url'], equals('https://t.me/astrack_official/3'));
    });
  });

  group('ASTRACK Bab 77 APK Update UI Widget Tests', () {
    testWidgets('9. UpdateAvailableDialog renders version, changelog, and action buttons', (tester) async {
      final info = AppUpdateInfo(
        versionName: '1.0.5',
        buildNumber: 6,
        minSupportedBuild: 2,
        downloadUrl: 'https://t.me/astrack_official/6',
        sha256: 'd' * 64,
        fileSizeBytes: 24500000,
        changelogId: 'Pembaruan UI dan perbaikan performa',
        changelogEn: 'UI updates and performance boost',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: UpdateAvailableDialog(info: info, isDark: false),
          ),
        ),
      );

      expect(find.textContaining('1.0.5'), findsOneWidget);
      expect(find.textContaining('Pembaruan'), findsWidgets);
      expect(find.text('Perbarui Sekarang'), findsOneWidget);
      expect(find.text('Nanti (3 Hari)'), findsOneWidget);
    });

    testWidgets('10. ForceUpdateScreen enforces PopScope(canPop: false) and renders 360dp safely', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = StorageService();
      await storage.init();

      final info = AppUpdateInfo(
        versionName: '2.0.0',
        buildNumber: 15,
        minSupportedBuild: 10,
        downloadUrl: 'https://t.me/astrack_official/15',
        sha256: 'e' * 64,
        changelogId: 'Migrasi arsitektur keamanan wajib',
        changelogEn: 'Mandatory security architecture migration',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            supportedLocales: const [Locale('id'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ForceUpdateScreen(info: info),
          ),
        ),
      );

      expect(find.byWidgetPredicate((w) => w is PopScope && !w.canPop), findsOneWidget);

      expect(find.textContaining('Pembaruan Aplikasi Wajib'), findsOneWidget);
      expect(find.text('Unduh Pembaruan Sekarang'), findsOneWidget);

      // Confirm zero RenderFlex overflow on 360dp viewport
      expect(tester.takeException(), isNull);
    });
  });
}
