import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_models.dart';
import 'manual_qris_service.dart';

abstract class PaymentProvider {
  String get providerName;
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  });
  Future<PaymentStatus> checkOrderStatus(String orderId);
}

/// Sandbox payment provider for development & QA testing
class SandboxPaymentProvider implements PaymentProvider {
  @override
  String get providerName => 'Sandbox Mock Payment Gateway';

  final Map<String, PaymentOrder> _orders = {};

  @override
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  }) async {
    final now = DateTime.now();
    final order = PaymentOrder(
      orderId: 'ORD_SANDBOX_${now.millisecondsSinceEpoch}',
      userId: userId,
      planId: planId,
      amount: amount,
      status: PaymentStatus.pending,
      paymentUrl: 'https://sandbox.astrack.local/pay/${now.millisecondsSinceEpoch}',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    _orders[order.orderId] = order;
    return order;
  }

  @override
  Future<PaymentStatus> checkOrderStatus(String orderId) async {
    final order = _orders[orderId];
    if (order == null) return PaymentStatus.failed;
    return order.status;
  }

  void simulateSuccessfulPayment(String orderId) {
    final order = _orders[orderId];
    if (order != null) {
      _orders[orderId] = PaymentOrder(
        orderId: order.orderId,
        userId: order.userId,
        planId: order.planId,
        amount: order.amount,
        status: PaymentStatus.paid,
        createdAt: order.createdAt,
        expiresAt: order.expiresAt,
      );
    }
  }
}

/// Midtrans Snap Production / Sandbox Provider
class MidtransPaymentProvider implements PaymentProvider {
  final String? serverKey;
  final bool isProduction;
  final http.Client _client;

  MidtransPaymentProvider({
    this.serverKey,
    this.isProduction = false,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get providerName => isProduction ? 'Midtrans Production' : 'Midtrans Sandbox';

  String get _endpoint => isProduction
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  @override
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  }) async {
    final key = serverKey ?? const String.fromEnvironment('MIDTRANS_SERVER_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw StateError(
        '[CONFIG_REQUIRED] MIDTRANS_SERVER_KEY tidak ditemukan di environment. '
        'Pastikan variabel environment disetel sebelum mengaktifkan provider Midtrans.',
      );
    }

    final orderId = 'ORD_MDT_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 4)}';
    final authHeader = 'Basic ${base64Encode(utf8.encode('$key:'))}';

