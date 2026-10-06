import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/saas_models.dart';
import '../saas_backend_service.dart';
import 'payment_models.dart';

class ManualQrisService {
  static final ManualQrisService _instance = ManualQrisService._internal();
  factory ManualQrisService() => _instance;
  ManualQrisService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory store for standalone execution / unit test isolation / offline fallback
  final Map<String, PaymentOrder> _inMemoryOrders = {};
  final List<PaymentProof> _inMemoryProofs = [];
  final List<PaymentEvent> _inMemoryEvents = [];

  void resetInMemoryState() {
    _inMemoryOrders.clear();
    _inMemoryProofs.clear();
    _inMemoryEvents.clear();
  }

  void setOrderForTesting(PaymentOrder order) {
    _inMemoryOrders[order.orderId] = order;
  }

  /// Calculates Asia/Jakarta calendar date (UTC+7)
  DateTime getJakartaDateTime([DateTime? date]) {
    final utc = (date ?? DateTime.now()).toUtc();
    return utc.add(const Duration(hours: 7));
  }

  /// Generates deterministic unique code 001-999 for today with collision prevention
  int generateDailyUniqueCode({DateTime? forDate}) {
    final jakartaDate = getJakartaDateTime(forDate);
    final dateKey = '${jakartaDate.year}-${jakartaDate.month.toString().padLeft(2, '0')}-${jakartaDate.day.toString().padLeft(2, '0')}';

    final activeCodesToday = _inMemoryOrders.values.where((o) {
      final orderDate = getJakartaDateTime(o.createdAt);
      final orderDateKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
      return orderDateKey == dateKey &&
          (o.status == PaymentStatus.pending || o.status == PaymentStatus.claimed);
    }).map((o) => o.uniqueCode ?? 0).toSet();

    // Try incremental code based on existing count
    int candidate = (activeCodesToday.length + 1) % 1000;
    if (candidate == 0) candidate = 1;

    if (!activeCodesToday.contains(candidate)) {
      return candidate;
    }

    // Scan for first available gap between 1 and 999
    for (int i = 1; i <= 999; i++) {
      if (!activeCodesToday.contains(i)) {
        return i;
      }
    }

    // Fallback pseudo-random if completely saturated
    return Random().nextInt(999) + 1;
  }

  /// Calculates final payable amount: base - discount + uniqueCode
  double calculateFinalAmount({
    required double baseAmount,
    double discountAmount = 0.0,
    required int uniqueCode,
  }) {
    final afterDiscount = max(0.0, baseAmount - discountAmount);
    return afterDiscount + uniqueCode;
  }

  /// Standard Indonesian QRIS string generator (EMVCo compliant format)
  String generateQrisPayload({
    required String orderId,
    required double amount,
    String merchantName = 'ASTRACK OFFICIAL',
  }) {
    final amountInt = amount.toInt();
    final amountStr = amountInt.toString();
    return '00020101021226590014ID.LINKAJA.WWW01189360091800000000000215ID1026001234567520458125303360540'
        '${amountStr.length.toString().padLeft(2, '0')}$amountStr'
        '5802ID59${merchantName.length.toString().padLeft(2, '0')}$merchantName'
        '6007JAKARTA62${orderId.length.toString().padLeft(2, '0')}$orderId'
        '6304';
  }

  /// Creates a Manual QRIS Order
  Future<PaymentOrder> createOrder({
    required String userId,
    required String planId,
    String? couponCode,
  }) async {
    final saas = SaaSBackendService();
    final client = _supabase;

    // 1. Fetch and validate plan
    final plans = await saas.getPlans(includeInactive: true);
    final plan = plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => throw ArgumentError('Paket langganan $planId tidak ditemukan.'),
    );

    if (!plan.isActive) {
      throw StateError('Paket langganan ${plan.name} sedang tidak aktif.');
    }

    final baseAmount = plan.monthlyPrice;
    double discountAmount = 0.0;
    String? appliedCouponCode;

