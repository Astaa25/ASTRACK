import 'package:flutter/material.dart';
import '../../features/subscription/models/astra_feature.dart';
import '../../features/subscription/widgets/upgrade_paywall_sheet.dart';

/// Reusable PaywallSheet alias pointing to UpgradePaywallSheet
typedef PaywallSheet = UpgradePaywallSheet;

/// Helper to trigger paywall
Future<bool?> showPaywall(
  BuildContext context, {
  required AstraFeature feature,
  VoidCallback? onUnlocked,
}) {
  return showUpgradePaywall(
    context,
    feature: feature,
    onUnlocked: onUnlocked,
  );
}
