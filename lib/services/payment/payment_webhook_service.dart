import 'package:supabase_flutter/supabase_flutter.dart';
import '../saas_backend_service.dart';
import 'manual_qris_service.dart';
import 'payment_gateway_config_service.dart';
import 'payment_models.dart';
import 'payment_service.dart';

class PaymentWebhookService {
  static final PaymentWebhookService _instance = PaymentWebhookService._internal();
  factory PaymentWebhookService() => _instance;
  PaymentWebhookService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final Set<String> _inMemoryProcessedEvents = {};
  final List<PaymentEvent> _inMemoryAuditEvents = [];

  void resetInMemoryState() {
    _inMemoryProcessedEvents.clear();
    _inMemoryAuditEvents.clear();
  }

  /// Processes an incoming payment webhook event end-to-end
  Future<WebhookProcessingResult> processWebhook({
    required PaymentWebhookPayload payload,
    String? rawBody,
    String? signatureKey,
  }) async {
    final config = await PaymentGatewayConfigService().getConfig();
    final verifier = PaymentWebhookVerifier(webhookSecret: config.webhookSecret);

    // 1. Replay Protection: Timestamp must be within +/- 300 seconds (5 minutes)
    final nowTs = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final eventTs = payload.timestamp.toUtc().millisecondsSinceEpoch ~/ 1000;
    if ((nowTs - eventTs).abs() > 300) {
      return WebhookProcessingResult(
        success: false,
        orderId: payload.orderId,
        message: 'Replay attack prevented: Timestamp expired (> 300 seconds).',
      );
    }

    // 2. Signature Verification based on Gateway Provider
    bool isSignatureValid = false;
    switch (payload.provider.toLowerCase()) {
      case 'midtrans':
        final grossAmountStr = (payload.grossAmount ?? payload.rawData['gross_amount'] ?? '').toString();
        final statusCode = (payload.rawData['status_code'] ?? '200').toString();
        isSignatureValid = verifier.verifyMidtransSha512(
          orderId: payload.orderId,
          statusCode: statusCode,
          grossAmount: grossAmountStr,
          signatureKey: payload.signature,
        );
        break;
      case 'xendit':
        isSignatureValid = verifier.verifyXenditCallbackToken(payload.signature);
        break;
      case 'stripe':
        isSignatureValid = verifier.verifyStripeSignature(
          rawBody: rawBody ?? '',
          stripeSignatureHeader: payload.signature,
        );
        break;
      case 'sandbox':
      default:
        isSignatureValid = verifier.verifyHmacSha256(
          rawBody: rawBody ?? '{"order_id":"${payload.orderId}"}',
          signature: payload.signature,
          timestamp: (payload.timestamp.millisecondsSinceEpoch ~/ 1000).toString(),
        );
        break;
    }

    if (!isSignatureValid) {
      return WebhookProcessingResult(
        success: false,
        orderId: payload.orderId,
        message: 'Invalid webhook signature: Signature verification failed.',
      );
    }

    // 3. Persistent & In-Memory Idempotency Check
    if (_inMemoryProcessedEvents.contains(payload.eventId)) {
      return WebhookProcessingResult(
        success: true,
        orderId: payload.orderId,
        isDuplicate: true,
        message: 'Duplicate webhook event: Already processed safely.',
      );
    }

    final client = _supabase;
    if (client != null) {
      final isDbDuplicate = await verifier.isAlreadyProcessedPersistent(payload.eventId, client: client);
      if (isDbDuplicate) {
        _inMemoryProcessedEvents.add(payload.eventId);
        return WebhookProcessingResult(
          success: true,
          orderId: payload.orderId,
          isDuplicate: true,
          message: 'Duplicate webhook event: Already recorded in persistent database.',
        );
      }
    }

    // 4. Retrieve Order & Anti-Tampering Check
    final qrisService = ManualQrisService();
    final order = await qrisService.getOrder(payload.orderId);
    if (order == null) {
      return WebhookProcessingResult(
        success: false,
        orderId: payload.orderId,
        message: 'Order not found.',
      );
    }

    if (payload.grossAmount != null) {
      final amountMatches = (order.amount - payload.grossAmount!).abs() < 0.01;
      if (!amountMatches) {
        return WebhookProcessingResult(
          success: false,
          orderId: payload.orderId,
          message: 'Anti-tampering alert: Gross amount ${payload.grossAmount} does not match order amount ${order.amount}.',
        );
      }
    }

    // 5. State Transition & Auto-Activation
    PaymentStatus newStatus;
    bool subscriptionActivated = false;
    final normalizedEvent = payload.eventType.toLowerCase();

    if (normalizedEvent == 'paid' || normalizedEvent == 'settlement' || normalizedEvent == 'capture') {
      newStatus = PaymentStatus.paid;

      if (order.status != PaymentStatus.paid) {
        final saas = SaaSBackendService();
        final plans = await saas.getPlans(includeInactive: true);
        final plan = plans.firstWhere(
          (p) => p.id == order.planId,
          orElse: () => plans.first,
        );

        // Idempotent Extension: record successful subscription with plan duration
        final durationMonths = plan.durationMonths;

        await saas.recordSuccessfulSubscription(
          userId: order.userId,
          planId: order.planId,
          durationMonths: durationMonths,
          paidAmount: order.amount,
          orderId: order.orderId,
        );

        if (order.couponCode != null && order.couponCode!.isNotEmpty) {
          await saas.redeemCouponOrder(
            code: order.couponCode!,
            planId: order.planId,
            userId: order.userId,
            orderId: order.orderId,
          );
        }

        subscriptionActivated = true;
      }
    } else if (normalizedEvent == 'expire' || normalizedEvent == 'expired') {
      newStatus = PaymentStatus.expired;
    } else if (normalizedEvent == 'cancel' || normalizedEvent == 'deny') {
      newStatus = PaymentStatus.failed;
    } else {
      newStatus = PaymentStatus.pending;
    }

    // Update Order Status
    final updatedOrder = order.copyWith(
      status: newStatus,
      verifiedAt: newStatus == PaymentStatus.paid ? DateTime.now() : order.verifiedAt,
      verifiedBy: newStatus == PaymentStatus.paid ? 'webhook_${payload.provider}' : order.verifiedBy,
    );
    qrisService.setOrderForTesting(updatedOrder);

    // 6. Record Processed Event (Idempotency) & Audit Trail
    _inMemoryProcessedEvents.add(payload.eventId);
    if (client != null) {
      await verifier.markAsProcessedPersistent(
        payload.eventId,
        provider: payload.provider,
        orderId: payload.orderId,
        client: client,
      );
    }

    _logAuditEvent(payload.orderId, 'WEBHOOK_PROCESSED', payload: {
      'provider': payload.provider,
      'event_id': payload.eventId,
      'status': newStatus.name,
      'amount': payload.grossAmount ?? order.amount,
    });

    return WebhookProcessingResult(
      success: true,
      orderId: payload.orderId,
      status: newStatus,
      isDuplicate: false,
      subscriptionActivated: subscriptionActivated,
      message: 'Webhook processed successfully: Order is now ${newStatus.name}.',
    );
  }

