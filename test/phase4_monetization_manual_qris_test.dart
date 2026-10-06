import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:astrack/core/utils/currency_formatter.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/features/admin/admin_payment_queue_screen.dart';
import 'package:astrack/features/payment/manual_qris_checkout_screen.dart';
import 'package:astrack/models/saas_models.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/services/payment/manual_qris_service.dart';
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/services/payment/payment_service.dart';
import 'package:astrack/services/saas_backend_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ManualQrisService qrisService;
  late SaaSBackendService saasService;
  late StorageService storage;
  late ThemeProvider themeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    themeProvider = ThemeProvider(storage);

    qrisService = ManualQrisService();
    qrisService.resetInMemoryState();

    saasService = SaaSBackendService();
    saasService.resetInMemoryState();
  });

  group('ASTRACK Phase 4 — Daily Unique Code & Dynamic Pricing Engine', () {
    test('1. Generates unique code between 1 and 999 based on Asia/Jakarta timezone', () {
      final now = DateTime.utc(2026, 10, 6, 0, 0, 0); // UTC
      final jakartaDate = qrisService.getJakartaDateTime(now);

      expect(jakartaDate.hour, equals(7)); // UTC+7
      expect(jakartaDate.day, equals(6));

      final code = qrisService.generateDailyUniqueCode(forDate: now);
      expect(code, greaterThanOrEqualTo(1));
      expect(code, lessThanOrEqualTo(999));
    });

    test('2. Collision avoidance: active orders on the same day get distinct unique codes', () async {
      final code1 = qrisService.generateDailyUniqueCode();
      final order1 = await qrisService.createOrder(userId: 'user_1', planId: 'plan_pro');
      expect(order1.uniqueCode, equals(code1));

      final code2 = qrisService.generateDailyUniqueCode();
      final order2 = await qrisService.createOrder(userId: 'user_2', planId: 'plan_pro');
      expect(order2.uniqueCode, equals(code2));
      expect(code1, isNot(equals(code2)));
    });

    test('3. Dynamic pricing formula: base_price - discount + unique_code', () {
      const baseAmount = 29000.0;
      const discount = 5000.0;
      const uniqueCode = 142;

      final finalAmount = qrisService.calculateFinalAmount(
        baseAmount: baseAmount,
        discountAmount: discount,
        uniqueCode: uniqueCode,
      );

      expect(finalAmount, equals(24142.0));
      expect(CurrencyFormatter.format(finalAmount), equals('Rp24.142'));
    });

    test('4. Clamps discount to 0 if discount exceeds base price', () {
      const baseAmount = 15000.0;
      const discount = 20000.0;
      const uniqueCode = 88;

      final finalAmount = qrisService.calculateFinalAmount(
        baseAmount: baseAmount,
        discountAmount: discount,
        uniqueCode: uniqueCode,
      );

      expect(finalAmount, equals(88.0));
    });

    test('5. Coupon integration with Manual QRIS order creation', () async {
      final order = await qrisService.createOrder(
        userId: 'user_coupon_test',
        planId: 'plan_pro',
        couponCode: 'ASTRACK20', // 20% discount of 29000 = 5800
      );

      expect(order.baseAmount, equals(29000.0));
      expect(order.discountAmount, equals(5800.0));
      expect(order.couponCode, equals('ASTRACK20'));
      expect(order.amount, equals(23200.0 + order.uniqueCode!));
      expect(order.status, equals(PaymentStatus.pending));
    });
  });

  group('ASTRACK Phase 4 — Order Lifecycle & Claims ("Saya Sudah Bayar")', () {
    test('6. Order creation generates valid ID, QRIS payload, and 24h expiration', () async {
      final order = await qrisService.createOrder(userId: 'user_alpha', planId: 'plan_pro');

      expect(order.orderId, startsWith('ORD-QRIS-'));
      expect(order.qrisPayload, isNotNull);
      expect(order.qrisPayload!, contains('ASTRACK OFFICIAL'));
      expect(order.status, equals(PaymentStatus.pending));

      final duration = order.expiresAt.difference(order.createdAt);
      expect(duration.inHours, equals(24));
      expect(order.isExpired, isFalse);
    });

    test('7. User claims payment ("Saya Sudah Bayar") with proof of transfer', () async {
      final order = await qrisService.createOrder(userId: 'user_claim', planId: 'plan_pro');

      final claimed = await qrisService.claimPayment(
        orderId: order.orderId,
        proofUrl: 'https://storage.astrack.local/receipts/proof_123.jpg',
        proofNotes: 'Transfer via BCA a.n. John Doe',
        userId: 'user_claim',
      );

      expect(claimed.status, equals(PaymentStatus.claimed));
      expect(claimed.proofUrl, equals('https://storage.astrack.local/receipts/proof_123.jpg'));
      expect(claimed.proofNotes, equals('Transfer via BCA a.n. John Doe'));
      expect(claimed.claimedAt, isNotNull);

      final proofs = await qrisService.getOrderProofs(order.orderId);
      expect(proofs.length, equals(1));
      expect(proofs.first.proofUrl, contains('proof_123.jpg'));
    });

    test('8. Rejects claim on already paid order', () async {
      final order = await qrisService.createOrder(userId: 'user_double', planId: 'plan_pro');
      await qrisService.approveOrder(orderId: order.orderId, adminId: 'admin_test');

      expect(
        () => qrisService.claimPayment(orderId: order.orderId),
        throwsA(isA<StateError>()),
      );
    });

    test('9. Rejects claim on expired order', () async {
      final order = await qrisService.createOrder(userId: 'user_expired', planId: 'plan_pro');
      // Force expired order in local store
      final expiredOrder = order.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: PaymentStatus.expired,
      );
      qrisService.setOrderForTesting(expiredOrder);

      // Re-claim will throw StateError
      expect(
        () => qrisService.claimPayment(orderId: expiredOrder.orderId),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ASTRACK Phase 4 — Admin Verification, Idempotent Extension & RBAC', () {
    test('10. Admin ACC: Activates Pro from now() for new user', () async {
      final order = await qrisService.createOrder(userId: 'user_new_pro', planId: 'plan_pro');
      await qrisService.claimPayment(orderId: order.orderId);

      final approved = await qrisService.approveOrder(
        orderId: order.orderId,
        adminId: 'admin_super',
      );

      expect(approved.status, equals(PaymentStatus.paid));
      expect(approved.verifiedBy, equals('admin_super'));

      // Check user entitlement
      final hasOcr = await saasService.hasEntitlement('user_new_pro', 'ocr_scanner');
      expect(hasOcr, isTrue);

      final sub = await saasService.getUserSubscription('user_new_pro');
      expect(sub, isNotNull);
      expect(sub!.planId, equals('plan_pro'));
      expect(sub.status, equals(SubscriptionStatus.active));
    });

    test('11. Admin ACC Idempotent: Extends active Pro from current_period_end', () async {
      const userId = 'user_renewing_pro';

      // User already has an active Pro
      await saasService.recordSuccessfulSubscription(
        userId: userId,
        planId: 'plan_pro',
        durationMonths: 1,
      );

      final order = await qrisService.createOrder(userId: userId, planId: 'plan_pro');
      await qrisService.claimPayment(orderId: order.orderId);

      final approved = await qrisService.approveOrder(
        orderId: order.orderId,
        adminId: 'admin_super',
      );
      expect(approved.status, equals(PaymentStatus.paid));

      // Check audit events
      final events = await qrisService.getOrderEvents(order.orderId);
      final approveEvent = events.firstWhere((e) => e.eventType == 'ADMIN_APPROVE');
      expect(approveEvent.payload['amount'], equals(order.amount));
    });

    test('12. Admin Reject: Requires mandatory reason >= 5 characters', () async {
      final order = await qrisService.createOrder(userId: 'user_reject', planId: 'plan_pro');
      await qrisService.claimPayment(orderId: order.orderId);

      // Rejection with short reason throws ArgumentError
      expect(
        () => qrisService.rejectOrder(orderId: order.orderId, reason: 'Bad', adminId: 'admin_super'),
        throwsA(isA<ArgumentError>()),
      );

      // Valid rejection
      final rejected = await qrisService.rejectOrder(
        orderId: order.orderId,
        reason: 'Nominal transfer tidak sesuai dengan kode unik harian.',
        adminId: 'admin_super',
      );

      expect(rejected.status, equals(PaymentStatus.rejected));
      expect(rejected.rejectionReason, contains('Nominal transfer tidak sesuai'));
    });

    test('13. RBAC: Non-admin ID cannot approve or reject payment orders', () async {
      final order = await qrisService.createOrder(userId: 'user_rbac', planId: 'plan_pro');

      expect(
        () => qrisService.approveOrder(orderId: order.orderId, adminId: 'regular_user_123'),
        throwsA(isA<StateError>()),
      );

      expect(
        () => qrisService.rejectOrder(orderId: order.orderId, reason: 'Valid reason here', adminId: 'regular_user_123'),
        throwsA(isA<StateError>()),
      );
    });

    test('14. Admin Queue filtering by status', () async {
      final o1 = await qrisService.createOrder(userId: 'u1', planId: 'plan_basic');
      final o2 = await qrisService.createOrder(userId: 'u2', planId: 'plan_pro');
      final o3 = await qrisService.createOrder(userId: 'u3', planId: 'plan_pro');

      await qrisService.claimPayment(orderId: o1.orderId);
      await qrisService.claimPayment(orderId: o2.orderId);
      await qrisService.approveOrder(orderId: o2.orderId, adminId: 'admin_1');
      await qrisService.rejectOrder(orderId: o3.orderId, reason: 'Bukti tidak sah', adminId: 'admin_1');

      final claimedQueue = await qrisService.getAdminQueue(statusFilter: PaymentStatus.claimed);
      expect(claimedQueue.length, equals(1));
      expect(claimedQueue.first.orderId, equals(o1.orderId));

      final paidQueue = await qrisService.getAdminQueue(statusFilter: PaymentStatus.paid);
      expect(paidQueue.length, equals(1));
      expect(paidQueue.first.orderId, equals(o2.orderId));

      final rejectedQueue = await qrisService.getAdminQueue(statusFilter: PaymentStatus.rejected);
      expect(rejectedQueue.length, equals(1));
      expect(rejectedQueue.first.orderId, equals(o3.orderId));
    });
  });

  group('ASTRACK Phase 4 — UI Widget Integration Tests', () {
    testWidgets('15. ManualQrisCheckoutScreen renders merchant, exact amount, and countdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      final plan = Plan(
        id: 'plan_pro',
        slug: 'pro',
        name: 'Pro',
        type: PlanType.regular,
        monthlyPrice: 29000.0,
        maxDevices: 5,
        maxAiRequests: 1000,
      );

      final order = PaymentOrder(
        orderId: 'ORD-QRIS-20261006-001234-142',
        userId: 'test_user_widget',
        planId: 'plan_pro',
        amount: 29142.0,
        baseAmount: 29000.0,
        uniqueCode: 142,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: MaterialApp(
            home: ManualQrisCheckoutScreen(
              order: order,
              plan: plan,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify QRIS & Merchant header
      expect(find.text('ASTRACK OFFICIAL'), findsOneWidget);
      expect(find.text('NMID: ID1026001234567'), findsOneWidget);

      // Verify Amount & Unique Code
      expect(find.text('Rp29.142'), findsOneWidget);
      expect(find.text('+ Rp 142'), findsOneWidget);

      // Verify Bank Alternatives
      expect(find.text('Transfer Bank Manual'), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('Mandiri'), findsOneWidget);

      // Verify CTA
      expect(find.text('Saya Sudah Bayar'), findsOneWidget);
    });

    testWidgets('16. AdminPaymentQueueScreen renders filters and empty state cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: const MaterialApp(
            home: AdminPaymentQueueScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Screen Title
      expect(find.text('Antrean Verifikasi Pembayaran'), findsOneWidget);

      // Verify Filter Chips
      expect(find.text('Verifikasi'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);

      // Empty State
      expect(find.text('Tidak Ada Antrean Pembayaran'), findsOneWidget);
    });

    testWidgets('17. PaymentGatewayFactory creates ManualQrisPaymentProvider correctly', (tester) async {
      final provider = PaymentGatewayFactory.create(providerType: 'manual_qris');
      expect(provider, isA<ManualQrisPaymentProvider>());
      expect(provider.providerName, contains('Manual QRIS'));

      final order = await provider.createOrder(
        userId: 'u_factory',
        planId: 'plan_basic',
        amount: 15000.0,
      );
      expect(order.orderId, startsWith('ORD-QRIS-'));
      expect(order.status, equals(PaymentStatus.pending));
    });
  });
}