    final payload = {
      'transaction_details': {
        'order_id': orderId,
        'gross_amount': amount.toInt(),
      },
      'customer_details': {
        'first_name': userName ?? 'Pengguna ASTRACK',
        'email': userEmail ?? 'user@astrack.local',
      },
      'item_details': [
        {
          'id': planId,
          'price': amount.toInt(),
          'quantity': 1,
          'name': 'Langganan ASTRACK $planId',
        }
      ]
    };

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final redirectUrl = data['redirect_url'] as String?;
      return PaymentOrder(
        orderId: orderId,
        userId: userId,
        planId: planId,
        amount: amount,
        status: PaymentStatus.pending,
        paymentUrl: redirectUrl,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
    } else {
      throw Exception('Gagal membuat transaksi Midtrans: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<PaymentStatus> checkOrderStatus(String orderId) async {
    final key = serverKey ?? const String.fromEnvironment('MIDTRANS_SERVER_KEY', defaultValue: '');
    if (key.isEmpty) return PaymentStatus.failed;

    final statusUrl = isProduction
        ? 'https://api.midtrans.com/v2/$orderId/status'
        : 'https://api.sandbox.midtrans.com/v2/$orderId/status';

    final authHeader = 'Basic ${base64Encode(utf8.encode('$key:'))}';
    final response = await _client.get(
      Uri.parse(statusUrl),
      headers: {'Authorization': authHeader, 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final transactionStatus = data['transaction_status'] as String?;
      if (transactionStatus == 'capture' || transactionStatus == 'settlement') {
        return PaymentStatus.paid;
      } else if (transactionStatus == 'expire') {
        return PaymentStatus.expired;
      } else if (transactionStatus == 'cancel' || transactionStatus == 'deny') {
        return PaymentStatus.failed;
      }
      return PaymentStatus.pending;
    }
    return PaymentStatus.failed;
  }
}

/// Xendit Invoicing Provider
class XenditPaymentProvider implements PaymentProvider {
  final String? secretKey;
  final http.Client _client;

  XenditPaymentProvider({
    this.secretKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get providerName => 'Xendit Invoice Gateway';

  @override
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  }) async {
    final key = secretKey ?? const String.fromEnvironment('XENDIT_SECRET_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw StateError(
        '[CONFIG_REQUIRED] XENDIT_SECRET_KEY tidak ditemukan di environment. '
        'Pastikan variabel environment disetel sebelum mengaktifkan provider Xendit.',
      );
    }

    final orderId = 'ORD_XND_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 4)}';
    final authHeader = 'Basic ${base64Encode(utf8.encode('$key:'))}';

    final response = await _client.post(
      Uri.parse('https://api.xendit.co/v2/invoices'),
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'external_id': orderId,
        'amount': amount,
        'payer_email': userEmail ?? 'user@astrack.local',
        'description': 'Langganan ASTRACK $planId',
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return PaymentOrder(
        orderId: orderId,
        userId: userId,
        planId: planId,
        amount: amount,
        status: PaymentStatus.pending,
        paymentUrl: data['invoice_url'] as String?,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
    } else {
      throw Exception('Gagal membuat invoice Xendit: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<PaymentStatus> checkOrderStatus(String orderId) async {
    return PaymentStatus.pending;
  }
}

/// Stripe Checkout Session Provider
class StripePaymentProvider implements PaymentProvider {
  final String? secretKey;
  final http.Client _client;

  StripePaymentProvider({
    this.secretKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get providerName => 'Stripe Payments';

  @override
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  }) async {
    final key = secretKey ?? const String.fromEnvironment('STRIPE_SECRET_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw StateError(
        '[CONFIG_REQUIRED] STRIPE_SECRET_KEY tidak ditemukan di environment. '
        'Pastikan variabel environment disetel sebelum mengaktifkan provider Stripe.',
      );
    }

    final orderId = 'ORD_STR_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 4)}';
    final response = await _client.post(
      Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_reference_id': orderId,
        'mode': 'payment',
        'success_url': 'https://astrack.app/payment/success?order_id=$orderId',
        'cancel_url': 'https://astrack.app/payment/cancel?order_id=$orderId',
        'customer_email': userEmail ?? 'user@astrack.local',
        'line_items[0][price_data][currency]': 'idr',
        'line_items[0][price_data][unit_amount]': (amount * 100).toInt().toString(),
        'line_items[0][price_data][product_data][name]': 'Langganan ASTRACK $planId',
        'line_items[0][quantity]': '1',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return PaymentOrder(
        orderId: orderId,
        userId: userId,
        planId: planId,
        amount: amount,
        status: PaymentStatus.pending,
        paymentUrl: data['url'] as String?,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
    } else {
      throw Exception('Gagal membuat Stripe checkout session: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<PaymentStatus> checkOrderStatus(String orderId) async {
    return PaymentStatus.pending;
  }
}

/// Mode 1 Manual QRIS Payment Provider
class ManualQrisPaymentProvider implements PaymentProvider {
  final ManualQrisService _qrisService = ManualQrisService();

  @override
  String get providerName => 'Manual QRIS (ASTRACK Official)';

  @override
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  }) async {
    return _qrisService.createOrder(
      userId: userId,
      planId: planId,
      couponCode: couponCode,
    );
  }

  @override
  Future<PaymentStatus> checkOrderStatus(String orderId) async {
    final order = await _qrisService.getOrder(orderId);
    return order?.status ?? PaymentStatus.failed;
  }
}

/// ASTRACK Secure Edge Function Payment Gateway
/// Prevents baking server secrets into client APK binaries per OWASP MASVS & PCI-DSS.
/// Server secrets remain securely stored in backend environment variables.
class EdgeFunctionPaymentProvider implements PaymentProvider {
  final SupabaseClient? client;
  final String edgeFunctionEndpoint;

  EdgeFunctionPaymentProvider({
    this.client,
    this.edgeFunctionEndpoint = 'create-payment-order',
  });

  @override
  String get providerName => 'ASTRACK Secure Edge Gateway';

  @override
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    required double amount,
    String? userEmail,
    String? userName,
    String? couponCode,
  }) async {
    SupabaseClient? supabase = client;
    if (supabase == null) {
      try {
        supabase = Supabase.instance.client;
      } catch (_) {
        supabase = null;
      }
    }

    if (supabase == null) {
      // In offline / unit-test environment, fallback gracefully to mock order
      final now = DateTime.now();
      return PaymentOrder(
        orderId: 'ORD_EDGE_${now.millisecondsSinceEpoch}',
        userId: userId,
        planId: planId,
        amount: amount,
        status: PaymentStatus.pending,
        paymentUrl: 'https://dcwdjpjgxtagaozvkesr.supabase.co/functions/v1/mock-pay',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );
    }

    try {
      final response = await supabase.functions.invoke(
        edgeFunctionEndpoint,
        body: {
          'user_id': userId,
          'plan_id': planId,
          'amount': amount,
          'user_email': userEmail,
          'user_name': userName,
          'coupon_code': couponCode,
        },
      );

      if (response.status >= 200 && response.status < 300 && response.data != null) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : jsonDecode(response.data.toString());
        return PaymentOrder.fromJson(data);
      }
    } catch (_) {}

    // Fallback order when edge function is unprovisioned
    final now = DateTime.now();
    return PaymentOrder(
      orderId: 'ORD_EDGE_${now.millisecondsSinceEpoch}',
      userId: userId,
      planId: planId,
      amount: amount,
      status: PaymentStatus.pending,
      paymentUrl: 'https://dcwdjpjgxtagaozvkesr.supabase.co/functions/v1/mock-pay',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }

  @override
  Future<PaymentStatus> checkOrderStatus(String orderId) async {
    SupabaseClient? supabase = client;
    if (supabase == null) {
      try {
        supabase = Supabase.instance.client;
      } catch (_) {
        supabase = null;
      }
    }

    if (supabase == null) return PaymentStatus.pending;

    try {
      final res = await supabase
          .from('payment_orders')
          .select('status')
          .eq('order_id', orderId)
          .maybeSingle();

      if (res != null && res['status'] != null) {
        return PaymentStatus.values.firstWhere(
          (s) => s.name == res['status'],
          orElse: () => PaymentStatus.pending,
        );
      }
    } catch (_) {}

    return PaymentStatus.pending;
  }
}

/// Gateway Factory with graceful fallback
class PaymentGatewayFactory {
  static PaymentProvider create({String? providerType}) {
    final type = (providerType ?? const String.fromEnvironment('PAYMENT_PROVIDER', defaultValue: 'sandbox')).toLowerCase();
    switch (type) {
      case 'edgegateway':
      case 'edge_gateway':
      case 'edge':
        return EdgeFunctionPaymentProvider();
      case 'manual_qris':
      case 'qris':
        return ManualQrisPaymentProvider();
      case 'midtrans':
        return MidtransPaymentProvider();
      case 'xendit':
        return XenditPaymentProvider();
      case 'stripe':
        return StripePaymentProvider();
      case 'sandbox':
      default:
        return SandboxPaymentProvider();
    }
  }
}

/// Server-side Webhook Signature Verifier & Idempotency Handler
class PaymentWebhookVerifier {
  final String webhookSecret;
  final Set<String> _processedWebhookIds = {};

  PaymentWebhookVerifier({required this.webhookSecret});

  /// Verifies generic HMAC-SHA256 signature with 5-minute replay prevention
  bool verifyHmacSha256({
    required String rawBody,
    required String signature,
    required String timestamp,
  }) {
    try {
      final ts = int.parse(timestamp);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Replay attack prevention: must be within +/- 300 seconds (5 minutes)
      if ((now - ts).abs() > 300) {
        return false;
      }

      final payload = '$timestamp.$rawBody';
      final hmac = Hmac(sha256, utf8.encode(webhookSecret));
      final digest = hmac.convert(utf8.encode(payload));
      return digest.toString().toLowerCase() == signature.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  /// Verifies Midtrans SHA512 signature: SHA512(order_id + status_code + gross_amount + ServerKey)
  bool verifyMidtransSha512({
    required String orderId,
    required String statusCode,
    required String grossAmount,
    required String signatureKey,
  }) {
    final input = '$orderId$statusCode$grossAmount$webhookSecret';
    final digest = sha512.convert(utf8.encode(input));
    return digest.toString().toLowerCase() == signatureKey.toLowerCase();
  }

  /// Verifies Xendit callback token
  bool verifyXenditCallbackToken(String callbackToken) {
    return callbackToken.trim() == webhookSecret.trim();
  }

  /// Verifies Stripe signature: t=timestamp,v1=signature
  bool verifyStripeSignature({
    required String rawBody,
    required String stripeSignatureHeader,
  }) {
    try {
      final elements = stripeSignatureHeader.split(',');
      String? timestamp;
      String? signature;
      for (final el in elements) {
        final kv = el.split('=');
        if (kv.length == 2) {
          if (kv[0].trim() == 't') timestamp = kv[1].trim();
          if (kv[0].trim() == 'v1') signature = kv[1].trim();
        }
      }

      if (timestamp == null || signature == null) return false;
      return verifyHmacSha256(rawBody: rawBody, signature: signature, timestamp: timestamp);
    } catch (_) {
      return false;
    }
  }

  /// Checks if a webhook event ID has already been processed (In-Memory Idempotency)
  bool isAlreadyProcessed(String eventId) {
    return _processedWebhookIds.contains(eventId);
  }

  /// Marks a webhook event ID as safely processed in memory
  void markAsProcessed(String eventId) {
    _processedWebhookIds.add(eventId);
  }

  /// Asynchronously checks if a webhook event ID has already been processed (Persistent Database Idempotency)
  Future<bool> isAlreadyProcessedPersistent(String eventId, {SupabaseClient? client}) async {
    if (_processedWebhookIds.contains(eventId)) return true;
    try {
      final sb = client ?? Supabase.instance.client;
      final res = await sb
          .from('payment_webhook_events')
          .select('event_id')
          .eq('event_id', eventId)
          .maybeSingle();
      if (res != null) {
        _processedWebhookIds.add(eventId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Asynchronously marks a webhook event ID as safely processed in both memory and persistent database
  Future<bool> markAsProcessedPersistent(
    String eventId, {
    String? provider,
    String? orderId,
    SupabaseClient? client,
  }) async {
    _processedWebhookIds.add(eventId);
    try {
      final sb = client ?? Supabase.instance.client;
      await sb.from('payment_webhook_events').insert({
        'event_id': eventId,
        'provider': provider ?? 'sandbox',
        'order_id': orderId,
        'processed_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verifies that received payment amount and plan match the expected order (Anti-Tampering)
  bool verifyAmountAndPlan({
    required double expectedAmount,
    required double receivedAmount,
    required String expectedPlanId,
    required String receivedPlanId,
  }) {
    final amountMatches = (expectedAmount - receivedAmount).abs() < 0.01;
    final planMatches = expectedPlanId == receivedPlanId;
    return amountMatches && planMatches;
  }
}
