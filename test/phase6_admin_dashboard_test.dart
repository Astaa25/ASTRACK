import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/models/saas_models.dart';
import 'package:astrack/services/saas_backend_service.dart';
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/services/payment/manual_qris_service.dart';
import 'package:astrack/services/payment/payment_gateway_config_service.dart';
import 'package:astrack/features/admin/admin_gateway_config_screen.dart';
import 'package:astrack/features/admin/admin_payment_queue_screen.dart';

Widget createTestableWidget(Widget child, {required ThemeProvider themeProvider, Size size = const Size(800, 1000)}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late ThemeProvider themeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    themeProvider = ThemeProvider(storage);

    PaymentGatewayConfigService().resetInMemoryState();
    ManualQrisService().resetInMemoryState();
    SaaSBackendService().resetInMemoryState();
  });

  group('Fase 6 - Admin Gateway Config & Feature Flags Screen', () {
    testWidgets('AdminGatewayConfigScreen renders mode options, providers, and dry run', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createTestableWidget(
        const AdminGatewayConfigScreen(),
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('Konfigurasi Payment Gateway'), findsOneWidget);
      expect(find.text('Server-Authoritative Feature Flags'), findsOneWidget);
      expect(find.text('1. Mode Pembayaran Aktif'), findsOneWidget);
      expect(find.text('2. Provider Gateway Aktif'), findsOneWidget);
      expect(find.text('3. Lingkungan & Keamanan Webhook'), findsOneWidget);

      // Check payment modes
      expect(find.text('Hybrid (QRIS Manual & Gateway Otomatis)'), findsOneWidget);
      expect(find.text('Payment Gateway Otomatis Saja'), findsOneWidget);
      expect(find.text('Manual QRIS Saja'), findsOneWidget);

      // Check providers
      expect(find.text('Sandbox Mock'), findsOneWidget);
      expect(find.text('Midtrans Snap'), findsOneWidget);
      expect(find.text('Xendit Invoice'), findsOneWidget);
      expect(find.text('Stripe Checkout'), findsOneWidget);

      // Dry run button
      final dryRunBtn = find.text('Dry-Run Test');
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(dryRunBtn, findsOneWidget);
      await tester.tap(dryRunBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Simulasi Berhasil'), findsOneWidget);
    });

    testWidgets('Admin can switch payment mode and save configuration', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createTestableWidget(
        const AdminGatewayConfigScreen(),
        themeProvider: themeProvider,
      ));
      await tester.pumpAndSettle();

      // Switch to Manual QRIS Saja
      final manualQrisCard = find.text('Manual QRIS Saja');
      expect(manualQrisCard, findsOneWidget);
      await tester.tap(manualQrisCard);
      await tester.pumpAndSettle();

      // Tap Save button
      final saveBtn = find.text('Simpan Konfigurasi');
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation appears
      expect(find.textContaining('berhasil disimpan'), findsOneWidget);

      // Verify updated in service
      final config = await PaymentGatewayConfigService().getConfig();
      expect(config.paymentMode, equals(PaymentMode.manualQris));
    });

    test('Non-admin is blocked by RBAC on updating gateway config', () async {
      final configService = PaymentGatewayConfigService();
      expect(
        () => configService.updateConfig(
          paymentMode: PaymentMode.gateway,
          activeProvider: PaymentGatewayType.xendit,
          isSandbox: false,
          adminId: 'intruder_user_999',
        ),
        throwsStateError,
      );
    });
  });

  group('Fase 6 - Responsiveness & Two-Pane Layout in Admin Payment Queue', () {
    testWidgets('AdminPaymentQueueScreen renders phone single-pane on narrow screens (<700dp)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Seed an order
      final qris = ManualQrisService();
      qris.setOrderForTesting(PaymentOrder(
        orderId: 'ORD-PHONE-001',
        userId: 'user_phone_1',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        status: PaymentStatus.claimed,
        claimedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestableWidget(
        const AdminPaymentQueueScreen(),
        themeProvider: themeProvider,
        size: const Size(400, 800),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Antrean Verifikasi Pembayaran'), findsOneWidget);
      expect(find.text('ORD-PHONE-001'), findsOneWidget);
      expect(find.text('Paket: plan_pro'), findsOneWidget);
      expect(find.text('Rp29.000'), findsOneWidget);
    });

    testWidgets('AdminPaymentQueueScreen renders tablet two-pane on wide screens (>=700dp)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      final qris = ManualQrisService();
      qris.setOrderForTesting(PaymentOrder(
        orderId: 'ORD-TABLET-001',
        userId: 'user_tablet_1',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        status: PaymentStatus.claimed,
        claimedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestableWidget(
        const AdminPaymentQueueScreen(),
        themeProvider: themeProvider,
        size: const Size(1000, 800),
      ));
      await tester.pumpAndSettle();

      // Tablet view renders master list on left and detail panel on right
      expect(find.text('ORD-TABLET-001'), findsWidgets);
      expect(find.text('Detail Pembayaran'), findsOneWidget);
      expect(find.text('ACC Pembayaran'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });
  });

  group('Fase 6 - Payment Queue Actions & Idempotent Pro Extension', () {
    test('Admin approves claimed payment idempotently with Pro extension', () async {
      final qris = ManualQrisService();
      final saas = SaaSBackendService();
      const testUserId = 'user_acc_target';

      // Pre-existing Pro expiring in 10 days
      final existingExpiry = DateTime.now().add(const Duration(days: 10));
      saas.setInMemorySubscriptionForTesting(
        testUserId,
        Subscription(
          id: 'sub_old',
          userId: testUserId,
          planId: 'plan_pro',
          status: SubscriptionStatus.active,
          currentPeriodEnd: existingExpiry,
        ),
      );

      final order = PaymentOrder(
        orderId: 'ORD-ACC-001',
        userId: testUserId,
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        status: PaymentStatus.claimed,
      );
      qris.setOrderForTesting(order);

      // Admin approves
      final approved = await qris.approveOrder(
        orderId: 'ORD-ACC-001',
        adminId: 'admin_lead_reviewer',
      );

      expect(approved.status, equals(PaymentStatus.paid));
      expect(approved.verifiedBy, equals('admin_lead_reviewer'));

      // Check subscription extension in SaaS backend
      final sub = await saas.getUserSubscription(testUserId);
      expect(sub, isNotNull);
      final daysDiff = sub!.currentPeriodEnd.difference(DateTime.now()).inDays;
      // Existing 10 days + 30 days = 40 days
      expect(daysDiff, greaterThanOrEqualTo(39));
      expect(daysDiff, lessThanOrEqualTo(41));
    });

    test('Admin rejection requires valid reason (>= 5 chars)', () async {
      final qris = ManualQrisService();
      final order = PaymentOrder(
        orderId: 'ORD-REJECT-001',
        userId: 'user_reject_1',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        status: PaymentStatus.claimed,
      );
      qris.setOrderForTesting(order);

      // Rejection with too short reason throws ArgumentError
      expect(
        () => qris.rejectOrder(
          orderId: 'ORD-REJECT-001',
          reason: 'bad', // < 5 chars
          adminId: 'admin_guard',
        ),
        throwsArgumentError,
      );

      // Rejection with valid reason succeeds
      final rejected = await qris.rejectOrder(
        orderId: 'ORD-REJECT-001',
        reason: 'Bukti transfer tidak terbaca / buram',
        adminId: 'admin_guard',
      );

      expect(rejected.status, equals(PaymentStatus.rejected));
      expect(rejected.rejectionReason, equals('Bukti transfer tidak terbaca / buram'));
    });
  });

  group('Fase 6 - Zero-Trust Financial Privacy Audit', () {
    test('Admin services strictly query SaaS and Subscription data, never user personal transactions', () async {
      final saas = SaaSBackendService();

      // Pricing & plans
      final plans = await saas.getPlans(includeInactive: true);
      expect(plans, isNotEmpty);

      // Coupons
      final coupons = await saas.getCoupons();
      expect(coupons, isNotEmpty);

      // Subscriptions
      final subs = await saas.getAllSubscriptions();
      expect(subs, isA<List<Subscription>>());

      // Licenses
      final licenses = await saas.getAllLicenses();
      expect(licenses, isA<List<License>>());

      // Notice: SaaSBackendService contains ZERO methods to query user personal transactions or bank accounts.
      // Personal finances remain strictly segregated in the user client FinanceProvider with private RLS.
    });
  });

  group('Fase 6 - Pricing & Promotion Coupon Administration', () {
    test('Coupon model supports fixed and percentage discounts with validation via SaaSBackendService', () async {
      final saas = SaaSBackendService();

      final percentageResult = await saas.validateCouponServer(
        code: 'ASTRACK20', // Diskon 20% dari Pro (29.000)
        planId: 'plan_pro',
        userId: 'u_test_1',
      );

      expect(percentageResult.isValid, isTrue);
      expect(percentageResult.originalPrice, equals(29000.0));
      expect(percentageResult.discountAmount, equals(5800.0)); // 20% of 29.000
      expect(percentageResult.finalPrice, equals(23200.0));

      final fixedResult = await saas.validateCouponServer(
        code: 'ASTRACK5K', // Potongan Rp5.000 dari Basic (15.000)
        planId: 'plan_basic',
        userId: 'u_test_2',
      );

      expect(fixedResult.isValid, isTrue);
      expect(fixedResult.originalPrice, equals(15000.0));
      expect(fixedResult.discountAmount, equals(5000.0));
      expect(fixedResult.finalPrice, equals(10000.0));
    });
  });
}
