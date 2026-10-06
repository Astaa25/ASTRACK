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
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/models/saas_models.dart';
import 'package:astrack/features/auth/forgot_password_screen.dart';
import 'package:astrack/features/auth/reset_password_screen.dart';
import 'package:astrack/features/policy/policy_screen.dart';
import 'package:astrack/features/settings/privacy_data_screen.dart';
import 'package:astrack/features/settings/appearance_screen.dart';
import 'package:astrack/features/payment/manual_qris_checkout_screen.dart';
import 'package:astrack/features/admin/admin_payment_queue_screen.dart';
import 'package:astrack/features/update/widgets/update_available_dialog.dart';
import 'package:astrack/features/update/models/app_update_info.dart';
import 'package:astrack/features/auth/login_screen.dart';
import 'package:astrack/features/auth/register_screen.dart';
import 'package:astrack/features/dashboard/dashboard_screen.dart';
import 'package:astrack/features/statistics/statistics_screen.dart';
import 'package:astrack/features/admin/admin_statistics_screen.dart';
import 'package:astrack/features/admin/admin_gateway_config_screen.dart';
import 'package:astrack/features/admin/admin_coupons_screen.dart';
import 'package:astrack/features/admin/admin_pricing_screen.dart';
import 'package:astrack/features/admin/admin_settings_screen.dart';
import 'package:astrack/features/scanner/receipt_scanner_screen.dart';
import 'package:astrack/features/budget/budget_screen.dart';
import 'package:astrack/features/savings/savings_screen.dart';
import 'package:astrack/features/recurring/recurring_screen.dart';
import 'package:astrack/features/transactions/transactions_screen.dart';
import 'package:astrack/features/sources/sources_screen.dart';
import 'package:astrack/features/transactions/csv_import_screen.dart';
import 'package:astrack/features/settings/about_screen.dart';
import 'package:astrack/features/settings/language_settings_screen.dart';
import 'package:astrack/features/settings/manage_categories_screen.dart';

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
    storage = StorageService();
    await storage.init();
    themeProvider = ThemeProvider(storage);
    financeProvider = FinanceProvider(storage);

    PaymentGatewayConfigService().resetInMemoryState();
    ManualQrisService().resetInMemoryState();
    SaaSBackendService().resetInMemoryState();
  });

  group('ASTRACK Comprehensive Pixel Overflow Audit (320dp & 360dp Hardening)', () {
    testWidgets('ForgotPasswordScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const ForgotPasswordScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ResetPasswordScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const ResetPasswordScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('PolicyScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const PolicyScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AppearanceScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AppearanceScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('PrivacyDataScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const PrivacyDataScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminPaymentQueueScreen renders cleanly on 320x568 narrow screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AdminPaymentQueueScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('UpdateAvailableDialog renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      const info = AppUpdateInfo(
        versionName: '1.2.0',
        buildNumber: 12,
        minSupportedBuild: 1,
        changelogEn: 'Performance updates and bugfixes',
        changelogId: 'Peningkatan performa dan perbaikan bug sistem.',
        downloadUrl: 'https://example.com/astrack.apk',
        fileSizeBytes: 28500000,
        sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      await tester.pumpWidget(createAuditHarness(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateAvailableDialog.show(context, info: info, isDark: false),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ASTRACK v1.2.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ManualQrisCheckoutScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final testOrder = PaymentOrder(
        orderId: 'ORD-AUDIT-320',
        userId: 'user-audit-1',
        planId: 'plan_pro',
        amount: 29845,
        baseAmount: 29000,
        uniqueCode: 845,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final testPlan = Plan(
        id: 'plan_pro',
        slug: 'pro',
        name: 'Paket Pro',
        description: 'Akses penuh seluruh fitur ASTRACK',
        type: PlanType.regular,
        monthlyPrice: 29000,
        maxDevices: 5,
        maxAiRequests: 100,
        features: ['AI Scanner', 'Multi-Wallet', 'Cloud Sync'],
      );

      await tester.pumpWidget(createAuditHarness(
        child: ManualQrisCheckoutScreen(order: testOrder, plan: testPlan),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const LoginScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const RegisterScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      FlutterErrorDetails? overflowDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.summary.toString().contains('overflowed by')) {
          overflowDetails = details;
        }
      };

      await tester.pumpWidget(createAuditHarness(
        child: const DashboardScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;
      expect(overflowDetails, isNull, reason: 'Pixel overflow detected on DashboardScreen');
    });

    testWidgets('StatisticsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const StatisticsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminStatisticsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AdminStatisticsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminGatewayConfigScreen renders cleanly on 360x640 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));

      await tester.pumpWidget(createAuditHarness(
        child: const AdminGatewayConfigScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminCouponsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AdminCouponsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminPricingScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AdminPricingScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminSettingsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AdminSettingsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ReceiptScannerScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const ReceiptScannerScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('BudgetScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const BudgetScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('SavingsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const SavingsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RecurringScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const RecurringScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TransactionsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const TransactionsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('SourcesScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const SourcesScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('CsvImportScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const CsvImportScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AboutScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const AboutScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('LanguageSettingsScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const LanguageSettingsScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ManageCategoriesScreen renders cleanly on 320x568 compact screen without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(createAuditHarness(
        child: const ManageCategoriesScreen(),
        themeProvider: themeProvider,
        financeProvider: financeProvider,
        size: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
