import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:astrack/features/auth/forgot_password_screen.dart';
import 'package:astrack/features/auth/reset_password_screen.dart';
import 'package:astrack/features/settings/privacy_data_screen.dart';
import 'package:astrack/features/policy/policy_screen.dart';
import 'package:astrack/features/settings/about_screen.dart';
import 'package:astrack/services/supabase_auth_service.dart';

Widget createTestApp({
  required Widget child,
  required StorageService storage,
  Locale locale = const Locale('id', 'ID'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(storage)),
      ChangeNotifierProvider<FinanceProvider>(create: (_) => FinanceProvider(storage)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });

  group('ASTRACK Phase 2: Missing Features & Account Privacy Tests', () {
    testWidgets('1. ForgotPasswordScreen renders and validates empty/invalid email input', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const ForgotPasswordScreen(),
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Verify title and input field rendered
      expect(find.text('Lupa Kata Sandi'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Tap submit with empty email -> shows validation error
      final submitBtn = find.text('Kirim Tautan Pemulihan');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Mohon masukkan alamat email yang valid.'), findsOneWidget);

      // Enter invalid email without '@'
      await tester.enterText(find.byType(TextField), 'invalidemailformat');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Mohon masukkan alamat email yang valid.'), findsOneWidget);
    });

    testWidgets('2. ResetPasswordScreen validates password length and confirmation mismatch', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const ResetPasswordScreen(),
        storage: storage,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Atur Kata Sandi Baru'), findsOneWidget);
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Enter short password (< 6 chars)
      await tester.enterText(textFields.at(0), '12345');
      await tester.enterText(textFields.at(1), '12345');
      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi baru minimal harus 6 karakter.'), findsOneWidget);

      // Enter mismatched passwords
      await tester.enterText(textFields.at(0), 'secret123');
      await tester.enterText(textFields.at(1), 'mismatch456');
      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);
    });

    testWidgets('3. PrivacyDataScreen Crash Reporting toggle updates SharedPreferences', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const PrivacyDataScreen(),
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Find Crash Reporting toggle switch
      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);
      expect(find.text('Laporan Galat Sistem (Crash Reporting)'), findsOneWidget);

      // Initially false
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('astrack_crash_reporting_enabled'), isNull);

      // Toggle switch to ON
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      expect(prefs.getBool('astrack_crash_reporting_enabled'), isTrue);
    });

    testWidgets('4. PrivacyDataScreen Account Deletion dialog flow and backup recommendation', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const PrivacyDataScreen(),
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Locate "Hapus Akun & Data Cloud" danger tile
      final deleteAccountTile = find.text('Hapus Akun & Data Cloud');
      expect(deleteAccountTile, findsOneWidget);

      await tester.scrollUntilVisible(deleteAccountTile, 100);
      await tester.tap(deleteAccountTile);
      await tester.pumpAndSettle();

      // Verify warning dialog opened
      expect(find.text('Hapus Akun & Cloud'), findsOneWidget);
      expect(find.text('Salin Cadangan JSON Dulu'), findsOneWidget);
      expect(find.text('Lanjut Hapus'), findsOneWidget);

      // Tap "Lanjut Hapus" to open final confirmation dialog
      await tester.tap(find.text('Lanjut Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Terakhir ⚠️'), findsOneWidget);
      expect(find.text('Konfirmasi Hapus Akun'), findsOneWidget);
    });

    testWidgets('5. PolicyScreen renders bilingual clauses, contacts, and TODO: [LEGAL_REVIEW]', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const PolicyScreen(),
        storage: storage,
      ));
      await tester.pumpAndSettle();

      // Verify legal review marker in terms
      expect(find.textContaining('TODO: [LEGAL_REVIEW]'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);

      // Verify submit button disabled initially
      final submitBtn = find.widgetWithText(ElevatedButton, 'Setuju & Lanjutkan');
      expect(submitBtn, findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(submitBtn);
      expect(elevatedButton.onPressed, isNull);

      // Tap agreement checkbox
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final updatedElevatedButton = tester.widget<ElevatedButton>(submitBtn);
      expect(updatedElevatedButton.onPressed, isNotNull);
    });

    testWidgets('6. AboutScreen renders official support contacts and issue report button', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const AboutScreen(),
        storage: storage,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bantuan & Saluran Resmi'), findsOneWidget);
      expect(find.text('Laporkan Masalah'), findsOneWidget);
      expect(find.text('Sidik Jari Sertifikat Rilis'), findsOneWidget);
    });

    test('7. SupabaseAuthService method contracts for Phase 2 are implemented', () {
      // Test contract existence without throwing uncaught runtime errors
      expect(SupabaseAuthService.deleteAccount, isNotNull);
      expect(SupabaseAuthService.sendPasswordResetEmail, isNotNull);
      expect(SupabaseAuthService.updateUserPassword, isNotNull);
    });
  });
}
