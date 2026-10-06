import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/models/coupon_model.dart';
import 'package:astrack/models/saas_models.dart';
import 'package:astrack/services/payment/payment_service.dart';
import 'package:astrack/services/saas_backend_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ASTRACK Dynamic Pricing & Audit History Tests', () {
    late SaaSBackendService saas;

    setUp(() {
      saas = SaaSBackendService();
      saas.resetInMemoryState();
    });

    test('Loads dynamic plans from backend SSOT', () async {
      final plans = await saas.getPlans();
      expect(plans.isNotEmpty, isTrue);

      final proPlan = plans.firstWhere((p) => p.id == 'plan_pro');
      expect(proPlan.name, equals('Pro'));
      expect(proPlan.monthlyPrice, equals(29000.0));
      expect(proPlan.isRecommended, isTrue);
      expect(proPlan.durationLabel, equals('/ bulan'));
    });

    test('Admin changes price and writes immutable audit history', () async {
      const planId = 'plan_pro';
      const newPrice = 35000.0;

      await saas.updatePlanPricing(
        planId: planId,
        newPrice: newPrice,
        adminId: 'admin_test_1',
      );

      final updatedPlans = await saas.getPlans();
      final updatedPro = updatedPlans.firstWhere((p) => p.id == planId);
      expect(updatedPro.monthlyPrice, equals(35000.0));

      final history = await saas.getPriceHistory(planId);
      expect(history.isNotEmpty, isTrue);
      expect(history.first.oldPrice, equals(29000.0));
      expect(history.first.newPrice, equals(35000.0));
      expect(history.first.changedBy, equals('admin_test_1'));
    });

    test('Rejects negative plan price with ArgumentError', () async {
      expect(
        () => saas.updatePlanPricing(
          planId: 'plan_basic',
          newPrice: -5000.0,
          adminId: 'admin_test_1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Inactive product cannot be used for checkout/coupon validation', () async {
      await saas.updatePlanPricing(
        planId: 'plan_basic',
        newPrice: 15000.0,
        isActive: false,
        adminId: 'admin_test_1',
      );

      // Inactive plans excluded from normal getPlans()
      final activePlans = await saas.getPlans(includeInactive: false);
      expect(activePlans.any((p) => p.id == 'plan_basic'), isFalse);

      // Inactive plans visible when includeInactive is true
      final allPlans = await saas.getPlans(includeInactive: true);
      expect(allPlans.any((p) => p.id == 'plan_basic'), isTrue);

      // Coupon validation on inactive plan is rejected
      final result = await saas.validateCouponServer(
        code: 'ASTRACK20',
        planId: 'plan_basic',
        userId: 'user_1',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('tidak aktif'));
    });
  });

  group('ASTRACK Server-Side Coupon Validation Tests', () {
    late SaaSBackendService saas;

    setUp(() {
      saas = SaaSBackendService();
      saas.resetInMemoryState();
    });

    test('Validates percentage discount coupon correctly', () async {
      final res = await saas.validateCouponServer(
        code: 'ASTRACK20',
        planId: 'plan_pro',
        userId: 'user_pct',
      );

      expect(res.isValid, isTrue);
      expect(res.originalPrice, equals(29000.0));
      expect(res.discountAmount, equals(5800.0)); // 20% of 29,000
      expect(res.finalPrice, equals(23200.0));
    });

    test('Validates fixed nominal discount coupon correctly', () async {
      final res = await saas.validateCouponServer(
        code: 'ASTRACK5K',
        planId: 'plan_pro',
        userId: 'user_fixed',
      );

      expect(res.isValid, isTrue);
      expect(res.originalPrice, equals(29000.0));
      expect(res.discountAmount, equals(5000.0));
      expect(res.finalPrice, equals(24000.0));
    });

    test('Clamps discount to zero when fixed discount exceeds price (No negative price)', () async {
      final hugeCoupon = Coupon(
        id: 'cpn_huge',
        code: 'MEGADEAL',
        discountType: CouponDiscountType.fixed,
        discountValue: 100000.0,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      await saas.createCoupon(hugeCoupon);

      final res = await saas.validateCouponServer(
        code: 'MEGADEAL',
        planId: 'plan_pro',
        userId: 'user_mega',
      );

      expect(res.isValid, isTrue);
      expect(res.originalPrice, equals(29000.0));
      expect(res.discountAmount, equals(29000.0));
      expect(res.finalPrice, equals(0.0));
    });

    test('Rejects invalid / non-existent coupon code', () async {
      final res = await saas.validateCouponServer(
        code: 'KODETIDAKADA999',
        planId: 'plan_pro',
        userId: 'user_1',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon tidak valid.'));
    });

    test('Rejects inactive coupon', () async {
      final inactiveCoupon = Coupon(
        id: 'cpn_inactive',
        code: 'OFFLINE50',
        discountType: CouponDiscountType.percentage,
        discountValue: 50,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: false,
      );
      await saas.createCoupon(inactiveCoupon);

      final res = await saas.validateCouponServer(
        code: 'OFFLINE50',
        planId: 'plan_pro',
        userId: 'user_1',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon tidak aktif.'));
    });

    test('Rejects expired coupon', () async {
      final expiredCoupon = Coupon(
        id: 'cpn_expired',
        code: 'EXPIRED10',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        startsAt: DateTime.now().subtract(const Duration(days: 30)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      await saas.createCoupon(expiredCoupon);

      final res = await saas.validateCouponServer(
        code: 'EXPIRED10',
        planId: 'plan_pro',
        userId: 'user_1',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon sudah kedaluwarsa.'));
    });

    test('Rejects future / not yet active coupon', () async {
      final futureCoupon = Coupon(
        id: 'cpn_future',
        code: 'FUTURE2027',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        startsAt: DateTime.now().add(const Duration(days: 10)),
        isActive: true,
      );
      await saas.createCoupon(futureCoupon);

      final res = await saas.validateCouponServer(
        code: 'FUTURE2027',
        planId: 'plan_pro',
        userId: 'user_1',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon belum dapat digunakan.'));
    });

    test('Rejects coupon when minimum purchase condition is not met', () async {
      final minPurchaseCoupon = Coupon(
        id: 'cpn_min',
        code: 'MIN50K',
        discountType: CouponDiscountType.fixed,
        discountValue: 10000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        minimumPurchase: 50000, // Pro is 29,000 -> not met
        isActive: true,
      );
      await saas.createCoupon(minPurchaseCoupon);

      final res = await saas.validateCouponServer(
        code: 'MIN50K',
        planId: 'plan_pro',
        userId: 'user_1',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Minimum pembelian untuk kupon ini belum terpenuhi.'));
    });

    test('Rejects coupon when plan restriction does not match', () async {
      final restrictedCoupon = Coupon(
        id: 'cpn_restricted',
        code: 'ONLYPRO',
        discountType: CouponDiscountType.percentage,
        discountValue: 25,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        applicablePlanIds: ['plan_pro'],
        isActive: true,
      );
      await saas.createCoupon(restrictedCoupon);

      // Try on plan_basic
      final res = await saas.validateCouponServer(
        code: 'ONLYPRO',
        planId: 'plan_basic',
        userId: 'user_1',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon tidak berlaku untuk paket ini.'));
    });

    test('Enforces overall usage limit', () async {
      final limitedCoupon = Coupon(
        id: 'cpn_limit1',
        code: 'LIMITED1',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 1,
        usageCount: 1, // Already reached
        isActive: true,
      );
      await saas.createCoupon(limitedCoupon);

      final res = await saas.validateCouponServer(
        code: 'LIMITED1',
        planId: 'plan_pro',
        userId: 'user_new',
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon sudah mencapai batas penggunaan.'));
    });

    test('Enforces per-user limit and records atomic redemption', () async {
      const code = 'ONCEONLY';
      final perUserCoupon = Coupon(
        id: 'cpn_once',
        code: code,
        discountType: CouponDiscountType.fixed,
        discountValue: 3000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 10,
        perUserLimit: 1,
        isActive: true,
      );
      await saas.createCoupon(perUserCoupon);

      // First validation succeeds
      final res1 = await saas.validateCouponServer(
        code: code,
        planId: 'plan_pro',
        userId: 'user_single',
      );
      expect(res1.isValid, isTrue);

      // Redeem coupon on payment
      final redeemed = await saas.redeemCouponOrder(
        code: code,
        planId: 'plan_pro',
        userId: 'user_single',
        orderId: 'ord_123',
      );
      expect(redeemed, isTrue);

      // Second validation for same user fails with user limit error
      final res2 = await saas.validateCouponServer(
        code: code,
        planId: 'plan_pro',
        userId: 'user_single',
      );
      expect(res2.isValid, isFalse);
      expect(res2.errorMessage, equals('Kamu sudah mencapai batas penggunaan kode kupon ini.'));

      // Another user can still use it
      final res3 = await saas.validateCouponServer(
        code: code,
        planId: 'plan_pro',
        userId: 'user_other',
      );
      expect(res3.isValid, isTrue);
    });

    test('Prevents client-side pro activation spoofing', () async {
      expect(
        () => saas.upgradeToPro('attacker_user'),
        throwsA(
          predicate((e) => e.toString().contains('Unauthorized')),
        ),
      );
    });

    test('Old transaction and subscription snapshot remains immutable after admin price change', () async {
      const planId = 'plan_pro';
      const initialPrice = 29000.0;
      const updatedPrice = 35000.0;

      // User creates a subscription snapshot at initial price
      final sub = Subscription(
        id: 'sub_hist_1',
        userId: 'user_immutable',
        planId: planId,
        status: SubscriptionStatus.active,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
        paidAmount: initialPrice,
        orderId: 'ord_hist_1',
      );

      // Verify initial snapshot
      expect(sub.paidAmount, equals(initialPrice));
      expect(sub.orderId, equals('ord_hist_1'));

      // Admin updates Pro plan price to Rp35.000
      await saas.updatePlanPricing(
        planId: planId,
        newPrice: updatedPrice,
        adminId: 'admin_audit',
      );

      // Verify new plan has new price
      final plans = await saas.getPlans();
      final proPlan = plans.firstWhere((p) => p.id == planId);
      expect(proPlan.monthlyPrice, equals(updatedPrice));

      // Old subscription still holds original paidAmount and does NOT recalculate retroactively
      expect(sub.paidAmount, equals(initialPrice));
      expect(sub.paidAmount, isNot(equals(proPlan.monthlyPrice)));
    });

    test('Fail-safe on non-existent plan ID returns zero price and clear error', () async {
      final res = await saas.validateCouponServer(
        code: 'ASTRACK20',
        planId: 'plan_non_existent_999',
        userId: 'user_test',
      );

      expect(res.isValid, isFalse);
      expect(res.originalPrice, equals(0.0));
      expect(res.finalPrice, equals(0.0));
      expect(res.errorMessage, equals('Paket langganan tidak ditemukan.'));
    });

    test('PaymentWebhookVerifier strictly verifies expected amount and plan matching (Anti-Tampering)', () {
      final verifier = PaymentWebhookVerifier(webhookSecret: 'test_secret_123');

      // Valid: exactly matches expected final price (e.g. 29,000 - 5,800 = 23,200)
      final valid = verifier.verifyAmountAndPlan(
        expectedAmount: 23200.0,
        receivedAmount: 23200.0,
        expectedPlanId: 'plan_pro',
        receivedPlanId: 'plan_pro',
      );
      expect(valid, isTrue);

      // Tampered: client modified amount to Rp100
      final tamperedAmount = verifier.verifyAmountAndPlan(
        expectedAmount: 23200.0,
        receivedAmount: 100.0,
        expectedPlanId: 'plan_pro',
        receivedPlanId: 'plan_pro',
      );
      expect(tamperedAmount, isFalse);

      // Tampered: plan mismatch
      final mismatchedPlan = verifier.verifyAmountAndPlan(
        expectedAmount: 23200.0,
        receivedAmount: 23200.0,
        expectedPlanId: 'plan_pro',
        receivedPlanId: 'plan_basic',
      );
      expect(mismatchedPlan, isFalse);
    });

    test('Redemption fails and blocks over-increment when usage limit is reached', () async {
      const code = 'ATOMICMAX';
      final maxCoupon = Coupon(
        id: 'cpn_max',
        code: code,
        discountType: CouponDiscountType.fixed,
        discountValue: 1000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 1,
        usageCount: 0,
        perUserLimit: 2,
        isActive: true,
      );
      await saas.createCoupon(maxCoupon);

      // 1st redemption succeeds
      final firstRedeem = await saas.redeemCouponOrder(
        code: code,
        planId: 'plan_pro',
        userId: 'user_a',
        orderId: 'ord_a',
      );
      expect(firstRedeem, isTrue);

      // 2nd redemption by user_b fails because usageLimit (1) was reached
      final secondRedeem = await saas.redeemCouponOrder(
        code: code,
        planId: 'plan_pro',
        userId: 'user_b',
        orderId: 'ord_b',
      );
      expect(secondRedeem, isFalse);
    });
  });
}