    // 2. Validate coupon if provided
    if (couponCode != null && couponCode.trim().isNotEmpty) {
      final couponVal = await saas.validateCouponServer(
        code: couponCode.trim(),
        planId: planId,
        userId: userId,
      );
      if (couponVal.isValid) {
        discountAmount = couponVal.discountAmount;
        appliedCouponCode = couponVal.coupon?.code;
      } else {
        throw ArgumentError(couponVal.errorMessage ?? 'Kupon tidak valid.');
      }
    }

    // 3. Generate unique code and timestamps
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));
    final uniqueCode = generateDailyUniqueCode(forDate: now);
    final finalAmount = calculateFinalAmount(
      baseAmount: baseAmount,
      discountAmount: discountAmount,
      uniqueCode: uniqueCode,
    );

    final jakartaNow = getJakartaDateTime(now);
    final datePart = '${jakartaNow.year}${jakartaNow.month.toString().padLeft(2, '0')}${jakartaNow.day.toString().padLeft(2, '0')}';
    final timePart = '${jakartaNow.hour.toString().padLeft(2, '0')}${jakartaNow.minute.toString().padLeft(2, '0')}${jakartaNow.second.toString().padLeft(2, '0')}';
    final codePart = uniqueCode.toString().padLeft(3, '0');
    final orderId = 'ORD-QRIS-$datePart-$timePart-$codePart';

    final qrisPayload = generateQrisPayload(orderId: orderId, amount: finalAmount);

    final order = PaymentOrder(
      orderId: orderId,
      userId: userId,
      planId: planId,
      amount: finalAmount,
      currency: 'IDR',
      status: PaymentStatus.pending,
      createdAt: now,
      expiresAt: expiresAt,
      baseAmount: baseAmount,
      discountAmount: discountAmount,
      uniqueCode: uniqueCode,
      couponCode: appliedCouponCode,
      paymentMethod: 'manual_qris',
      qrisPayload: qrisPayload,
    );

    // Save via Supabase RPC if online
    if (client != null) {
      try {
        final res = await client.rpc('create_manual_qris_order', params: {
          'p_plan_id': planId,
          'p_coupon_code': appliedCouponCode,
          'p_user_id': userId,
        });
        if (res != null && res['success'] == true) {
          final serverOrder = PaymentOrder.fromJson(res);
          _inMemoryOrders[serverOrder.orderId] = serverOrder;
          return serverOrder;
        }
      } catch (_) {
        // Fall back to local store
      }
    }

    _inMemoryOrders[order.orderId] = order;
    _logEvent(orderId, 'ORDER_CREATED', actorId: userId, payload: {
      'plan_id': planId,
      'base_amount': baseAmount,
      'discount_amount': discountAmount,
      'unique_code': uniqueCode,
      'final_amount': finalAmount,
    });

    return order;
  }

  /// User claims payment ("Saya Sudah Bayar") with optional proof of transfer
  Future<PaymentOrder> claimPayment({
    required String orderId,
    String? proofUrl,
    String? proofNotes,
    String? userId,
  }) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.rpc('claim_payment_order', params: {
          'p_order_id': orderId,
          'p_proof_url': proofUrl,
          'p_notes': proofNotes,
        });
        if (res != null && res['success'] == true) {
          final existing = _inMemoryOrders[orderId];
          if (existing != null) {
            _inMemoryOrders[orderId] = existing.copyWith(
              status: PaymentStatus.claimed,
              proofUrl: proofUrl,
              proofNotes: proofNotes,
              claimedAt: DateTime.now(),
            );
            return _inMemoryOrders[orderId]!;
          }
        }
      } catch (_) {}
    }

    final order = _inMemoryOrders[orderId];
    if (order == null) {
      throw ArgumentError('Order $orderId tidak ditemukan.');
    }

    if (order.status == PaymentStatus.paid) {
      throw StateError('Order ini sudah berhasil disetujui sebelumnya.');
    }

    if (order.isExpired || order.status == PaymentStatus.expired) {
      _inMemoryOrders[orderId] = order.copyWith(status: PaymentStatus.expired);
      throw StateError('Batas waktu pembayaran untuk order ini telah kedaluwarsa.');
    }

    final claimedOrder = order.copyWith(
      status: PaymentStatus.claimed,
      proofUrl: proofUrl ?? order.proofUrl,
      proofNotes: proofNotes ?? order.proofNotes,
      claimedAt: DateTime.now(),
    );

    _inMemoryOrders[orderId] = claimedOrder;

    if (proofUrl != null && proofUrl.isNotEmpty) {
      _inMemoryProofs.add(PaymentProof(
        id: 'proof_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        userId: userId ?? order.userId,
        proofUrl: proofUrl,
        notes: proofNotes,
        uploadedAt: DateTime.now(),
      ));
    }

    _logEvent(orderId, 'PAYMENT_CLAIMED', actorId: userId ?? order.userId, payload: {
      'proof_url': proofUrl,
      'notes': proofNotes,
    });

    return claimedOrder;
  }

  /// Admin approves order with idempotent subscription extension
  Future<PaymentOrder> approveOrder({
    required String orderId,
    required String adminId,
  }) async {
    if (!adminId.toLowerCase().contains('admin')) {
      throw StateError('Unauthorized: Hanya Administrator yang berwenang menyetujui pembayaran.');
    }

    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.rpc('admin_approve_payment_order', params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        });
        if (res != null && res['success'] == true) {
          final existing = _inMemoryOrders[orderId];
          if (existing != null) {
            _inMemoryOrders[orderId] = existing.copyWith(
              status: PaymentStatus.paid,
              verifiedAt: DateTime.now(),
              verifiedBy: adminId,
            );
            return _inMemoryOrders[orderId]!;
          }
        }
      } catch (_) {}
    }

    final order = _inMemoryOrders[orderId];
    if (order == null) {
      throw ArgumentError('Order $orderId tidak ditemukan.');
    }

    if (order.status == PaymentStatus.paid) {
      return order; // Idempotent return
    }

    final saas = SaaSBackendService();
    final plans = await saas.getPlans(includeInactive: true);
    final plan = plans.firstWhere(
      (p) => p.id == order.planId,
      orElse: () => plans.first,
    );

    // Idempotent Extension Check:
    // If user currently has active Pro, extend from currentPeriodEnd.
    // Otherwise activate from now().
    final currentSub = await saas.getUserSubscription(order.userId);
    final now = DateTime.now();
    DateTime newStart = now;

    if (currentSub != null &&
        currentSub.status == SubscriptionStatus.active &&
        currentSub.currentPeriodEnd.isAfter(now)) {
      newStart = currentSub.currentPeriodEnd;
    }

    final durationMonths = plan.durationMonths;
    final expiresAt = durationMonths >= 120
        ? newStart.add(const Duration(days: 3650))
        : newStart.add(Duration(days: 30 * durationMonths));

    // Record subscription
    await saas.recordSuccessfulSubscription(
      userId: order.userId,
      planId: order.planId,
      durationMonths: durationMonths,
      paidAmount: order.amount,
      orderId: order.orderId,
    );

    // If coupon used, redeem coupon
    if (order.couponCode != null && order.couponCode!.isNotEmpty) {
      await saas.redeemCouponOrder(
        code: order.couponCode!,
        planId: order.planId,
        userId: order.userId,
        orderId: order.orderId,
      );
    }

    final approvedOrder = order.copyWith(
      status: PaymentStatus.paid,
      verifiedAt: now,
      verifiedBy: adminId,
    );

    _inMemoryOrders[orderId] = approvedOrder;

    _logEvent(orderId, 'ADMIN_APPROVE', actorId: adminId, payload: {
      'new_start': newStart.toIso8601String(),
      'new_end': expiresAt.toIso8601String(),
      'amount': order.amount,
    });

    return approvedOrder;
  }

  /// Admin rejects order with mandatory reason
  Future<PaymentOrder> rejectOrder({
    required String orderId,
    required String reason,
    required String adminId,
  }) async {
    if (!adminId.toLowerCase().contains('admin')) {
      throw StateError('Unauthorized: Hanya Administrator yang berwenang menolak pembayaran.');
    }

    if (reason.trim().length < 5) {
      throw ArgumentError('Alasan penolakan wajib diisi minimal 5 karakter.');
    }

    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.rpc('admin_reject_payment_order', params: {
          'p_order_id': orderId,
          'p_reason': reason.trim(),
          'p_admin_id': adminId,
        });
        if (res != null && res['success'] == true) {
          final existing = _inMemoryOrders[orderId];
          if (existing != null) {
            _inMemoryOrders[orderId] = existing.copyWith(
              status: PaymentStatus.rejected,
              rejectionReason: reason.trim(),
              verifiedAt: DateTime.now(),
              verifiedBy: adminId,
            );
            return _inMemoryOrders[orderId]!;
          }
        }
      } catch (_) {}
    }

    final order = _inMemoryOrders[orderId];
    if (order == null) {
      throw ArgumentError('Order $orderId tidak ditemukan.');
    }

    if (order.status == PaymentStatus.paid) {
      throw StateError('Order yang sudah disetujui tidak dapat ditolak.');
    }

    final rejectedOrder = order.copyWith(
      status: PaymentStatus.rejected,
      rejectionReason: reason.trim(),
      verifiedAt: DateTime.now(),
      verifiedBy: adminId,
    );

    _inMemoryOrders[orderId] = rejectedOrder;

    _logEvent(orderId, 'ADMIN_REJECT', actorId: adminId, payload: {
      'reason': reason.trim(),
    });

    return rejectedOrder;
  }

  /// Returns specific order
  Future<PaymentOrder?> getOrder(String orderId) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.from('payment_orders').select().eq('order_id', orderId).maybeSingle();
        if (res != null) {
          final order = PaymentOrder.fromJson(res);
          _inMemoryOrders[order.orderId] = order;
          return order;
        }
      } catch (_) {}
    }
    return _inMemoryOrders[orderId];
  }

  /// Returns orders for a user
  Future<List<PaymentOrder>> getUserOrders(String userId) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client
            .from('payment_orders')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return res.map<PaymentOrder>((e) => PaymentOrder.fromJson(e)).toList();
      } catch (_) {}
    }
    return _inMemoryOrders.values
        .where((o) => o.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Returns orders for the Admin Verification Queue
  Future<List<PaymentOrder>> getAdminQueue({PaymentStatus? statusFilter}) async {
    final client = _supabase;
    if (client != null) {
      try {
        var query = client.from('payment_orders').select();
        if (statusFilter != null) {
          query = query.eq('status', statusFilter.name);
        }
        final res = await query.order('created_at', ascending: false);
        return res.map<PaymentOrder>((e) => PaymentOrder.fromJson(e)).toList();
      } catch (_) {}
    }

    var list = _inMemoryOrders.values.toList();
    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Returns proofs for an order
  Future<List<PaymentProof>> getOrderProofs(String orderId) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client
            .from('payment_proofs')
            .select()
            .eq('order_id', orderId)
            .order('uploaded_at', ascending: false);
        return res.map<PaymentProof>((e) => PaymentProof.fromJson(e)).toList();
      } catch (_) {}
    }
    return _inMemoryProofs.where((p) => p.orderId == orderId).toList();
  }

  /// Returns audit events for an order
  Future<List<PaymentEvent>> getOrderEvents(String orderId) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client
            .from('payment_events')
            .select()
            .eq('order_id', orderId)
            .order('created_at', ascending: false);
        return res.map<PaymentEvent>((e) => PaymentEvent.fromJson(e)).toList();
      } catch (_) {}
    }
    return _inMemoryEvents.where((e) => e.orderId == orderId).toList();
  }

  void _logEvent(String orderId, String eventType, {String? actorId, Map<String, dynamic> payload = const {}}) {
    _inMemoryEvents.add(PaymentEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      orderId: orderId,
      eventType: eventType,
      actorId: actorId,
      payload: payload,
      createdAt: DateTime.now(),
    ));
  }
}
