import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/saas_models.dart';
import '../../../services/saas_backend_service.dart';
import '../models/astra_feature.dart';
import '../widgets/upgrade_paywall_sheet.dart';

/// Centralized Feature Gate Service for ASTRACK
/// Validates server-side entitlements and enforces modern dynamic paywalls.
class FeatureGateService {
  static final SaaSBackendService _saas = SaaSBackendService();

  /// Check whether current user holds valid entitlement for the given feature.
  /// Server/Supabase subscription is the single source of truth.
  static Future<bool> hasEntitlement(
    AstraFeature feature, {
    String? userId,
  }) async {
    final uid = userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return false; // Guests / unauthenticated users have no paid entitlements
    }

    final sub = await _saas.getUserSubscription(uid);
    if (sub == null || sub.status != SubscriptionStatus.active) {
      return false;
    }

    // Check expiration
    if (sub.currentPeriodEnd.isBefore(DateTime.now())) {
      return false;
    }

    // If feature requires Pro, user must have plan_pro
    if (feature.requiresPro) {
      return sub.planId == 'plan_pro';
    }

    // If feature requires Basic, user with plan_basic or plan_pro has access
    if (feature.requiredPlanId == 'plan_basic') {
      return sub.planId == 'plan_basic' || sub.planId == 'plan_pro';
    }

    return true;
  }

  /// Gate helper: Executes [onGranted] immediately if entitled,
  /// otherwise prompts user with the dynamic modern [UpgradePaywallSheet].
  static Future<void> checkAndGate(
    BuildContext context, {
    required AstraFeature feature,
    required VoidCallback onGranted,
    VoidCallback? onDenied,
  }) async {
    final entitled = await hasEntitlement(feature);

    if (!context.mounted) return;

    if (entitled) {
      onGranted();
    } else {
      onDenied?.call();
      await showUpgradePaywall(
        context,
        feature: feature,
        onUnlocked: onGranted,
      );
    }
  }
}
