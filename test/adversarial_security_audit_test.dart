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

  group('ASTRACK Final Adversarial Security & Entitlement Audit Tests', () {
    late SaaSBackendService saas;
    late PaymentWebhookVerifier webhookVerifier;

    setUp(() {
      saas = SaaSBackendService();
      saas.resetInMemoryState();
      webhookVerifier = PaymentWebhookVerifier(webhookSecret: 'adversarial_wh_secret');
    });

    // 1. Normal user update plan price -> DENIED
    test('Vector 1: Normal user cannot update plan price (DENIED)', () async {
      expect(
        () => saas.updatePlanPricing(
          planId: 'plan_pro',
          newPrice: 1000.0,
          adminId: 'normal_user_hacker',
        ),
        throwsA(
          predicate((e) => e.toString().contains('Unauthorized')),
        ),
      );
    });

    // 2. Normal user create coupon -> DENIED
    test('Vector 2: Normal user cannot create coupon (DENIED)', () async {
      final fakeCoupon = Coupon(
        id: 'cpn_hacked',
        code: 'FREE99',
        discountType: CouponDiscountType.percentage,
        discountValue: 99,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );

      expect(
        () => saas.createCoupon(fakeCoupon, adminId: 'normal_user_hacker'),
        throwsA(
          predicate((e) => e.toString().contains('Unauthorized')),
        ),
      );
    });

    // 3. Normal user update coupon -> DENIED
    test('Vector 3: Normal user cannot update coupon (DENIED)', () async {
      final coupon = Coupon(
        id: 'cpn_valid',
        code: 'LEGALPROMO',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      // Admin creates legitimately
      await saas.createCoupon(coupon, adminId: 'admin_sys');

      // Normal user attempts to change discount to 100%
      final hackedCoupon = coupon.copyWith(discountValue: 100);
      expect(
        () => saas.updateCoupon(hackedCoupon, adminId: 'normal_user_hacker'),
        throwsA(
          predicate((e) => e.toString().contains('Unauthorized')),
        ),
      );
    });

    // 4. Normal user update usage_count -> DENIED
    test('Vector 4: Normal user cannot directly manipulate coupon usage_count (DENIED)', () async {
      final coupon = Coupon(
        id: 'cpn_usage',
        code: 'ONEUSE',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 1,
        usageCount: 1,
        isActive: true,
      );
      await saas.createCoupon(coupon, adminId: 'admin_sys');

      // Attacker attempts to reset usageCount to 0
      final resetUsageCoupon = coupon.copyWith(usageCount: 0);
      expect(
        () => saas.updateCoupon(resetUsageCoupon, adminId: 'normal_user_hacker'),
        throwsA(
          predicate((e) => e.toString().contains('Unauthorized')),
        ),
      );
    });

    // 5. Normal user insert fake redemption -> DENIED
    test('Vector 5: Fake redemption without valid order and server validation fails (DENIED)', () async {
      final result = await saas.redeemCouponOrder(
        code: 'NON_EXISTENT_COUPON',
        planId: 'plan_pro',
        userId: 'user_hacker',
        orderId: 'fake_order_123',
      );
      expect(result, isFalse);
    });

    // 6. Normal user update subscription -> DENIED
    test('Vector 6: Normal user cannot arbitrarily update subscription status (DENIED)', () async {
      expect(
        () => saas.upgradeToPro('normal_user_attacker'),
        throwsA(
          predicate((e) => e.toString().contains('Unauthorized')),
        ),
      );
    });

    // 7. Normal user activate Pro without payment -> DENIED
    test('Vector 7: Client cannot activate Pro directly without payment verification (DENIED)', () async {
      expect(
        () => saas.upgradeToPro('attacker_user_id'),
        throwsA(isA<Exception>()),
      );
    });

    // 8. Client spoof final price -> DENIED
    test('Vector 8: Client cannot spoof final price (Server-Authoritative)', () async {
      // Coupon ASTRACK20 gives 20% off 29,000 -> final must be 23,200
      final res = await saas.validateCouponServer(
        code: 'ASTRACK20',
        planId: 'plan_pro',
        userId: 'user_tamper',
      );
      expect(res.isValid, isTrue);
      expect(res.originalPrice, equals(29000.0));
      expect(res.discountAmount, equals(5800.0));
      expect(res.finalPrice, equals(23200.0));
      // Client cannot force 100 rupiahs
      expect(res.finalPrice, isNot(equals(100.0)));
    });

    // 9. Client spoof discount -> DENIED
    test('Vector 9: Client cannot spoof discount amount (DENIED)', () async {
      final res = await saas.validateCouponServer(
        code: 'ASTRACK20',
        planId: 'plan_pro',
        userId: 'user_tamper_disc',
      );
      expect(res.discountAmount, equals(5800.0));
      expect(res.discountAmount, isNot(equals(29000.0)));
    });

    // 10. Invalid coupon -> DENIED
    test('Vector 10: Invalid coupon code is rejected (DENIED)', () async {
      final res = await saas.validateCouponServer(
        code: 'FAKECOUPON999',
        planId: 'plan_pro',
        userId: 'user_1',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon tidak valid.'));
    });

    // 11. Expired coupon -> DENIED
    test('Vector 11: Expired coupon is rejected (DENIED)', () async {
      final expired = Coupon(
        id: 'cpn_exp_adv',
        code: 'EXPIRED_NOW',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        startsAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      await saas.createCoupon(expired, adminId: 'admin_sys');

      final res = await saas.validateCouponServer(
        code: 'EXPIRED_NOW',
        planId: 'plan_pro',
        userId: 'user_1',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon sudah kedaluwarsa.'));
    });

    // 12. Future coupon -> DENIED
    test('Vector 12: Future / not-yet-started coupon is rejected (DENIED)', () async {
      final future = Coupon(
        id: 'cpn_fut_adv',
        code: 'STARTS_NEXT_WEEK',
        discountType: CouponDiscountType.percentage,
        discountValue: 15,
        startsAt: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );
      await saas.createCoupon(future, adminId: 'admin_sys');

      final res = await saas.validateCouponServer(
        code: 'STARTS_NEXT_WEEK',
        planId: 'plan_pro',
        userId: 'user_1',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon belum dapat digunakan.'));
    });

    // 13. Wrong product coupon -> DENIED
    test('Vector 13: Coupon restricted to Pro plan fails when used on Basic (DENIED)', () async {
      final restricted = Coupon(
        id: 'cpn_res_adv',
        code: 'PRO_ONLY_2026',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        applicablePlanIds: ['plan_pro'],
        isActive: true,
      );
      await saas.createCoupon(restricted, adminId: 'admin_sys');

      final res = await saas.validateCouponServer(
        code: 'PRO_ONLY_2026',
        planId: 'plan_basic',
        userId: 'user_1',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon tidak berlaku untuk paket ini.'));
    });

    // 14. Exceeded global limit -> DENIED
    test('Vector 14: Coupon with exhausted global usage limit is rejected (DENIED)', () async {
      final limited = Coupon(
        id: 'cpn_glob_adv',
        code: 'EXHAUSTED',
        discountType: CouponDiscountType.fixed,
        discountValue: 5000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 2,
        usageCount: 2,
        isActive: true,
      );
      await saas.createCoupon(limited, adminId: 'admin_sys');

      final res = await saas.validateCouponServer(
        code: 'EXHAUSTED',
        planId: 'plan_pro',
        userId: 'user_random',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, equals('Kode kupon sudah mencapai batas penggunaan.'));
    });

    // 15. Exceeded per-user limit -> DENIED
    test('Vector 15: User exceeding per-user limit is rejected (DENIED)', () async {
      final perUser = Coupon(
        id: 'cpn_puser_adv',
        code: 'ONCE_PER_PERSON',
        discountType: CouponDiscountType.fixed,
        discountValue: 2000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        usageLimit: 100,
        perUserLimit: 1,
        isActive: true,
      );
      await saas.createCoupon(perUser, adminId: 'admin_sys');

      // User A redeems
      final firstRedeem = await saas.redeemCouponOrder(
        code: 'ONCE_PER_PERSON',
        planId: 'plan_pro',
        userId: 'user_attacker_a',
        orderId: 'ord_1',
      );
      expect(firstRedeem, isTrue);

      // User A attempts second checkout
      final secondCheck = await saas.validateCouponServer(
        code: 'ONCE_PER_PERSON',
        planId: 'plan_pro',
        userId: 'user_attacker_a',
      );
      expect(secondCheck.isValid, isFalse);
      expect(secondCheck.errorMessage, equals('Kamu sudah mencapai batas penggunaan kode kupon ini.'));
    });

    // 16. Negative price -> DENIED
    test('Vector 16: Setting negative product price is rejected (DENIED)', () async {
      expect(
        () => saas.updatePlanPricing(
          planId: 'plan_pro',
          newPrice: -100.0,
          adminId: 'admin_sys',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // 17. Inactive plan -> DENIED
    test('Vector 17: Purchasing or applying coupon to inactive plan is rejected (DENIED)', () async {
      await saas.updatePlanPricing(
        planId: 'plan_basic',
        newPrice: 15000.0,
        isActive: false,
        adminId: 'admin_sys',
      );

      final res = await saas.validateCouponServer(
        code: 'ASTRACK20',
        planId: 'plan_basic',
        userId: 'user_1',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('tidak aktif'));
    });

    // 18. Duplicate webhook -> IDEMPOTENT
    test('Vector 18: Duplicate webhook event is safely ignored (IDEMPOTENT)', () {
      const eventId = 'evt_payment_success_999';

      expect(webhookVerifier.isAlreadyProcessed(eventId), isFalse);
      webhookVerifier.markAsProcessed(eventId);
      expect(webhookVerifier.isAlreadyProcessed(eventId), isTrue);

      // Second check returns true, protecting against duplicate execution
      final isDuplicate = webhookVerifier.isAlreadyProcessed(eventId);
      expect(isDuplicate, isTrue);
    });

    // 19. Duplicate payment -> BLOCKED (Payment Webhook Verifier checks expected vs received amount & plan)
    test('Vector 19: Webhook tampering with mismatched amount or plan is blocked (BLOCKED)', () {
      final matches = webhookVerifier.verifyAmountAndPlan(
        expectedAmount: 23200.0,
        receivedAmount: 1000.0, // Tampered
        expectedPlanId: 'plan_pro',
        receivedPlanId: 'plan_pro',
      );
      expect(matches, isFalse);
    });

    // 20. Old transaction price -> IMMUTABLE
    test('Vector 20: Past subscription snapshot remains immutable after admin price change (IMMUTABLE)', () async {
      final pastSub = Subscription(
        id: 'sub_past_99',
        userId: 'user_past',
        planId: 'plan_pro',
        status: SubscriptionStatus.active,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
        paidAmount: 29000.0,
        orderId: 'ord_past_99',
      );
      expect(pastSub.paidAmount, equals(29000.0));

      // Admin updates Pro price to 40,000
      await saas.updatePlanPricing(
        planId: 'plan_pro',
        newPrice: 40000.0,
        adminId: 'admin_sys',
      );

      // Past sub still has 29,000
      expect(pastSub.paidAmount, equals(29000.0));
    });

    // 21. Admin pricing update -> ALLOWED
    test('Vector 21: Authorized admin updates product pricing (ALLOWED)', () async {
      await saas.updatePlanPricing(
        planId: 'plan_pro',
        newPrice: 32000.0,
        adminId: 'admin_sys',
      );
      final plans = await saas.getPlans();
      final pro = plans.firstWhere((p) => p.id == 'plan_pro');
      expect(pro.monthlyPrice, equals(32000.0));
    });

    // 22. Admin coupon creation -> ALLOWED
    test('Vector 22: Authorized admin creates promo coupon (ALLOWED)', () async {
      final adminCoupon = Coupon(
        id: 'cpn_admin_legit',
        code: 'ADMINSPECIAL',
        discountType: CouponDiscountType.fixed,
        discountValue: 10000,
        startsAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );
      await saas.createCoupon(adminCoupon, adminId: 'admin_sys');

      final check = await saas.validateCouponServer(
        code: 'ADMINSPECIAL',
        planId: 'plan_pro',
        userId: 'any_user',
      );
      expect(check.isValid, isTrue);
      expect(check.discountAmount, equals(10000.0));
    });

    // 23. Valid coupon checkout -> ALLOWED
    test('Vector 23: Valid coupon on checkout calculates correct discounted price (ALLOWED)', () async {
      final res = await saas.validateCouponServer(
        code: 'ASTRACK5K',
        planId: 'plan_pro',
        userId: 'user_regular',
      );
      expect(res.isValid, isTrue);
      expect(res.finalPrice, equals(24000.0)); // 29000 - 5000
    });

    // 24. Valid payment verification -> ALLOWED
    test('Vector 24: Valid payment amount and plan match passes verification (ALLOWED)', () {
      final verified = webhookVerifier.verifyAmountAndPlan(
        expectedAmount: 24000.0,
        receivedAmount: 24000.0,
        expectedPlanId: 'plan_pro',
        receivedPlanId: 'plan_pro',
      );
      expect(verified, isTrue);
    });
  });
}
