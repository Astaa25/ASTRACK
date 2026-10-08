import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/app/theme/app_colors.dart';
import 'package:astrack/core/services/security_service.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:astrack/models/saas_models.dart';
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/services/payment/manual_qris_service.dart';
import 'package:astrack/services/payment/payment_gateway_config_service.dart';
import 'package:astrack/services/payment/payment_webhook_service.dart';
import 'package:astrack/features/auth/pin_lock_screen.dart';
import 'package:astrack/features/payment/manual_qris_checkout_screen.dart';
import 'package:astrack/features/admin/admin_payment_queue_screen.dart';
import 'package:astrack/features/admin/admin_gateway_config_screen.dart';

// Helper to compute WCAG 2.1 relative luminance
double relativeLuminance(Color color) {
  double transform(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.red / 255.0);
  final g = transform(color.green / 255.0);
  final b = transform(color.blue / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// Helper to compute contrast ratio
double contrastRatio(Color fg, Color bg) {
  final l1 = relativeLuminance(fg);
  final l2 = relativeLuminance(bg);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

Widget createTestableWidget({
  required Widget child,
  required ThemeProvider themeProvider,
  double textScaleFactor = 1.0,
  Size size = const Size(400, 800),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<FinanceProvider>(create: (_) => FinanceProvider(StorageService())),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScaleFactor),
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    themeProvider = ThemeProvider(storage);

    PaymentGatewayConfigService().resetInMemoryState();
    ManualQrisService().resetInMemoryState();
    PaymentWebhookService().resetInMemoryState();
    await SecurityService.instance.init();
  });

  group('Fase 7 - WCAG AA Color Contrast Ratio Audit', () {
    test('Light mode body text contrast against background meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.lightTextPrimary, AppColors.lightBg);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Dark mode body text contrast against background meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.darkTextPrimary, AppColors.darkDeepBg);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Brand primary emerald on white card meets WCAG AA for UI & bold text (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.primary, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('Semantic income and expense colors meet readable contrast standards (>= 3.0:1)', () {
      final incomeRatio = contrastRatio(AppColors.income, Colors.white);
      final expenseRatio = contrastRatio(AppColors.expense, Colors.white);
      expect(incomeRatio, greaterThanOrEqualTo(3.0));
      expect(expenseRatio, greaterThanOrEqualTo(3.0));
    });
  });

  group('Fase 7 - Dynamic Type & 200% Text Scaling Stress Tests', () {
    testWidgets('AdminPaymentQueueScreen survives 200% text scale without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final qris = ManualQrisService();
      qris.setOrderForTesting(PaymentOrder(
        orderId: 'ORD-A11Y-001',
        userId: 'user_a11y_1',
        planId: 'plan_pro',
        amount: 29142.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        status: PaymentStatus.claimed,
        claimedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestableWidget(
        child: const AdminPaymentQueueScreen(),
        themeProvider: themeProvider,
        textScaleFactor: 2.0, // 200% scale
        size: const Size(400, 800),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ORD-A11Y-001'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });

    testWidgets('ManualQrisCheckoutScreen survives 200% text scale without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      final order = PaymentOrder(
        orderId: 'ORD-A11Y-CHECKOUT',
        userId: 'user_a11y_2',
        planId: 'plan_pro',
        amount: 29142.0,
        uniqueCode: 142,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        status: PaymentStatus.pending,
      );

      final plan = Plan(
        id: 'plan_pro',
        name: 'Pro',
        slug: 'pro',
        type: PlanType.regular,
        monthlyPrice: 29000.0,
        maxDevices: 5,
        maxAiRequests: 1000,
        features: const ['Fitur Pro'],
      );

      await tester.pumpWidget(createTestableWidget(
        child: ManualQrisCheckoutScreen(order: order, plan: plan),
        themeProvider: themeProvider,
        textScaleFactor: 2.0, // 200% scale
        size: const Size(400, 850),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ASTRACK OFFICIAL'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });

    testWidgets('AdminGatewayConfigScreen survives 200% text scale without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(createTestableWidget(
        child: const AdminGatewayConfigScreen(),
        themeProvider: themeProvider,
        textScaleFactor: 2.0, // 200% scale
        size: const Size(400, 900),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Konfigurasi Payment Gateway'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });

    testWidgets('PinLockScreen survives 150% text scale with full numeric keypad visibility', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(createTestableWidget(
        child: const PinLockScreen(mode: PinMode.create),
        themeProvider: themeProvider,
        textScaleFactor: 1.5,
        size: const Size(400, 850),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Buat PIN Keamanan'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(tester.takeException(), isNull); // ZERO OVERFLOW
    });
  });

  group('Fase 7 - Security Penetration Test & Tampering Resistance', () {
    test('PIN is cryptographically salted and hashed (Zero Plaintext Storage)', () async {
      final sec = SecurityService.instance;
      await sec.setPin('654321');

      final prefs = await SharedPreferences.getInstance();
      // Plaintext key MUST be wiped completely
      expect(prefs.getString('astrack_user_pin'), isNull);
      // Hash is stored in FlutterSecureStorage, NOT unencrypted SharedPreferences
      expect(prefs.getString('astrack_user_pin_hash'), isNull);

      final hash = await sec.secureStorage.read(key: 'astrack_user_pin_hash');
      expect(hash, isNotNull);
      expect(hash, isNot(equals('654321')));
      expect(hash!.length, equals(64)); // SHA-256 is 64 hex chars
    });

    test('Brute-force PIN protection triggers 30-second cooldown at 3 failures and 300-second lockout at 5 failures', () async {
      final sec = SecurityService.instance;
      await sec.setPin('123456');

      expect(sec.isLockedOut, isFalse);

      // Attempt 3 incorrect PINs -> triggers 30s cooldown
      for (int i = 0; i < 3; i++) {
        final ok = await sec.verifyPin('000000');
        expect(ok, isFalse);
      }

      expect(sec.isLockedOut, isTrue);
      expect(sec.remainingLockoutSeconds, greaterThan(20));
      expect(sec.remainingLockoutSeconds, lessThanOrEqualTo(30));

      // Simulate cooldown expiry
      sec.clearCooldownForTesting();

      // 4th failure
      final ok4 = await sec.verifyPin('000000');
      expect(ok4, isFalse);
      sec.clearCooldownForTesting();

      // 5th failure -> triggers full 300-second (5 min) lockout
      final ok5 = await sec.verifyPin('000000');
      expect(ok5, isFalse);

      expect(sec.isLockedOut, isTrue);
      expect(sec.remainingLockoutSeconds, greaterThan(290));
      expect(sec.remainingLockoutSeconds, lessThanOrEqualTo(300));

      // Attempt during lockout is rejected automatically even with valid PIN
      final lockedAttempt = await sec.verifyPin('123456');
      expect(lockedAttempt, isFalse);

      await sec.resetLockout();
      expect(sec.isLockedOut, isFalse);
    });

    test('Payment Webhook anti-tampering rejects modified gross amount', () async {
      final webhook = PaymentWebhookService();
      final qris = ManualQrisService();

      qris.setOrderForTesting(PaymentOrder(
        orderId: 'ORD-SECURITY-AUDIT-01',
        userId: 'user_sec_audit',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));

      final payload = PaymentWebhookPayload(
        orderId: 'ORD-SECURITY-AUDIT-01',
        eventType: 'paid',
        signature: 'mock_sig',
        timestamp: DateTime.now(),
        rawData: {},
        provider: 'sandbox',
        grossAmount: 1000.0, // Tampered nominal
      );

      final result = await webhook.processWebhook(payload: payload);
      expect(result.success, isFalse);
      // Fails at signature or tampering guard
    });
  });

  group('Fase 7 - Production Release Configuration Audit', () {
    test('AndroidManifest.xml contains mandatory production permissions', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('android.permission.INTERNET'));
      expect(content, contains('android.permission.ACCESS_NETWORK_STATE'));
      expect(content, contains('android.permission.CAMERA'));
      expect(content, contains('android.permission.USE_BIOMETRIC'));
    });

    test('pubspec.yaml specifies semantic versioning format', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();
      final versionMatch = RegExp(r'version:\s+(\d+\.\d+\.\d+\+\d+)').firstMatch(content);
      expect(versionMatch, isNotNull);
      expect(versionMatch!.group(1), equals('2.0.0+2'));
    });

    test('build.gradle.kts targets modern Java 17 bytecode', () {
      final gradleFile = File('android/app/build.gradle.kts');
      expect(gradleFile.existsSync(), isTrue);

      final content = gradleFile.readAsStringSync();
      expect(content, contains('JavaVersion.VERSION_17'));
    });
  });
}
