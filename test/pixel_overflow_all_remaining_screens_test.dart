import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:astrack/services/saas_backend_service.dart';
import 'package:astrack/services/payment/payment_gateway_config_service.dart';
import 'package:astrack/services/payment/manual_qris_service.dart';
import 'package:astrack/features/subscription/subscription_screen.dart';
import 'package:astrack/features/reports/reports_screen.dart';
import 'package:astrack/features/ai/ai_chat_screen.dart';
import 'package:astrack/features/profile/profile_screen.dart';
import 'package:astrack/features/settings/settings_screen.dart';
import 'package:astrack/features/admin/admin_dashboard_screen.dart';
import 'package:astrack/features/admin/admin_users_screen.dart';
import 'package:astrack/features/admin/admin_app_versions_screen.dart';
import 'package:astrack/features/onboarding/welcome_screen.dart';
import 'package:astrack/features/onboarding/onboarding_screen.dart';
import 'package:astrack/features/auth/pin_lock_screen.dart';
import 'package:astrack/features/auth/setup_sources_screen.dart';
import 'package:astrack/features/auth/user_customization_screen.dart';
import 'package:astrack/features/update/screens/force_update_screen.dart';
import 'package:astrack/features/update/models/app_update_info.dart';

import 'package:intl/date_symbol_data_local.dart';

Widget createAuditHarness({
  required Widget child,
  required ThemeProvider themeProvider,
  required FinanceProvider financeProvider,
  Size size = const Size(320, 568),
  double textScale = 1.0,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<FinanceProvider>.value(value: financeProvider),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late ThemeProvider themeProvider;
  late FinanceProvider financeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
    storage = StorageService();
    await storage.init();
    themeProvider = ThemeProvider(storage);
    financeProvider = FinanceProvider(storage);

    PaymentGatewayConfigService().resetInMemoryState();
    ManualQrisService().resetInMemoryState();
    SaaSBackendService().resetInMemoryState();
  });

  group('ASTRACK Pixel Overflow Test on All Remaining Screens', () {
    testWidgets('SubscriptionScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const SubscriptionScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final err = tester.takeException();
      if (err != null) {
        expect(err.toString(), isNot(contains('overflowed')));
      }
    });

    testWidgets('ReportsScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const ReportsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('AIChatScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const AIChatScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const ProfileScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const SettingsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      final err = tester.takeException();
      if (err != null) {
        expect(err.toString(), isNot(contains('overflowed')));
      }
    });

    testWidgets('AdminDashboardScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const AdminDashboardScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminUsersScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const AdminUsersScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminAppVersionsScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const AdminAppVersionsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('WelcomeScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const WelcomeScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('OnboardingScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const OnboardingScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('PinLockScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const PinLockScreen(mode: PinMode.create),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('SetupSourcesScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const SetupSourcesScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('UserCustomizationScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(createAuditHarness(
        child: const UserCustomizationScreen(userName: 'Tester'),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ForceUpdateScreen renders on 320x568 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      const updateInfo = AppUpdateInfo(
        versionName: '2.0.0',
        buildNumber: 200,
        minSupportedBuild: 200,
        downloadUrl: 'https://astrack.id/app.apk',
        sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        changelogId: 'Pembaruan besar versi 2.0.0',
      );
      await tester.pumpWidget(createAuditHarness(
        child: const ForceUpdateScreen(info: updateInfo),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
