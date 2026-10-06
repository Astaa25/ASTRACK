import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/saas_models.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/saas_backend_service.dart';
import '../../subscription/models/astra_feature.dart';
import '../../subscription/widgets/upgrade_paywall_sheet.dart';

/// Non-intrusive luxury upgrade prompt card for the Dashboard.
/// Only displayed for Free / non-Pro users, and can be dismissed gracefully.
class DashboardUpgradeCard extends StatefulWidget {
  const DashboardUpgradeCard({super.key});

  @override
  State<DashboardUpgradeCard> createState() => _DashboardUpgradeCardState();
}

class _DashboardUpgradeCardState extends State<DashboardUpgradeCard> {
  bool _isVisible = false;
  final _saas = SaaSBackendService();

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedUntil = prefs.getInt('dashboard_upgrade_dismissed_until') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < dismissedUntil) {
      return; // Recently dismissed
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final sub = await _saas.getUserSubscription(userId);
        if (sub != null && sub.status == SubscriptionStatus.active && sub.planId == 'plan_pro') {
          return; // Already Pro! Don't show upgrade card
        }
      }
    } catch (_) {
      // Supabase uninitialized or offline
    }

    if (mounted) {
      setState(() => _isVisible = true);
    }
  }

  Future<void> _dismissCard() async {
    setState(() => _isVisible = false);
    final prefs = await SharedPreferences.getInstance();
    // Dismiss for 7 days so it never spams the user
    final nextShow = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    await prefs.setInt('dashboard_upgrade_dismissed_until', nextShow);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D251C), const Color(0xFF071410)]
              : [const Color(0xFFE6F4EE), const Color(0xFFF7FAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1D4A39) : const Color(0xFFC7E3D6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkLightGreen : AppColors.lightPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unlock more with ASTRACK Pro',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismissCard,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Get deeper insights, smart receipt scanning, and full control over your money.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                showUpgradePaywall(
                  context,
                  feature: AstraFeatures.advancedAnalytics,
                  onUnlocked: () {
                    setState(() => _isVisible = false);
                  },
                );
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore Plans',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
