// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  final isConfigured = supabaseUrl.isNotEmpty && anonKey.isNotEmpty;

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  group(
    'ASTRACK Supabase Cloud Live Runtime Probe',
    skip: !isConfigured
        ? 'Live probe skipped: SUPABASE_URL and SUPABASE_ANON_KEY not set via --dart-define'
        : null,
    () {
      test('1. Supabase Cloud Connection & Plans Query (LIVE RUNTIME)', () async {
      final res = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/plans?select=*'),
        headers: headers,
      );

      expect(res.statusCode, equals(200));
      final List data = jsonDecode(res.body);
      expect(data.isNotEmpty, isTrue);

      final pro = data.firstWhere((p) => p['id'] == 'plan_pro');
      expect(pro['name'], equals('Pro'));
      expect(pro['monthly_price'], equals(29000));
      print('LIVE CLOUD: plans table verified. Pro plan monthly_price = ${pro['monthly_price']}');
    });

    test('2. RLS Security: Normal/Anon user CANNOT update plan price (LIVE RUNTIME)', () async {
      final res = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/plans?id=eq.plan_pro'),
        headers: headers,
        body: jsonEncode({'monthly_price': 100}),
      );

      // Under PostgreSQL RLS with no update policy for anon/user:
      // PostgREST returns 200 with empty list [] (0 rows updated) or 401/403.
      if (res.statusCode == 200) {
        final List updatedRows = jsonDecode(res.body);
        expect(updatedRows.isEmpty, isTrue, reason: 'RLS must block update, returning 0 affected rows');
      } else {
        expect(res.statusCode, anyOf([401, 403, 404]));
      }

      // Re-verify that price in database is still 29000
      final checkRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/plans?id=eq.plan_pro&select=monthly_price'),
        headers: headers,
      );
      final checkData = jsonDecode(checkRes.body);
      expect(checkData.first['monthly_price'], equals(29000));
      print('LIVE CLOUD: RLS successfully blocked price update attack on plan_pro.');
    });

    test('3. RLS Security: Normal/Anon user CANNOT insert new plan (LIVE RUNTIME)', () async {
      final res = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/plans'),
        headers: headers,
        body: jsonEncode({
          'id': 'plan_hacked_999',
          'name': 'Hacked Plan',
          'monthly_price': 1,
          'duration_months': 1,
          'is_active': true,
        }),
      );

      // PostgREST returns 401 Unauthorized or 403 Forbidden or 201 with empty representation
      expect(res.statusCode, anyOf([400, 401, 403]));
      print('LIVE CLOUD: RLS successfully blocked plan insertion attack (status: ${res.statusCode}).');
    });

    test('4. RLS Security: Normal/Anon user CANNOT insert fake subscription directly (LIVE RUNTIME)', () async {
      final res = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/subscriptions'),
        headers: headers,
        body: jsonEncode({
          'user_id': '00000000-0000-0000-0000-000000000001',
          'plan_id': 'plan_pro',
          'status': 'active',
        }),
      );

      expect(res.statusCode, anyOf([400, 401, 403]));
      print('LIVE CLOUD: RLS successfully blocked fake subscription insertion (status: ${res.statusCode}).');
    });

    test('5. Schema Audit: Verify table deployment status on Supabase Cloud', () async {
      // 5.1 plan_price_history
      final historyRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/plan_price_history?select=*'),
        headers: headers,
      );
      print('LIVE CLOUD: plan_price_history status = ${historyRes.statusCode}');

      // 5.2 coupons
      final couponsRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/coupons?select=*'),
        headers: headers,
      );
      print('LIVE CLOUD: coupons status = ${couponsRes.statusCode}, body = ${couponsRes.body}');

      // 5.3 coupon_redemptions
      final redemptionsRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/coupon_redemptions?select=*'),
        headers: headers,
      );
      print('LIVE CLOUD: coupon_redemptions status = ${redemptionsRes.statusCode}');

      // 5.4 payment_webhook_events
      final webhookRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events?select=*'),
        headers: headers,
      );
      print('LIVE CLOUD: payment_webhook_events status = ${webhookRes.statusCode}');

      // 5.5 subscriptions
      final subRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/subscriptions?select=user_id,plan_id'),
        headers: headers,
      );
      expect(subRes.statusCode, equals(200));

      // 5.6 subscriptions snapshot columns (paid_amount, order_id)
      final subSnapshotRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/subscriptions?select=paid_amount,order_id'),
        headers: headers,
      );
      print('LIVE CLOUD: subscriptions snapshot columns status = ${subSnapshotRes.statusCode}, body = ${subSnapshotRes.body}');

      // 6.1 RPC validate_and_calculate_coupon
      final rpcValRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/validate_and_calculate_coupon'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'ASTRACK20',
          'p_plan_id': 'plan_pro',
          'p_user_id': null,
        }),
      );
      print('LIVE CLOUD: RPC validate_and_calculate_coupon status = ${rpcValRes.statusCode}, body = ${rpcValRes.body}');

      // 6.2 RPC redeem_coupon_order
      final rpcRedeemRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/redeem_coupon_order'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'ASTRACK20',
          'p_plan_id': 'plan_pro',
          'p_user_id': null,
          'p_order_id': 'TEST-ORDER-1'
        }),
      );
      print('LIVE CLOUD: RPC redeem_coupon_order status = ${rpcRedeemRes.statusCode}, body = ${rpcRedeemRes.body}');

      // 6.3 RPC admin_update_plan_pricing
      final rpcPricingRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/admin_update_plan_pricing'),
        headers: headers,
        body: jsonEncode({
          'p_plan_id': 'plan_pro',
          'p_new_price': 35000,
          'p_name': 'Pro Updated',
          'p_description': 'Updated',
          'p_duration_months': 1,
          'p_is_recommended': true,
          'p_is_active': true,
          'p_admin_id': null,
        }),
      );
      print('LIVE CLOUD: RPC admin_update_plan_pricing status = ${rpcPricingRes.statusCode}, body = ${rpcPricingRes.body}');
    });

    test('6. Live Coupon Validation: Matrix of valid, invalid, and minimum purchase tests (LIVE CLOUD)', () async {
      // 6.1 Valid coupon ASTRACK20 on plan_pro
      final valValidRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/validate_and_calculate_coupon'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'ASTRACK20',
          'p_plan_id': 'plan_pro',
          'p_user_id': null,
        }),
      );
      expect(valValidRes.statusCode, equals(200));
      final Map validData = jsonDecode(valValidRes.body);
      expect(validData['is_valid'], isTrue);
      expect(validData['original_price'], equals(29000));
      expect(validData['discount_amount'], equals(5800));
      expect(validData['final_price'], equals(23200));
      print('LIVE CLOUD: ASTRACK20 valid on Pro. Discount: 5800, Final: 23200');

      // 6.2 Invalid coupon code
      final valInvalidRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/validate_and_calculate_coupon'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'FAKE_NONEXISTENT_CODE',
          'p_plan_id': 'plan_pro',
          'p_user_id': null,
        }),
      );
      expect(valInvalidRes.statusCode, equals(200));
      final Map invalidData = jsonDecode(valInvalidRes.body);
      expect(invalidData['is_valid'], isFalse);
      expect(invalidData['error_message'], contains('tidak valid'));
      print('LIVE CLOUD: Fake coupon successfully rejected with: ${invalidData['error_message']}');

      // 6.3 Minimum purchase requirement: HEMATPRO requires min purchase 25000, basic plan is 15000
      final valMinPurchaseRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/validate_and_calculate_coupon'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'HEMATPRO',
          'p_plan_id': 'plan_basic',
          'p_user_id': null,
        }),
      );
      expect(valMinPurchaseRes.statusCode, equals(200));
      final Map minData = jsonDecode(valMinPurchaseRes.body);
      expect(minData['is_valid'], isFalse);
      expect(minData['error_message'], contains('Minimum pembelian'));
      print('LIVE CLOUD: HEMATPRO correctly rejected on basic plan due to minimum purchase requirement: ${minData['error_message']}');
    });

    test('7. Live Zero-Floor Security: Discount never creates negative price (LIVE CLOUD)', () async {
      // ASTRACK5K has 5000 fixed discount. On plan_free (price = 0), final_price must be 0, not -5000.
      final zeroRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/validate_and_calculate_coupon'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'ASTRACK5K',
          'p_plan_id': 'plan_free',
          'p_user_id': null,
        }),
      );
      expect(zeroRes.statusCode, equals(200));
      final Map zeroData = jsonDecode(zeroRes.body);
      // Either rejected by minimum purchase or final_price capped at 0
      if (zeroData['is_valid'] == true) {
        expect(zeroData['final_price'], greaterThanOrEqualTo(0));
      } else {
        expect(zeroData['is_valid'], isFalse);
      }
      print('LIVE CLOUD: Zero-floor security verified. Result: $zeroData');
    });

    test('8. Live Admin RBAC: Non-admin caller is denied mutation (LIVE CLOUD)', () async {
      final adminRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/admin_update_plan_pricing'),
        headers: headers,
        body: jsonEncode({
          'p_plan_id': 'plan_pro',
          'p_new_price': 1,
          'p_name': 'Pro Hacked',
          'p_description': 'Hacked',
          'p_duration_months': 1,
          'p_is_recommended': true,
          'p_is_active': true,
          'p_admin_id': null,
        }),
      );
      expect(adminRes.statusCode, equals(200));
      final Map adminData = jsonDecode(adminRes.body);
      expect(adminData['success'], isFalse);
      expect(adminData['error'], contains('Administrator'));
      print('LIVE CLOUD: Non-admin call strictly blocked by server RPC.');
    });

    test('9. Existing Data Integrity: plans table preserved with original pricing (LIVE CLOUD)', () async {
      final plansRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/plans?select=*&order=monthly_price.asc'),
        headers: headers,
      );
      expect(plansRes.statusCode, equals(200));
      final List plans = jsonDecode(plansRes.body);
      
      final freePlan = plans.firstWhere((p) => p['id'] == 'plan_free');
      final basicPlan = plans.firstWhere((p) => p['id'] == 'plan_basic');
      final proPlan = plans.firstWhere((p) => p['id'] == 'plan_pro');

      expect(freePlan['monthly_price'], equals(0));
      expect(basicPlan['monthly_price'], equals(15000));
      expect(proPlan['monthly_price'], equals(29000));
      print('LIVE CLOUD: Existing plans data 100% intact: Free (0), Basic (15000), Pro (29000).');
    });

    test('10. Probe Supabase Auth & JWT Session Availability', () async {
      // 10.1 Probe Anonymous Signup
      final anonSignupRes = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/signup'),
        headers: headers,
        body: jsonEncode({}),
      );
      print('LIVE CLOUD: Anon signup status = ${anonSignupRes.statusCode}, body = ${anonSignupRes.body}');

      // 10.2 Probe Token Endpoint with Anonymous Grant
      final anonTokenRes = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/token?grant_type=anonymous'),
        headers: headers,
        body: jsonEncode({}),
      );
      print('LIVE CLOUD: Anon token status = ${anonTokenRes.statusCode}, body = ${anonTokenRes.body}');
    });

    test('11. RLS Attack Regression: Direct client mutation attacks on tables (LIVE CLOUD)', () async {
      // 11.1 plans: DELETE attack
      final delPlanRes = await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/plans?id=eq.plan_pro'),
        headers: headers,
      );
      print('LIVE CLOUD: DELETE plans attack status = ${delPlanRes.statusCode}');
      expect(delPlanRes.statusCode, anyOf([200, 204, 401, 403]));
      if (delPlanRes.statusCode == 200) {
        final List deleted = jsonDecode(delPlanRes.body);
        expect(deleted.isEmpty, isTrue, reason: 'RLS must block DELETE, returning 0 affected rows');
      }

      // Re-verify plan_pro is still there
      final checkPlan = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/plans?id=eq.plan_pro&select=id'),
        headers: headers,
      );
      expect(jsonDecode(checkPlan.body), isNotEmpty);

      // 11.2 coupons: INSERT attack by anon client
      final insertCouponRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/coupons'),
        headers: headers,
        body: jsonEncode({
          'code': 'HACKED_99_OFF',
          'discount_type': 'percentage',
          'discount_value': 99,
          'is_active': true,
        }),
      );
      print('LIVE CLOUD: INSERT coupons attack status = ${insertCouponRes.statusCode}, body = ${insertCouponRes.body}');
      expect(insertCouponRes.statusCode, anyOf([400, 401, 403]));

      // 11.3 plan_price_history: INSERT attack by anon client
      final insertHistRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/plan_price_history'),
        headers: headers,
        body: jsonEncode({
          'plan_id': 'plan_pro',
          'old_price': 29000,
          'new_price': 1,
        }),
      );
      print('LIVE CLOUD: INSERT plan_price_history attack status = ${insertHistRes.statusCode}, body = ${insertHistRes.body}');
      expect(insertHistRes.statusCode, anyOf([400, 401, 403]));

      // 11.4 coupon_redemptions: INSERT attack by anon client
      final insertRedeemRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/coupon_redemptions'),
        headers: headers,
        body: jsonEncode({
          'coupon_id': '97823b64-aa48-46c7-ba33-cd83363594bf',
          'user_id': '00000000-0000-0000-0000-000000000001',
          'plan_id': 'plan_pro',
          'original_price': 29000,
          'discount_amount': 5800,
          'final_price': 23200,
        }),
      );
      print('LIVE CLOUD: INSERT coupon_redemptions attack status = ${insertRedeemRes.statusCode}, body = ${insertRedeemRes.body}');
      expect(insertRedeemRes.statusCode, anyOf([400, 401, 403]));

      // 11.5 payment_webhook_events: Direct client mutation probe
      final whInsertRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events'),
        headers: headers,
        body: jsonEncode({
          'event_id': 'ASTRACK-TEST-PROBE-001',
          'provider': 'sandbox',
          'order_id': 'TEST-ORDER-PROBE',
        }),
      );
      print('LIVE CLOUD: payment_webhook_events INSERT status = ${whInsertRes.statusCode}, body = ${whInsertRes.body}');

      final whSelectRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events?event_id=eq.ASTRACK-TEST-PROBE-001'),
        headers: headers,
      );
      print('LIVE CLOUD: payment_webhook_events SELECT status = ${whSelectRes.statusCode}, body = ${whSelectRes.body}');
    });

    test('12. Persistent Webhook Idempotency & Replay Protection against Supabase Cloud', () async {
      final event1 = 'ASTRACK-TEST-WEBHOOK-001';
      final event2 = 'ASTRACK-TEST-WEBHOOK-002';

      // Ensure clean state for test events
      await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events?event_id=in.($event1,$event2)'),
        headers: headers,
      );

      // 12.1 First Webhook Event: Send and record to database
      final firstRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events'),
        headers: headers,
        body: jsonEncode({
          'event_id': event1,
          'provider': 'sandbox',
          'order_id': 'ORD-ASTRACK-001',
        }),
      );
      expect(firstRes.statusCode, equals(201), reason: 'First webhook event must be accepted and persisted');
      print('LIVE CLOUD: First webhook event $event1 recorded. Status: ${firstRes.statusCode}');

      // 12.2 Duplicate Webhook Event: Send exact same event ID again
      final dupRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events'),
        headers: headers,
        body: jsonEncode({
          'event_id': event1,
          'provider': 'sandbox',
          'order_id': 'ORD-ASTRACK-001',
        }),
      );
      // In PostgreSQL, PRIMARY KEY constraint violation causes 409 Conflict (code 23505)
      expect(dupRes.statusCode, equals(409), reason: 'PostgreSQL primary key must reject duplicate webhook event');
      final Map dupBody = jsonDecode(dupRes.body);
      expect(dupBody['code'], equals('23505'), reason: 'Unique violation error code');
      print('LIVE CLOUD: Duplicate webhook event $event1 rejected by database primary key: ${dupBody['message']}');

      // 12.3 Restart Persistence: Query database directly (simulating fresh process without memory)
      final persistRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events?event_id=eq.$event1'),
        headers: headers,
      );
      expect(persistRes.statusCode, equals(200));
      final List persistData = jsonDecode(persistRes.body);
      expect(persistData.length, equals(1), reason: 'Database must hold exactly 1 authoritative event record');
      print('LIVE CLOUD: Persistence verified. Single record found in DB for $event1');

      // 12.4 Different Event ID: Send event 2
      final secondRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events'),
        headers: headers,
        body: jsonEncode({
          'event_id': event2,
          'provider': 'sandbox',
          'order_id': 'ORD-ASTRACK-002',
        }),
      );
      expect(secondRes.statusCode, equals(201), reason: 'Different webhook event must be accepted');
      print('LIVE CLOUD: Second distinct event $event2 successfully accepted. Status: ${secondRes.statusCode}');

      // Clean up test events
      await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/payment_webhook_events?event_id=in.($event1,$event2)'),
        headers: headers,
      );
      print('LIVE CLOUD: Test webhook events cleaned up successfully.');
    });

    test('13. Live Database Transaction Atomicity & Rollback: Failure never increments usage_count (LIVE CLOUD)', () async {
      // 13.1 Query initial usage_count of ASTRACK20
      final preRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/coupons?code=eq.ASTRACK20&select=id,usage_count'),
        headers: headers,
      );
      expect(preRes.statusCode, equals(200));
      final List preData = jsonDecode(preRes.body);
      final initialUsage = preData.first['usage_count'];

      // 13.2 Execute failing redemption call (violates NOT NULL constraint on user_id)
      final failCallRes = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/redeem_coupon_order'),
        headers: headers,
        body: jsonEncode({
          'p_coupon_code': 'ASTRACK20',
          'p_plan_id': 'plan_pro',
          'p_user_id': null,
          'p_order_id': 'ORD-ROLLBACK-TEST-001',
        }),
      );
      expect(failCallRes.statusCode, equals(400), reason: 'Constraint violation must reject transaction');
      print('LIVE CLOUD: Failing redemption correctly aborted with status 400.');

      // 13.3 Query usage_count after failure - must be exactly equal to initialUsage (ROLLBACK VERIFIED)
      final postRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/coupons?code=eq.ASTRACK20&select=id,usage_count'),
        headers: headers,
      );
      expect(postRes.statusCode, equals(200));
      final List postData = jsonDecode(postRes.body);
      final postUsage = postData.first['usage_count'];
      expect(postUsage, equals(initialUsage), reason: 'Transaction rollback must prevent usage_count from incrementing on failure');
      print('LIVE CLOUD: Atomicity & Rollback verified: usage_count before = $initialUsage, after failure = $postUsage.');

      // 13.4 Query coupon_redemptions - must have no record for ORD-ROLLBACK-TEST-001
      final auditRes = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/coupon_redemptions?order_id=eq.ORD-ROLLBACK-TEST-001'),
        headers: headers,
      );
      expect(auditRes.statusCode, equals(200));
      final List auditData = jsonDecode(auditRes.body);
      expect(auditData.isEmpty, isTrue, reason: 'Failed transaction must not insert orphaned redemption record');
      print('LIVE CLOUD: Zero orphaned redemption records created on aborted transaction.');
    });
  });
}
