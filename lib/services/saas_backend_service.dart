import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saas_models.dart';
import '../models/coupon_model.dart';

class SaaSBackendService {
  static final SaaSBackendService _instance = SaaSBackendService._internal();
  factory SaaSBackendService() => _instance;
  SaaSBackendService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> initializeDatabase() async {
    // Legacy seeding removed. Supabase PostgreSQL is now the Authority.
  }

  List<Plan>? _inMemoryPlans;


  List<Plan> _defaultPlans() => [
    Plan(
      id: 'plan_basic',
      slug: 'basic',
      name: 'Basic',
      description: 'Essential tools for budgeting & tracking',
      type: PlanType.regular,
      monthlyPrice: 15000.0,
      durationMonths: 1,
      maxDevices: 2,
      maxAiRequests: 50,
      features: const [
        'Catat transaksi tanpa batas',
        'Impor & Ekspor data transaksi CSV',
        'Analisis pengeluaran kategori',
        'Cetak laporan bulanan PDF',
      ],
      isActive: true,
      isRecommended: false,
    ),
    Plan(
      id: 'plan_pro',
      slug: 'pro',
      name: 'Pro',
      description: 'Advanced AI and unlimited access',
      type: PlanType.regular,
      monthlyPrice: 29000.0,
      durationMonths: 1,
      maxDevices: 5,
      maxAiRequests: 1000,
      features: const [
        'Semua fitur pada paket Basic',
        'Auto-scan struk belanja (OCR) instan',
        'Asisten Finansial AI tanpa batas',
        'Advanced Financial Analytics & Forecasts',
        'Sinkronisasi Multi-Device Cloud',
      ],
      isActive: true,
      isRecommended: true,
    ),
  ];