  /// Cancels an order
  Future<PaymentOrder> cancelOrder({
    required String orderId,
    String? reason,
    String? userId,
  }) async {
    final qrisService = ManualQrisService();
    final order = await qrisService.getOrder(orderId);
    if (order == null) throw ArgumentError('Order $orderId tidak ditemukan.');

    if (order.status == PaymentStatus.paid) {
      throw StateError('Order yang sudah berhasil dibayar tidak dapat dibatalkan.');
    }

    final cancelled = order.copyWith(status: PaymentStatus.failed);
    qrisService.setOrderForTesting(cancelled);

    _logAuditEvent(orderId, 'ORDER_CANCELLED', actorId: userId ?? order.userId, payload: {
      'reason': reason ?? 'User cancellation',
    });

    return cancelled;
  }

  /// Refunds a paid order (restricted to Admin)
  Future<PaymentOrder> refundOrder({
    required String orderId,
    double? amount,
    String? reason,
    required String adminId,
  }) async {
    if (!adminId.toLowerCase().contains('admin')) {
      throw StateError('Unauthorized: Hanya Administrator yang berwenang memproses pengembalian dana (refund).');
    }

    final qrisService = ManualQrisService();
    final order = await qrisService.getOrder(orderId);
    if (order == null) throw ArgumentError('Order $orderId tidak ditemukan.');

    if (order.status != PaymentStatus.paid) {
      throw StateError('Hanya pesanan yang berstatus berhasil (paid) yang dapat di-refund.');
    }

    final refunded = order.copyWith(status: PaymentStatus.refunded);
    qrisService.setOrderForTesting(refunded);

    _logAuditEvent(orderId, 'ORDER_REFUNDED', actorId: adminId, payload: {
      'refund_amount': amount ?? order.amount,
      'reason': reason ?? 'Admin refund',
    });

    return refunded;
  }

  List<PaymentEvent> getAuditEvents(String orderId) {
    return _inMemoryAuditEvents.where((e) => e.orderId == orderId).toList();
  }

  void _logAuditEvent(String orderId, String eventType, {String? actorId, Map<String, dynamic> payload = const {}}) {
    _inMemoryAuditEvents.add(PaymentEvent(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      eventType: eventType,
      actorId: actorId,
      payload: payload,
      createdAt: DateTime.now(),
    ));
  }
}
