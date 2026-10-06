import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:astrack/models/saas_models.dart';
import 'package:astrack/core/utils/currency_formatter.dart';
import 'package:astrack/features/subscription/models/astra_feature.dart';
import 'package:astrack/features/subscription/widgets/upgrade_paywall_sheet.dart';
import 'package:astrack/services/payment/payment_service.dart';
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Dynamic Upgrade Paywall Unit & Integration Tests', () {
    test('1. Dynamic Plan Duration Formatting', () {
      final monthly = Plan(
        id: 'p1', slug: 'p1', name: 'Monthly',
        type: PlanType.regular, monthlyPrice: 20000, maxDevices: 1, maxAiRequests: 50,
        durationMonths: 1,
      );
      expect(monthly.durationLabel, '/ bulan');

      final quarterly = Plan(
        id: 'p3', slug: 'p3', name: 'Quarterly',
        type: PlanType.regular, monthlyPrice: 50000, maxDevices: 1, maxAiRequests: 50,
        durationMonths: 3,
      );
      expect(quarterly.durationLabel, '/ 3 bulan');

      final halfYear = Plan(
        id: 'p6', slug: 'p6', name: 'Semi-Annual',
        type: PlanType.regular, monthlyPrice: 90000, maxDevices: 1, maxAiRequests: 50,
        durationMonths: 6,
      );
      expect(halfYear.durationLabel, '/ 6 bulan');

      final annual = Plan(
        id: 'p12', slug: 'p12', name: 'Annual',
        type: PlanType.regular, monthlyPrice: 180000, maxDevices: 1, maxAiRequests: 50,
        durationMonths: 12,
      );
      expect(annual.durationLabel, '/ tahun');

      final lifetimeMonths = Plan(
        id: 'plife', slug: 'plife', name: 'Lifetime Months',
        type: PlanType.regular, monthlyPrice: 500000, maxDevices: 5, maxAiRequests: 1000,
        durationMonths: 120,
      );
      expect(lifetimeMonths.durationLabel, 'Lifetime');

      final lifetimeEnum = Plan(
        id: 'plife2', slug: 'plife2', name: 'Lifetime Enum',
        type: PlanType.lifetime, monthlyPrice: 500000, maxDevices: 5, maxAiRequests: 1000,
        durationMonths: 1,
      );
      expect(lifetimeEnum.durationLabel, 'Lifetime');
    });

    test('2. Dynamic Plan JSON Parsing with DB Schema Fields', () {
      final dbJson = {
        'id': 'plan_custom_enterprise',
        'slug': 'enterprise',
        'name': 'Enterprise Plan',
        'description': 'Custom corporate tier',
        'type': 'regular',
        'monthly_price': 125000,
        'duration_months': 6,
        'features': ['Multi-org support', 'Dedicated AI server', 'Priority SLA'],
        'is_active': true,
        'is_recommended': true,
      };

      final plan = Plan.fromJson(dbJson);
      expect(plan.id, 'plan_custom_enterprise');
      expect(plan.monthlyPrice, 125000.0);
      expect(plan.durationMonths, 6);
      expect(plan.durationLabel, '/ 6 bulan');
      expect(plan.features.length, 3);
      expect(plan.isRecommended, true);
      expect(CurrencyFormatter.format(plan.monthlyPrice), 'Rp125.000');
    });

    test('3. Feature Gate Catalog & Dynamic Benefits Verification', () {
      final ocr = AstraFeatures.receiptScanner;
      expect(ocr.requiredPlanId, 'plan_pro');
      expect(ocr.requiresPro, true);
      expect(ocr.heroTitle, contains('Pro'));
      expect(ocr.heroSubtitle, contains('receipts'));
      expect(ocr.benefits.length, 4);

      final csv = AstraFeatures.csvImportExport;
      expect(csv.requiredPlanId, 'plan_basic');
      expect(csv.requiresPro, false);
      expect(csv.heroTitle, contains('Basic'));
      expect(csv.benefits.length, 4);

      final reports = AstraFeatures.advancedReports;
      expect(reports.requiredPlanId, 'plan_basic');
      expect(reports.benefits.length, 4);

      final analytics = AstraFeatures.advancedAnalytics;
      expect(analytics.requiredPlanId, 'plan_pro');
      expect(analytics.requiresPro, true);
    });

    test('4. Tiered Entitlement & Expiry Matrix Logic', () {
      bool evaluateEntitlement({
        required Subscription? sub,
        required AstraFeature feature,
        required DateTime now,
      }) {
        if (sub == null || sub.status != SubscriptionStatus.active) return false;
        if (sub.currentPeriodEnd.isBefore(now)) return false;

        if (feature.requiresPro) {
          return sub.planId == 'plan_pro';
        }
        if (feature.requiredPlanId == 'plan_basic') {
          return sub.planId == 'plan_basic' || sub.planId == 'plan_pro';
        }
        return true;
      }

      final now = DateTime.now();

      // Free user
      expect(
        evaluateEntitlement(sub: null, feature: AstraFeatures.receiptScanner, now: now),
        false,
        reason: 'Free user cannot access Pro OCR',
      );
      expect(
        evaluateEntitlement(sub: null, feature: AstraFeatures.csvImportExport, now: now),
        false,
        reason: 'Free user cannot access Basic CSV Import',
      );

      // Basic user
      final basicSub = Subscription(
        id: 'sub_basic',
        userId: 'u_1',
        planId: 'plan_basic',
        status: SubscriptionStatus.active,
        currentPeriodEnd: now.add(const Duration(days: 30)),
      );
      expect(
        evaluateEntitlement(sub: basicSub, feature: AstraFeatures.csvImportExport, now: now),
        true,
        reason: 'Basic user can access Basic CSV',
      );
      expect(
        evaluateEntitlement(sub: basicSub, feature: AstraFeatures.receiptScanner, now: now),
        false,
        reason: 'Basic user cannot access Pro OCR',
      );

      // Pro user
      final proSub = Subscription(
        id: 'sub_pro',
        userId: 'u_2',
        planId: 'plan_pro',
        status: SubscriptionStatus.active,
        currentPeriodEnd: now.add(const Duration(days: 30)),
      );
      expect(
        evaluateEntitlement(sub: proSub, feature: AstraFeatures.csvImportExport, now: now),
        true,
        reason: 'Pro user has access to Basic features',
      );
      expect(
        evaluateEntitlement(sub: proSub, feature: AstraFeatures.receiptScanner, now: now),
        true,
        reason: 'Pro user has access to Pro features',
      );

      // Expired Pro user
      final expiredProSub = Subscription(
        id: 'sub_exp',
        userId: 'u_3',
        planId: 'plan_pro',
        status: SubscriptionStatus.active,
        currentPeriodEnd: now.subtract(const Duration(hours: 1)),
      );
      expect(
        evaluateEntitlement(sub: expiredProSub, feature: AstraFeatures.receiptScanner, now: now),
        false,
        reason: 'Expired Pro user is gated and denied',
      );
    });

    test('5. Payment Order Creation & Non-Destructive Flow', () async {
      final provider = PaymentGatewayFactory.create();
      expect(provider, isNotNull);

      final order = await provider.createOrder(
        userId: 'test_user_42',
        planId: 'plan_pro',
        amount: 29000.0,
      );

      expect(order.orderId, startsWith('ORD_'));
      expect(order.amount, 29000.0);
      expect(order.status, PaymentStatus.pending);

      // Verify payment provider requires server simulation/verification to change status
      final initialStatus = await provider.checkOrderStatus(order.orderId);
      expect(initialStatus, PaymentStatus.pending);
    });

    testWidgets('6. Dynamic UpgradePaywallSheet renders correctly without errors', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      final storage = StorageService();
      await storage.init();
      final themeProvider = ThemeProvider(storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UpgradePaywallSheet(
                feature: AstraFeatures.receiptScanner,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Hero section content
      expect(find.text(AstraFeatures.receiptScanner.heroTitle), findsOneWidget);
      expect(find.text(AstraFeatures.receiptScanner.heroSubtitle), findsOneWidget);

      // Verify Benefits
      expect(find.text('Keunggulan ${AstraFeatures.receiptScanner.title}'), findsOneWidget);
      expect(find.text('Scan receipts automatically using smart OCR'), findsOneWidget);

      // Verify Bottom Dismiss action
      expect(find.text('Maybe later'), findsOneWidget);
    });
  });
}
