import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:astrack/services/payment/payment_service.dart';
import 'package:astrack/services/payment/payment_models.dart';

void main() {
  group('ASTRACK Phase 5 — Payment Gateway Architecture & Security Tests', () {
    test('Sandbox provider creates order and tracks status correctly', () async {
      final provider = SandboxPaymentProvider();
      final order = await provider.createOrder(
        userId: 'user_dev_123',
        planId: 'plan_pro',
        amount: 29000,
      );

      expect(order.orderId.startsWith('ORD_SANDBOX_'), isTrue);
      expect(order.status, equals(PaymentStatus.pending));

      final pendingStatus = await provider.checkOrderStatus(order.orderId);
      expect(pendingStatus, equals(PaymentStatus.pending));

      // Simulate payment
      provider.simulateSuccessfulPayment(order.orderId);
      final paidStatus = await provider.checkOrderStatus(order.orderId);
      expect(paidStatus, equals(PaymentStatus.paid));
    });

    test('PaymentWebhookVerifier verifies valid HMAC SHA-256 and rejects expired replay attacks', () {
      const secret = 'super_secret_webhook_key_2026';
      final verifier = PaymentWebhookVerifier(webhookSecret: secret);

      final nowTs = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      const rawBody = '{"order_id":"ORD_123","status":"paid","gross_amount":29000}';

      final payload = '$nowTs.$rawBody';
      final hmac = Hmac(sha256, utf8.encode(secret));
      final validSignature = hmac.convert(utf8.encode(payload)).toString();

      // Valid signature within 5-minute window
      expect(verifier.verifyHmacSha256(rawBody: rawBody, signature: validSignature, timestamp: nowTs), isTrue);

      // Invalid signature
      expect(verifier.verifyHmacSha256(rawBody: rawBody, signature: 'invalid_forged_sig', timestamp: nowTs), isFalse);

      // Replay attack: timestamp from 10 minutes ago (> 300 seconds)
      final oldTs = ((DateTime.now().millisecondsSinceEpoch ~/ 1000) - 600).toString();
      final oldPayload = '$oldTs.$rawBody';
      final oldSignature = hmac.convert(utf8.encode(oldPayload)).toString();
      expect(verifier.verifyHmacSha256(rawBody: rawBody, signature: oldSignature, timestamp: oldTs), isFalse);
    });

    test('PaymentWebhookVerifier verifies Midtrans SHA512 signature', () {
      const serverKey = 'midtrans_server_key_live_xyz';
      final verifier = PaymentWebhookVerifier(webhookSecret: serverKey);

      const orderId = 'ORD_MDT_999';
      const statusCode = '200';
      const grossAmount = '29000.00';

      final input = '$orderId$statusCode$grossAmount$serverKey';
      final expectedSig = sha512.convert(utf8.encode(input)).toString();

      expect(verifier.verifyMidtransSha512(
        orderId: orderId,
        statusCode: statusCode,
        grossAmount: grossAmount,
        signatureKey: expectedSig,
      ), isTrue);
    });

    test('PaymentWebhookVerifier enforces idempotency: rejects duplicate processed events', () {
      final verifier = PaymentWebhookVerifier(webhookSecret: 'sec');
      const eventId = 'evt_payment_12345';

      expect(verifier.isAlreadyProcessed(eventId), isFalse);
      verifier.markAsProcessed(eventId);
      expect(verifier.isAlreadyProcessed(eventId), isTrue);
    });
  });
}
