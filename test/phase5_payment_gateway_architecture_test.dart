import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/models/saas_models.dart';
import 'package:astrack/services/saas_backend_service.dart';
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/services/payment/payment_service.dart';
import 'package:astrack/services/payment/manual_qris_service.dart';
import 'package:astrack/services/payment/payment_gateway_config_service.dart';
import 'package:astrack/services/payment/payment_webhook_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSecret = 'test_webhook_secret_key_12345';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PaymentGatewayConfigService().resetInMemoryState();
    PaymentWebhookService().resetInMemoryState();
    ManualQrisService().resetInMemoryState();
    SaaSBackendService().resetInMemoryState();
  });

  group('Fase 5 - PaymentGatewayConfigService & Feature Flag Switching', () {
    test('Default configuration should be Hybrid mode with Sandbox provider', () async {
      final configService = PaymentGatewayConfigService();
      final config = await configService.getConfig();

      expect(config.paymentMode, equals(PaymentMode.hybrid));
      expect(config.activeProvider, equals(PaymentGatewayType.sandbox));
      expect(config.isSandbox, isTrue);
      expect(config.isManualQrisEnabled, isTrue);
      expect(config.isGatewayEnabled, isTrue);

      final activeProvider = await configService.resolveActiveProvider();
      expect(activeProvider, isA<SandboxPaymentProvider>());
    });

    test('resolveActiveProvider returns ManualQrisPaymentProvider when mode is manualQris', () async {
      final configService = PaymentGatewayConfigService();
      await configService.updateConfig(
        paymentMode: PaymentMode.manualQris,
        activeProvider: PaymentGatewayType.sandbox,
        isSandbox: true,
        adminId: 'admin_super_user',
      );

      final activeProvider = await configService.resolveActiveProvider();
      expect(activeProvider, isA<ManualQrisPaymentProvider>());
    });

    test('Admin successfully updates gateway to Midtrans and reflects dynamically', () async {
      final configService = PaymentGatewayConfigService();
      final updated = await configService.updateConfig(
        paymentMode: PaymentMode.gateway,
        activeProvider: PaymentGatewayType.midtrans,
        isSandbox: false,
        webhookSecret: 'midtrans_secret_override',
        adminId: 'admin_finance_lead',
      );

      expect(updated.paymentMode, equals(PaymentMode.gateway));
      expect(updated.activeProvider, equals(PaymentGatewayType.midtrans));
      expect(updated.isSandbox, isFalse);
      expect(updated.webhookSecret, equals('midtrans_secret_override'));

      final activeProvider = await configService.resolveActiveProvider();
      expect(activeProvider, isA<MidtransPaymentProvider>());
    });

    test('Non-admin user cannot update gateway configuration (Security RBAC)', () async {
      final configService = PaymentGatewayConfigService();
      expect(
        () => configService.updateConfig(
          paymentMode: PaymentMode.gateway,
          activeProvider: PaymentGatewayType.stripe,
          isSandbox: true,
          adminId: 'user_regular_007',
        ),
        throwsStateError,
      );
    });

    test('PaymentGatewayConfig JSON serialization and deserialization', () {
      final original = PaymentGatewayConfig(
        paymentMode: PaymentMode.gateway,
        activeProvider: PaymentGatewayType.xendit,
        isSandbox: false,
        webhookSecret: 'xen_token_abc',
        updatedAt: DateTime.utc(2026, 10, 6, 12, 0),
      );

      final json = original.toJson();
      final reconstructed = PaymentGatewayConfig.fromJson(json);

      expect(reconstructed.paymentMode, equals(PaymentMode.gateway));
      expect(reconstructed.activeProvider, equals(PaymentGatewayType.xendit));
      expect(reconstructed.isSandbox, isFalse);
      expect(reconstructed.webhookSecret, equals('xen_token_abc'));
    });
  });

  group('Fase 5 - PaymentWebhookVerifier (Multi-Gateway Cryptographic Verification)', () {
    final verifier = PaymentWebhookVerifier(webhookSecret: testSecret);

    test('Midtrans SHA-512 signature verification', () {
      const orderId = 'ORD-MIDTRANS-1001';
      const statusCode = '200';
      const grossAmount = '29000.00';

      // SHA512(order_id + status_code + gross_amount + ServerKey)
      final rawInput = '$orderId$statusCode$grossAmount$testSecret';
      final validSignature = sha512.convert(utf8.encode(rawInput)).toString();

      final isValid = verifier.verifyMidtransSha512(
        orderId: orderId,
        statusCode: statusCode,
        grossAmount: grossAmount,
        signatureKey: validSignature,
      );
      expect(isValid, isTrue);

      final isTampered = verifier.verifyMidtransSha512(
        orderId: orderId,
        statusCode: statusCode,
        grossAmount: '15000.00', // tampered amount
        signatureKey: validSignature,
      );
      expect(isTampered, isFalse);
    });

    test('Xendit callback token verification', () {
      expect(verifier.verifyXenditCallbackToken(testSecret), isTrue);
      expect(verifier.verifyXenditCallbackToken('   $testSecret   '), isTrue);
      expect(verifier.verifyXenditCallbackToken('invalid_token_xyz'), isFalse);
    });

    test('Stripe HMAC-SHA256 signature verification', () {
      const rawBody = '{"id":"evt_stripe_999","type":"payment_intent.succeeded"}';
      final nowSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      final payload = '$nowSeconds.$rawBody';
      final hmac = Hmac(sha256, utf8.encode(testSecret));
      final signature = hmac.convert(utf8.encode(payload)).toString();

      final stripeHeader = 't=$nowSeconds,v1=$signature';

      final isValid = verifier.verifyStripeSignature(
        rawBody: rawBody,
        stripeSignatureHeader: stripeHeader,
      );
      expect(isValid, isTrue);

      final isTamperedBody = verifier.verifyStripeSignature(
        rawBody: '{"tampered":true}',
        stripeSignatureHeader: stripeHeader,
      );
      expect(isTamperedBody, isFalse);
    });

    test('Sandbox HMAC-SHA256 signature verification', () {
      const rawBody = '{"order_id":"ORD-SANDBOX-001"}';
      final nowSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      final payload = '$nowSeconds.$rawBody';
      final hmac = Hmac(sha256, utf8.encode(testSecret));
      final signature = hmac.convert(utf8.encode(payload)).toString();

      final isValid = verifier.verifyHmacSha256(
        rawBody: rawBody,
        signature: signature,
        timestamp: nowSeconds,
      );
      expect(isValid, isTrue);

      final isInvalidSig = verifier.verifyHmacSha256(
        rawBody: rawBody,
        signature: 'wrong_signature_hex',
        timestamp: nowSeconds,
      );
      expect(isInvalidSig, isFalse);
    });
  });

  group('Fase 5 - Webhook Replay Protection & Anti-Tampering', () {
    test('Replay attack (> 300 seconds old) is immediately rejected', () async {
      final webhookService = PaymentWebhookService();
      final expiredTimestamp = DateTime.now().subtract(const Duration(seconds: 350));

      final payload = PaymentWebhookPayload(
        orderId: 'ORD-EXPIRED-001',
        eventType: 'settlement',
        signature: 'any_signature',
        timestamp: expiredTimestamp,
        rawData: {},
        provider: 'midtrans',
      );

      final result = await webhookService.processWebhook(payload: payload);
      expect(result.success, isFalse);
      expect(result.message, contains('Replay attack prevented'));
    });

    test('Anti-tampering alert triggers if webhook gross amount mismatches order amount', () async {
      final configService = PaymentGatewayConfigService();
      await configService.updateConfig(
        paymentMode: PaymentMode.gateway,
        activeProvider: PaymentGatewayType.sandbox,
        isSandbox: true,
        webhookSecret: testSecret,
        adminId: 'admin_root',
      );

      final qrisService = ManualQrisService();
      final order = PaymentOrder(
        orderId: 'ORD-TAMPER-01',
        userId: 'user_tamper_test',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      qrisService.setOrderForTesting(order);

      final nowSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final rawBody = '{"order_id":"ORD-TAMPER-01"}';
      final hmac = Hmac(sha256, utf8.encode(testSecret));
      final signature = hmac.convert(utf8.encode('$nowSeconds.$rawBody')).toString();

      final payload = PaymentWebhookPayload(
        orderId: 'ORD-TAMPER-01',
        eventType: 'paid',
        signature: signature,
        timestamp: DateTime.now(),
        rawData: {'order_id': 'ORD-TAMPER-01'},
        provider: 'sandbox',
        grossAmount: 10000.0, // Tampered: 10,000 instead of 29,000!
      );

      final webhookService = PaymentWebhookService();
      final result = await webhookService.processWebhook(
        payload: payload,
        rawBody: rawBody,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Anti-tampering alert'));
    });
  });

  group('Fase 5 - Webhook Auto-Activation & Idempotency Pipeline', () {
    test('End-to-end payment webhook auto-activates subscription for pending order', () async {
      final configService = PaymentGatewayConfigService();
      await configService.updateConfig(
        paymentMode: PaymentMode.gateway,
        activeProvider: PaymentGatewayType.sandbox,
        isSandbox: true,
        webhookSecret: testSecret,
        adminId: 'admin_finance',
      );

      final qrisService = ManualQrisService();
      final saasService = SaaSBackendService();

      const testUserId = 'user_auto_activate_101';
      final order = PaymentOrder(
        orderId: 'ORD-AUTO-ACTIVATE-101',
        userId: testUserId,
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        status: PaymentStatus.pending,
      );
      qrisService.setOrderForTesting(order);

      final nowSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final rawBody = '{"order_id":"ORD-AUTO-ACTIVATE-101"}';
      final hmac = Hmac(sha256, utf8.encode(testSecret));
      final signature = hmac.convert(utf8.encode('$nowSeconds.$rawBody')).toString();

      final payload = PaymentWebhookPayload(
        eventId: 'evt_unique_101',
        orderId: 'ORD-AUTO-ACTIVATE-101',
        eventType: 'settlement',
        signature: signature,
        timestamp: DateTime.now(),
        rawData: {'order_id': 'ORD-AUTO-ACTIVATE-101'},
        provider: 'sandbox',
        grossAmount: 29000.0,
      );

      final webhookService = PaymentWebhookService();
      final result = await webhookService.processWebhook(
        payload: payload,
        rawBody: rawBody,
      );

      expect(result.success, isTrue);
      expect(result.isDuplicate, isFalse);
      expect(result.subscriptionActivated, isTrue);
      expect(result.status, equals(PaymentStatus.paid));

      // Verify order status in storage
      final updatedOrder = await qrisService.getOrder('ORD-AUTO-ACTIVATE-101');
      expect(updatedOrder!.status, equals(PaymentStatus.paid));
      expect(updatedOrder.verifiedBy, equals('webhook_sandbox'));

      // Verify subscription in SaaSBackendService
      final sub = await saasService.getUserSubscription(testUserId);
      expect(sub, isNotNull);
      expect(sub!.planId, equals('plan_pro'));
      expect(sub.status, equals(SubscriptionStatus.active));
      expect(sub.currentPeriodEnd.isAfter(DateTime.now()), isTrue);
    });

    test('Duplicate webhook event ID is safely handled with Idempotency Guard', () async {
      final configService = PaymentGatewayConfigService();
      await configService.updateConfig(
        paymentMode: PaymentMode.gateway,
        activeProvider: PaymentGatewayType.sandbox,
        isSandbox: true,
        webhookSecret: testSecret,
        adminId: 'admin_finance',
      );

      final qrisService = ManualQrisService();
      const testUserId = 'user_idempotent_test';
      final order = PaymentOrder(
        orderId: 'ORD-IDEMPOTENT-001',
        userId: testUserId,
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      qrisService.setOrderForTesting(order);

      final nowSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final rawBody = '{"order_id":"ORD-IDEMPOTENT-001"}';
      final hmac = Hmac(sha256, utf8.encode(testSecret));
      final signature = hmac.convert(utf8.encode('$nowSeconds.$rawBody')).toString();

      final payload = PaymentWebhookPayload(
        eventId: 'evt_idempotent_event_999',
        orderId: 'ORD-IDEMPOTENT-001',
        eventType: 'paid',
        signature: signature,
        timestamp: DateTime.now(),
        rawData: {'order_id': 'ORD-IDEMPOTENT-001'},
        provider: 'sandbox',
        grossAmount: 29000.0,
      );

      final webhookService = PaymentWebhookService();

      // First execution
      final result1 = await webhookService.processWebhook(payload: payload, rawBody: rawBody);
      expect(result1.success, isTrue);
      expect(result1.isDuplicate, isFalse);
      expect(result1.subscriptionActivated, isTrue);

      // Second duplicate execution
      final result2 = await webhookService.processWebhook(payload: payload, rawBody: rawBody);
      expect(result2.success, isTrue);
      expect(result2.isDuplicate, isTrue);
      expect(result2.subscriptionActivated, isFalse);
      expect(result2.message, contains('Duplicate webhook event'));
    });

    test('Idempotent Subscription Extension: adds duration on top of existing remaining Pro period', () async {
      final configService = PaymentGatewayConfigService();
      await configService.updateConfig(
        paymentMode: PaymentMode.gateway,
        activeProvider: PaymentGatewayType.sandbox,
        isSandbox: true,
        webhookSecret: testSecret,
        adminId: 'admin_sys',
      );

      final saasService = SaaSBackendService();
      final qrisService = ManualQrisService();
      const testUserId = 'user_existing_pro';

      // Pre-existing active subscription expiring in 15 days
      final existingExpiry = DateTime.now().add(const Duration(days: 15));
      saasService.setInMemorySubscriptionForTesting(
        testUserId,
        Subscription(
          id: 'sub_pre_existing',
          userId: testUserId,
          planId: 'plan_pro',
          status: SubscriptionStatus.active,
          currentPeriodEnd: existingExpiry,
        ),
      );

      final order = PaymentOrder(
        orderId: 'ORD-EXTEND-001',
        userId: testUserId,
        planId: 'plan_pro', // 1 month plan (30 days)
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      qrisService.setOrderForTesting(order);

      final nowSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final rawBody = '{"order_id":"ORD-EXTEND-001"}';
      final hmac = Hmac(sha256, utf8.encode(testSecret));
      final signature = hmac.convert(utf8.encode('$nowSeconds.$rawBody')).toString();

      final payload = PaymentWebhookPayload(
        eventId: 'evt_extend_001',
        orderId: 'ORD-EXTEND-001',
        eventType: 'settlement',
        signature: signature,
        timestamp: DateTime.now(),
        rawData: {'order_id': 'ORD-EXTEND-001'},
        provider: 'sandbox',
        grossAmount: 29000.0,
      );

      final webhookService = PaymentWebhookService();
      await webhookService.processWebhook(payload: payload, rawBody: rawBody);

      final updatedSub = await saasService.getUserSubscription(testUserId);
      expect(updatedSub, isNotNull);
      // New period end must be approximately existingExpiry + 30 days (45 days from now)
      final daysDiff = updatedSub!.currentPeriodEnd.difference(DateTime.now()).inDays;
      expect(daysDiff, greaterThanOrEqualTo(44));
      expect(daysDiff, lessThanOrEqualTo(46));
    });
  });

  group('Fase 5 - Cancellations & Admin Refunds', () {
    test('User or System can cancel pending order', () async {
      final qrisService = ManualQrisService();
      final order = PaymentOrder(
        orderId: 'ORD-CANCEL-001',
        userId: 'user_cancel_1',
        planId: 'plan_basic',
        amount: 15000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        status: PaymentStatus.pending,
      );
      qrisService.setOrderForTesting(order);

      final webhookService = PaymentWebhookService();
      final cancelled = await webhookService.cancelOrder(
        orderId: 'ORD-CANCEL-001',
        reason: 'User changed payment method',
        userId: 'user_cancel_1',
      );

      expect(cancelled.status, equals(PaymentStatus.failed));

      final auditEvents = webhookService.getAuditEvents('ORD-CANCEL-001');
      expect(auditEvents.any((e) => e.eventType == 'ORDER_CANCELLED'), isTrue);
    });

    test('Cannot cancel an already paid order', () async {
      final qrisService = ManualQrisService();
      final order = PaymentOrder(
        orderId: 'ORD-PAID-001',
        userId: 'user_paid_1',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        status: PaymentStatus.paid,
      );
      qrisService.setOrderForTesting(order);

      final webhookService = PaymentWebhookService();
      expect(
        () => webhookService.cancelOrder(orderId: 'ORD-PAID-001'),
        throwsStateError,
      );
    });

    test('Admin can refund paid order, but non-admin cannot', () async {
      final qrisService = ManualQrisService();
      final order = PaymentOrder(
        orderId: 'ORD-REFUND-001',
        userId: 'user_refund_1',
        planId: 'plan_pro',
        amount: 29000.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        status: PaymentStatus.paid,
      );
      qrisService.setOrderForTesting(order);

      final webhookService = PaymentWebhookService();

      // Non-admin attempt fails
      expect(
        () => webhookService.refundOrder(
          orderId: 'ORD-REFUND-001',
          adminId: 'user_regular_bob',
        ),
        throwsStateError,
      );

      // Admin attempt succeeds
      final refunded = await webhookService.refundOrder(
        orderId: 'ORD-REFUND-001',
        adminId: 'admin_support_lead',
        reason: 'Customer dispute resolution',
      );

      expect(refunded.status, equals(PaymentStatus.refunded));

      final auditEvents = webhookService.getAuditEvents('ORD-REFUND-001');
      expect(auditEvents.any((e) => e.eventType == 'ORDER_REFUNDED'), isTrue);
    });
  });
}