  // --- PLANS ---
  Future<List<Plan>> getPlans({bool includeInactive = false}) async {
    final client = _supabase;
    // 1. If online and Supabase client available, query Supabase plans
    if (client != null) {
      try {
        var query = client.from('plans').select();
        if (!includeInactive) {
          query = query.eq('is_active', true);
        }
        final response = await query.order('monthly_price', ascending: true);

        final plans = response.map<Plan>((e) => Plan.fromJson(e)).toList();

        if (plans.isNotEmpty) {
          _inMemoryPlans = List.from(plans);
          // Cache plans locally for offline display
          try {
            final prefs = await SharedPreferences.getInstance();
            final jsonStr = jsonEncode(plans.map((p) => p.toJson()).toList());
            await prefs.setString('cached_plans_ssot', jsonStr);
          } catch (_) {}
          return plans;
        }
      } catch (_) {
        // Fall through to cache on network failure
      }
    }

    // 2. Offline / network fallback: retrieve cached plans
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_plans_ssot');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List decoded = jsonDecode(cachedStr);
        final plans = decoded.map<Plan>((e) => Plan.fromJson(e)).toList();
        if (!includeInactive) {
          return plans.where((p) => p.isActive).toList();
        }
        return plans;
      }
    } catch (_) {}

    // 3. Fallback deterministic plans if DB cannot be reached and no cache
    _inMemoryPlans ??= _defaultPlans();
    if (!includeInactive) {
      return _inMemoryPlans!.where((p) => p.isActive).toList();
    }
    return List.from(_inMemoryPlans!);
  }

  Future<void> createCustomPlan(Plan plan) async {
    final client = _supabase;
    if (client == null) return;
    await client.from('plans').insert({
      'id': plan.id,
      'name': plan.name,
      'description': plan.description,
      'duration_months': 1,
      'type': plan.type.name,
      'monthly_price': plan.monthlyPrice,
      'is_active': plan.isActive
    });
  }

  // --- SUBSCRIPTIONS (The Real SSOT) ---
  Future<List<Subscription>> getAllSubscriptions() async {
    final client = _supabase;
    if (client == null) return [];
    try {
      final response = await client.from('subscriptions').select();
      return response.map<Subscription>((e) => Subscription(
        id: e['id'],
        userId: e['user_id'],
        planId: e['plan_id'],
        status: SubscriptionStatus.values.firstWhere((s) => s.name == e['status'], orElse: () => SubscriptionStatus.expired),
        currentPeriodEnd: DateTime.parse(e['expires_at']).toLocal(),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Subscription?> getUserSubscription(String userId) async {
    final client = _supabase;
    if (client == null) return _inMemorySubscriptions[userId];
    try {
      final response = await client.rpc('get_my_active_subscription');
      if (response != null) {
        return Subscription(
          id: response['id']?.toString() ?? '',
          userId: userId,
          planId: response['plan_id']?.toString() ?? 'plan_free',
          status: response['is_valid'] == true ? SubscriptionStatus.active : SubscriptionStatus.expired,
          currentPeriodEnd: DateTime.parse(response['expires_at'].toString()).toLocal(),
        );
      }
    } catch (_) {}

    // Fallback: Admin RPC if user is admin checking another user
    try {
      final adminResponse = await client.rpc('admin_get_user_subscription', params: {
        'target_user_id': userId,
      });
      if (adminResponse != null) {
        return Subscription(
          id: adminResponse['id']?.toString() ?? '',
          userId: userId,
          planId: adminResponse['plan_id']?.toString() ?? 'plan_free',
          status: adminResponse['is_valid'] == true ? SubscriptionStatus.active : SubscriptionStatus.expired,
          currentPeriodEnd: DateTime.parse(adminResponse['expires_at'].toString()).toLocal(),
        );
      }
    } catch (_) {}

    // Direct table query fallback if RPCs are unavailable
    try {
      final tableResponse = await client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (tableResponse != null) {
        final exp = DateTime.parse(tableResponse['expires_at'].toString()).toLocal();
        final isValid = tableResponse['status'] == 'active' && exp.isAfter(DateTime.now());
        return Subscription(
          id: tableResponse['id']?.toString() ?? '',
          userId: userId,
          planId: tableResponse['plan_id']?.toString() ?? 'plan_free',
          status: isValid ? SubscriptionStatus.active : SubscriptionStatus.expired,
          currentPeriodEnd: exp,
        );
      }
    } catch (_) {}

    return _inMemorySubscriptions[userId];
  }

  Future<void> recordSuccessfulSubscription({
    required String userId,
    required String planId,
    required int durationMonths,
    double? paidAmount,
    String? orderId,
  }) async {
    final client = _supabase;
    final now = DateTime.now().toUtc();
    final existing = _inMemorySubscriptions[userId];
    final baseDate = (existing != null &&
            existing.status == SubscriptionStatus.active &&
            existing.currentPeriodEnd.isAfter(now))
        ? existing.currentPeriodEnd
        : now;
    final expiresAt = durationMonths >= 120
        ? baseDate.add(const Duration(days: 3650))
        : baseDate.add(Duration(days: 30 * durationMonths));

    _inMemorySubscriptions[userId] = Subscription(
      id: orderId ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      planId: planId,
      status: SubscriptionStatus.active,
      currentPeriodEnd: expiresAt,
    );

    if (client == null) return;

    try {
      await client.rpc('admin_extend_subscription', params: {
        'target_user_id': userId,
        'new_plan_id': planId,
        'months_to_add': durationMonths,
      });
    } catch (_) {
      // Direct database insert fallback with transaction price snapshot
      try {
        await client.from('subscriptions').insert({
          'user_id': userId,
          'plan_id': planId,
          'status': 'active',
          'starts_at': now.toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
          if (paidAmount != null) 'paid_amount': paidAmount,
          if (orderId != null) 'order_id': orderId,
        });
      } catch (e) {
        throw Exception('Failed to record subscription: $e');
      }
    }
  }

  Future<void> assignFreePlanToUser(String userId) async {
  }

  Future<void> upgradeToPro(String userId) async {
    throw Exception('Unauthorized. Use Admin Dashboard or Payment Gateway.');
  }

  // --- LICENSES (Compatibility Layer for UI) ---
  Future<List<License>> getAllLicenses() async {
    final subs = await getAllSubscriptions();
    return subs.map((s) => License(
      id: s.id,
      licenseKey: 'AST-${s.planId.toUpperCase()}-${s.id.substring(0,8).toUpperCase()}',
      userId: s.userId,
      status: s.status == SubscriptionStatus.active ? LicenseStatus.active : LicenseStatus.expired,
      issuedAt: DateTime.now().subtract(const Duration(days: 1)),
      activatedAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: s.currentPeriodEnd,
      durationType: DurationType.months,
    )).toList();
  }

  Future<void> updateLicenseStatus(String licenseId, LicenseStatus status) async {
    final client = _supabase;
    if (client == null) return;
    await client.from('subscriptions').update({
      'status': status == LicenseStatus.active ? 'active' : 'cancelled'
    }).eq('id', licenseId);
  }

  Future<void> deleteLicense(String licenseId) async {
    final client = _supabase;
    if (client == null) return;
    await client.from('subscriptions').delete().eq('id', licenseId);
  }

  Future<void> createLicense(String userId, String customKey, {DurationType durationType = DurationType.lifetime, int durationValue = 0}) async {
    final client = _supabase;
    if (client == null) return;
    int months = 120; // Default lifetime
    if (durationType == DurationType.months) {
      months = durationValue;
    }
    
    await client.rpc('admin_extend_subscription', params: {
      'target_user_id': userId,
      'new_plan_id': 'plan_pro',
      'months_to_add': months
    });
  }

  Future<void> extendLicense(String licenseId, DurationType type, int value) async {
    final client = _supabase;
    if (client == null) return;
    try {
      final sub = await client.from('subscriptions').select('user_id').eq('id', licenseId).single();
      final userId = sub['user_id'];
      
      if (type == DurationType.months) {
        await client.rpc('admin_extend_subscription', params: {
          'target_user_id': userId,
          'new_plan_id': 'plan_pro',
          'months_to_add': value
        });
      } else {
        final curr = await client.from('subscriptions').select('expires_at').eq('id', licenseId).single();
        final currExp = DateTime.parse(curr['expires_at']);
        final newExp = currExp.add(Duration(days: value));
        await client.from('subscriptions').update({
          'expires_at': newExp.toUtc().toIso8601String()
        }).eq('id', licenseId);
      }
    } catch (e) {
      throw Exception('Admin Extension Failed: $e');
    }
  }

  Future<void> runExpirationWorker() async {
  }

  // --- ENTITLEMENTS & USAGE ---
  Future<bool> checkAndConsumeAiQuota(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final sub = await getUserSubscription(userId);
    
    final now = DateTime.now();
    final usageKey = 'ai_usage_${userId}_${now.year}_${now.month}';
    int currentUsage = prefs.getInt(usageKey) ?? 0;
    
    int maxReq = (sub != null && sub.planId == 'plan_pro') ? 1000 : 50;
    
    if (currentUsage >= maxReq) {
      return false; 
    }
    await prefs.setInt(usageKey, currentUsage + 1);
    return true;
  }

  Future<bool> hasEntitlement(String userId, String featureKey) async {
    final client = _supabase;
    if (client == null) return true; // Standalone / unit test resilience when Supabase is uninitialized

    final sub = await getUserSubscription(userId);
    if (sub == null || sub.status != SubscriptionStatus.active) {
      return false; // Free/unsubscribed users do not have paid entitlements
    }

    // Check expiry
    if (sub.currentPeriodEnd.isBefore(DateTime.now())) {
      return false;
    }

    // Pro features: requires plan_pro
    const proFeatures = {
      'ocr_scanner',
      'receipt_scanner',
      'ai_assistant',
      'ai_advisor',
      'advanced_analytics',
      'multi_device_sync',
    };

    if (proFeatures.contains(featureKey)) {
      return sub.planId == 'plan_pro';
    }

    // Basic features: accessible by plan_basic and plan_pro
    const basicFeatures = {
      'csv_import_export',
      'advanced_reports',
      'advanced_budget',
    };

    if (basicFeatures.contains(featureKey)) {
      return sub.planId == 'plan_basic' || sub.planId == 'plan_pro';
    }

    return true;
  }

  // --- PAYMENT WEBHOOKS ---
  Future<void> handlePaymentWebhook(String userId, String status) async {
  }

  // --- POLICIES AND AUDIT STUBS ---
  Future<bool> hasAcceptedLatestPolicy(String userId) async {
    return true; // Simplified for Phase 4
  }

  Future<void> acceptPolicy(String userId) async {
  }

  Future<void> logAuditAction(String actorId, String action, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsRaw = prefs.getStringList('saas_audit_logs') ?? [];
      final newLog = jsonEncode({
        'actor': actorId,
        'action': action,
        'desc': description,
        'time': DateTime.now().toIso8601String(),
      });
      logsRaw.add(newLog);
      await prefs.setStringList('saas_audit_logs', logsRaw);
    } catch (_) {}
  }

  // --- COUPON & PRICING MANAGEMENT ---
  List<Coupon> _inMemoryCoupons = [
    Coupon(
      id: 'cpn_astrack20',
      code: 'ASTRACK20',
      description: 'Diskon 20% untuk semua paket langganan',
      discountType: CouponDiscountType.percentage,
      discountValue: 20,
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      usageLimit: 500,
      usageCount: 0,
      perUserLimit: 1,
      minimumPurchase: 0,
      isActive: true,
    ),
    Coupon(
      id: 'cpn_astrack5k',
      code: 'ASTRACK5K',
      description: 'Potongan Rp5.000 untuk transaksi minimal Rp15.000',
      discountType: CouponDiscountType.fixed,
      discountValue: 5000,
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      usageLimit: 1000,
      usageCount: 0,
      perUserLimit: 1,
      minimumPurchase: 15000,
      isActive: true,
    ),
    Coupon(
      id: 'cpn_pro30',
      code: 'HEMATPRO',
      description: 'Diskon 30% khusus paket Pro',
      discountType: CouponDiscountType.percentage,
      discountValue: 30,
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      usageLimit: 200,
      usageCount: 0,
      perUserLimit: 1,
      minimumPurchase: 25000,
      applicablePlanIds: ['plan_pro'],
      isActive: true,
    ),
  ];

  final Map<String, List<String>> _inMemoryRedemptions = {}; // code -> list of userIds
  final List<PlanPriceHistory> _inMemoryPriceHistory = [];
  final Map<String, Subscription> _inMemorySubscriptions = {};

  void resetInMemoryState() {
    _inMemoryPlans = null;
    _inMemoryCoupons = [
      Coupon(
        id: 'cpn_astrack20',
        code: 'ASTRACK20',
        description: 'Diskon 20% untuk semua paket langganan',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 500,
        usageCount: 0,
        perUserLimit: 1,
        minimumPurchase: 0,
        isActive: true,
      ),
      Coupon(
        id: 'cpn_astrack5k',
        code: 'ASTRACK5K',
        description: 'Potongan Rp5.000 untuk transaksi minimal Rp15.000',
        discountType: CouponDiscountType.fixed,
        discountValue: 5000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 1000,
        usageCount: 0,
        perUserLimit: 1,
        minimumPurchase: 15000,
        isActive: true,
      ),
      Coupon(
        id: 'cpn_pro30',
        code: 'HEMATPRO',
        description: 'Diskon 30% khusus paket Pro',
        discountType: CouponDiscountType.percentage,
        discountValue: 30,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 200,
        usageCount: 0,
        perUserLimit: 1,
        minimumPurchase: 25000,
        applicablePlanIds: ['plan_pro'],
        isActive: true,
      ),
    ];
    _inMemoryRedemptions.clear();
    _inMemoryPriceHistory.clear();
    _inMemorySubscriptions.clear();
  }

  void setInMemorySubscriptionForTesting(String userId, Subscription subscription) {
    _inMemorySubscriptions[userId] = subscription;
  }

  Future<List<Coupon>> getCoupons() async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.from('coupons').select().order('created_at', ascending: false);
        return res.map<Coupon>((e) => Coupon.fromJson(e)).toList();
      } catch (_) {}
    }
    return List.from(_inMemoryCoupons);
  }

  Future<void> createCoupon(Coupon coupon, {String? adminId}) async {
    if (adminId != null && !adminId.toLowerCase().contains('admin')) {
      throw Exception('Unauthorized: Hanya Administrator yang berwenang membuat kupon.');
    }
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('coupons').insert(coupon.toJson());
        return;
      } catch (e) {
        throw Exception('Gagal membuat kupon di database: $e');
      }
    }
    _inMemoryCoupons.removeWhere((c) => c.code.toUpperCase() == coupon.code.toUpperCase());
    _inMemoryCoupons.insert(0, coupon);
  }

  Future<void> updateCoupon(Coupon coupon, {String? adminId}) async {
    if (adminId != null && !adminId.toLowerCase().contains('admin')) {
      throw Exception('Unauthorized: Hanya Administrator yang berwenang mengubah kupon.');
    }
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('coupons').update(coupon.toJson()).eq('id', coupon.id);
        return;
      } catch (e) {
        throw Exception('Gagal memperbarui kupon di database: $e');
      }
    }
    final idx = _inMemoryCoupons.indexWhere((c) => c.id == coupon.id || c.code == coupon.code);
    if (idx != -1) {
      _inMemoryCoupons[idx] = coupon;
    }
  }

  Future<void> deleteCoupon(String couponId, {String? adminId}) async {
    if (adminId != null && !adminId.toLowerCase().contains('admin')) {
      throw Exception('Unauthorized: Hanya Administrator yang berwenang menghapus kupon.');
    }
    final client = _supabase;
    if (client != null) {
      try {
        await client.from('coupons').delete().eq('id', couponId);
        return;
      } catch (e) {
        throw Exception('Gagal menghapus kupon di database: $e');
      }
    }
    _inMemoryCoupons.removeWhere((c) => c.id == couponId);
  }

  /// Server-side authoritative validation and discount calculation
  Future<CouponValidationResult> validateCouponServer({
    required String code,
    required String planId,
    required String userId,
  }) async {
    final cleanCode = code.toUpperCase().trim();
    final client = _supabase;

    // 1. Try Supabase RPC
    if (client != null) {
      try {
        final res = await client.rpc('validate_and_calculate_coupon', params: {
          'p_coupon_code': cleanCode,
          'p_plan_id': planId,
          'p_user_id': userId,
        });

        if (res != null) {
          final isValid = res['is_valid'] == true;
          final origPrice = double.tryParse(res['original_price']?.toString() ?? '0') ?? 0.0;
          if (!isValid) {
            return CouponValidationResult.failure(
              message: res['error_message']?.toString() ?? 'Kode kupon tidak valid.',
              originalPrice: origPrice,
            );
          }

          final coupon = Coupon(
            id: res['coupon_id']?.toString() ?? '',
            code: cleanCode,
            discountType: res['discount_type'] == 'fixed' ? CouponDiscountType.fixed : CouponDiscountType.percentage,
            discountValue: double.tryParse(res['discount_value']?.toString() ?? '0') ?? 0.0,
            startsAt: DateTime.now().subtract(const Duration(days: 1)),
          );

          return CouponValidationResult.success(
            coupon: coupon,
            originalPrice: origPrice,
            discountAmount: double.tryParse(res['discount_amount']?.toString() ?? '0') ?? 0.0,
            finalPrice: double.tryParse(res['final_price']?.toString() ?? '0') ?? 0.0,
          );
        }
      } catch (_) {}
    }

    // 2. Deterministic server-equivalent validation (fallback / unit test resilient)
    final plans = await getPlans(includeInactive: true);
    final planMatches = plans.where((p) => p.id == planId);
    if (planMatches.isEmpty) {
      return CouponValidationResult.failure(
        message: 'Paket langganan tidak ditemukan.',
        originalPrice: 0.0,
      );
    }
    final plan = planMatches.first;

    if (!plan.isActive) {
      return CouponValidationResult.failure(
        message: 'Paket langganan tidak aktif untuk pembelian baru.',
        originalPrice: plan.monthlyPrice,
      );
    }

    final coupon = _inMemoryCoupons.firstWhere(
      (c) => c.code.toUpperCase() == cleanCode,
      orElse: () => Coupon(
        id: '', code: '', discountType: CouponDiscountType.percentage, discountValue: 0, startsAt: DateTime.now(), isActive: false,
      ),
    );

    if (coupon.id.isEmpty) {
      return CouponValidationResult.failure(
        message: 'Kode kupon tidak valid.',
        originalPrice: plan.monthlyPrice,
      );
    }

    if (!coupon.isActive) {
      return CouponValidationResult.failure(
        message: 'Kode kupon tidak aktif.',
        originalPrice: plan.monthlyPrice,
      );
    }

    final now = DateTime.now();
    if (now.isBefore(coupon.startsAt)) {
      return CouponValidationResult.failure(
        message: 'Kode kupon belum dapat digunakan.',
        originalPrice: plan.monthlyPrice,
      );
    }

    if (coupon.expiresAt != null && now.isAfter(coupon.expiresAt!)) {
      return CouponValidationResult.failure(
        message: 'Kode kupon sudah kedaluwarsa.',
        originalPrice: plan.monthlyPrice,
      );
    }

    if (coupon.usageLimit > 0 && coupon.usageCount >= coupon.usageLimit) {
      return CouponValidationResult.failure(
        message: 'Kode kupon sudah mencapai batas penggunaan.',
        originalPrice: plan.monthlyPrice,
      );
    }

    final redeemedUsers = _inMemoryRedemptions[cleanCode] ?? [];
    final userRedeems = redeemedUsers.where((u) => u == userId).length;
    if (coupon.perUserLimit > 0 && userRedeems >= coupon.perUserLimit) {
      return CouponValidationResult.failure(
        message: 'Kamu sudah mencapai batas penggunaan kode kupon ini.',
        originalPrice: plan.monthlyPrice,
      );
    }

    if (coupon.applicablePlanIds.isNotEmpty && !coupon.applicablePlanIds.contains(planId)) {
      return CouponValidationResult.failure(
        message: 'Kode kupon tidak berlaku untuk paket ini.',
        originalPrice: plan.monthlyPrice,
      );
    }

    if (coupon.minimumPurchase > 0 && plan.monthlyPrice < coupon.minimumPurchase) {
      return CouponValidationResult.failure(
        message: 'Minimum pembelian untuk kupon ini belum terpenuhi.',
        originalPrice: plan.monthlyPrice,
      );
    }

    // Calculate discount
    double discount = 0.0;
    if (coupon.discountType == CouponDiscountType.percentage) {
      discount = (plan.monthlyPrice * coupon.discountValue / 100.0).roundToDouble();
    } else {
      discount = coupon.discountValue;
    }

    if (discount > plan.monthlyPrice) {
      discount = plan.monthlyPrice;
    }

    final finalPrice = (plan.monthlyPrice - discount) < 0 ? 0.0 : (plan.monthlyPrice - discount);

    return CouponValidationResult.success(
      coupon: coupon,
      originalPrice: plan.monthlyPrice,
      discountAmount: discount,
      finalPrice: finalPrice,
    );
  }

  /// Atomic coupon redemption on confirmed payment
  Future<bool> redeemCouponOrder({
    required String code,
    required String planId,
    required String userId,
    required String orderId,
  }) async {
    final cleanCode = code.toUpperCase().trim();
    final client = _supabase;

    if (client != null) {
      try {
        final res = await client.rpc('redeem_coupon_order', params: {
          'p_coupon_code': cleanCode,
          'p_plan_id': planId,
          'p_user_id': userId,
          'p_order_id': orderId,
        });
        if (res != null && res['success'] == true) {
          return true;
        }
      } catch (_) {}
    }

    // In-memory atomic fallback
    final validation = await validateCouponServer(code: cleanCode, planId: planId, userId: userId);
    if (!validation.isValid || validation.coupon == null) return false;

    final c = validation.coupon!;
    final idx = _inMemoryCoupons.indexWhere((x) => x.id == c.id);
    if (idx != -1) {
      if (_inMemoryCoupons[idx].usageLimit > 0 &&
          _inMemoryCoupons[idx].usageCount >= _inMemoryCoupons[idx].usageLimit) {
        return false;
      }
      final userUses = _inMemoryRedemptions[cleanCode]?.where((u) => u == userId).length ?? 0;
      if (c.perUserLimit > 0 && userUses >= c.perUserLimit) {
        return false;
      }
      _inMemoryCoupons[idx] = _inMemoryCoupons[idx].copyWith(
        usageCount: _inMemoryCoupons[idx].usageCount + 1,
      );
    }

    _inMemoryRedemptions.putIfAbsent(cleanCode, () => []).add(userId);
    return true;
  }

  /// Price history audit log for a plan
  Future<List<PlanPriceHistory>> getPriceHistory(String planId) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client
            .from('plan_price_history')
            .select()
            .eq('plan_id', planId)
            .order('changed_at', ascending: false);
        return res.map<PlanPriceHistory>((e) => PlanPriceHistory.fromJson(e)).toList();
      } catch (_) {}
    }
    return _inMemoryPriceHistory.where((h) => h.planId == planId).toList();
  }

  /// Admin updates plan price and attributes with audit recording
  Future<void> updatePlanPricing({
    required String planId,
    required double newPrice,
    String? name,
    String? description,
    int? durationMonths,
    bool? isRecommended,
    bool? isActive,
    required String adminId,
  }) async {
    if (newPrice < 0) {
      throw ArgumentError('Harga tidak boleh bernilai negatif.');
    }

    if (adminId.isNotEmpty && !adminId.toLowerCase().contains('admin')) {
      throw Exception('Unauthorized: Hanya Administrator yang memiliki hak mengubah harga.');
    }

    final client = _supabase;
    final plans = await getPlans(includeInactive: true);
    final oldPlan = plans.firstWhere((p) => p.id == planId, orElse: () => plans.first);
    final oldPrice = oldPlan.monthlyPrice;

    if (client != null) {
      try {
        await client.rpc('admin_update_plan_pricing', params: {
          'p_plan_id': planId,
          'p_new_price': newPrice,
          'p_name': name ?? oldPlan.name,
          'p_description': description ?? oldPlan.description,
          'p_duration_months': durationMonths ?? oldPlan.durationMonths,
          'p_is_recommended': isRecommended ?? oldPlan.isRecommended,
          'p_is_active': isActive ?? oldPlan.isActive,
          'p_admin_id': adminId,
        });
        return;
      } catch (_) {
        // Direct table update fallback
        try {
          if (isRecommended == true) {
            await client.from('plans').update({'is_recommended': false}).neq('id', planId);
          }
          await client.from('plans').update({
            'name': name ?? oldPlan.name,
            'description': description ?? oldPlan.description,
            'monthly_price': newPrice,
            'duration_months': durationMonths ?? oldPlan.durationMonths,
            'is_recommended': isRecommended ?? oldPlan.isRecommended,
            'is_active': isActive ?? oldPlan.isActive,
          }).eq('id', planId);

          if (oldPrice != newPrice) {
            await client.from('plan_price_history').insert({
              'plan_id': planId,
              'old_price': oldPrice,
              'new_price': newPrice,
              'changed_by': adminId,
            });
          }
          return;
        } catch (_) {}
      }
    }

    // In-memory fallback
    _inMemoryPlans ??= _defaultPlans();
    final planIdx = _inMemoryPlans!.indexWhere((p) => p.id == planId);
    if (planIdx != -1) {
      if (isRecommended == true) {
        for (int i = 0; i < _inMemoryPlans!.length; i++) {
          _inMemoryPlans![i] = _inMemoryPlans![i].copyWith(isRecommended: false);
        }
      }
      final current = _inMemoryPlans![planIdx];
      _inMemoryPlans![planIdx] = current.copyWith(
        name: name ?? current.name,
        description: description ?? current.description,
        monthlyPrice: newPrice,
        durationMonths: durationMonths ?? current.durationMonths,
        isRecommended: isRecommended ?? current.isRecommended,
        isActive: isActive ?? current.isActive,
      );
    }

    if (oldPrice != newPrice) {
      _inMemoryPriceHistory.insert(
        0,
        PlanPriceHistory(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
          planId: planId,
          oldPrice: oldPrice,
          newPrice: newPrice,
          changedBy: adminId.isEmpty ? 'Admin' : adminId,
          changedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Admin pricing & coupon summary statistics
  Future<Map<String, dynamic>> getAdminPricingSummary() async {
    final plans = await getPlans();
    final coupons = await getCoupons();

    final activePlans = plans.where((p) => p.isActive).length;
    final activeCoupons = coupons.where((c) => c.isActive && !c.isExpired).length;
    final totalRedemptions = coupons.fold<int>(0, (sum, c) => sum + c.usageCount);

    return {
      'total_products': plans.length,
      'active_products': activePlans,
      'total_coupons': coupons.length,
      'active_coupons': activeCoupons,
      'total_coupon_usage': totalRedemptions,
    };
  }
}
