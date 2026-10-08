import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/saas_backend_service.dart';
import '../../models/saas_models.dart';
import '../../app/theme/app_colors.dart';
import 'models/astra_feature.dart';
import 'widgets/upgrade_paywall_sheet.dart';
import '../../widgets/liquid_loader.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _saas = SaaSBackendService();
  bool _isLoading = true;
  Subscription? _sub;
  Plan? _currentPlan;
  License? _activeLicense;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _saas.initializeDatabase();
    
    User? currentUser;
    try {
      currentUser = Supabase.instance.client.auth.currentUser;
    } catch (_) {}
    final userId = currentUser?.id ?? 'current_user_123';
    
    final sub = await _saas.getUserSubscription(userId);
    final plans = await _saas.getPlans();
    final licenses = await _saas.getAllLicenses();
    
    License? active;
    try {
      active = licenses.firstWhere((l) => l.userId == userId && l.status == LicenseStatus.active);
    } catch (_) {}

    setState(() {
      _sub = sub;
      _currentPlan = plans.firstWhere((p) => p.id == sub?.planId, orElse: () => plans.first);
      _activeLicense = active;
      _isLoading = false;
    });
  }

  Future<void> _upgradeToPlan(String planId) async {
    final feature = planId == 'plan_basic' ? AstraFeatures.csvImportExport : AstraFeatures.receiptScanner;
    await showUpgradePaywall(
      context,
      feature: feature,
      onUnlocked: _loadData,
    );
  }

  void _showManageSubscriptionSheet(bool isDark, Color primary, Color textP) {
    final isPro = _sub?.planId == 'plan_pro' && _sub?.status == SubscriptionStatus.active;
    final dateStr = _sub?.currentPeriodEnd != null && _sub!.currentPeriodEnd.year < 2090
        ? DateFormat('dd MMMM yyyy').format(_sub!.currentPeriodEnd)
        : 'Seumur Hidup (Lifetime)';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isPro) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.goldAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paket PRO Aktif 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                          Text('Akses penuh fitur premium ASTRACK', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Masa Berlaku:', style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary, fontSize: 13)),
                          Text(dateStr, style: TextStyle(fontWeight: FontWeight.w700, color: textP, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Auto-Renewal:', style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary, fontSize: 13)),
                          const Text('Aktif (Manual via Admin)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.income, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _upgradeToPlan('plan_pro');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primary),
                    child: const Text('Perpanjang Masa Aktif Pro'),
                  ),
                ),
              ] else ...[
                Text('Pilih Paket Langganan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textP)),
                const SizedBox(height: 6),
                Text('Upgrade untuk membuka fitur AI & OCR Scanner tanpa batas', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _upgradeToPlan('plan_pro');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primary),
                    child: const Text('Buka Pilihan Paket Langganan'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final isPro = _sub?.planId == 'plan_pro' && _sub?.status == SubscriptionStatus.active;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Your Plan', style: TextStyle(color: textP, fontWeight: FontWeight.w700, fontFamily: 'Plus Jakarta Sans')),
        iconTheme: IconThemeData(color: textP),
      ),
      body: _isLoading
          ? const Center(child: AstrackLiquidLoader.full())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primary,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildCurrentPlanCard(isDark, primary, border, isPro),
                  const SizedBox(height: 24),
                  _buildEntitlements(isDark, textP, border, isPro),
                  const SizedBox(height: 32),
                  if (!isPro)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _upgradeToPlan('plan_pro'),
                      child: const Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  if (isPro)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(color: primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _showManageSubscriptionSheet(isDark, primary, textP),
                      child: const Text('Kelola Langganan (Manage Subscription)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard(bool isDark, Color primary, Color border, bool isPro) {
    final Color cardColor = isPro ? primary : (isDark ? AppColors.darkCard : Colors.white);
    final Color textColor = isPro ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    
    String expiresText = 'Lifetime';
    if (_sub?.currentPeriodEnd != null) {
      if (_sub!.currentPeriodEnd.year >= 2090) {
        expiresText = 'Lifetime';
      } else {
        expiresText = DateFormat('dd MMM yyyy').format(_sub!.currentPeriodEnd);
      }
    } else if (_activeLicense?.expiresAt != null) {
      expiresText = DateFormat('dd MMM yyyy').format(_activeLicense!.expiresAt!);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isPro ? null : Border.all(color: border),
        boxShadow: isPro ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentPlan?.name ?? 'Free',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Plus Jakarta Sans'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPro ? Colors.white.withOpacity(0.2) : primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_sub?.status.name.toUpperCase() ?? 'ACTIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPro ? Colors.white : primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_currentPlan?.description ?? 'Standard features', style: TextStyle(fontSize: 14, color: isPro ? Colors.white70 : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: isPro ? Colors.white70 : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Expires: $expiresText',
                  style: TextStyle(fontSize: 13, color: isPro ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntitlements(bool isDark, Color textP, Color border, bool isPro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You have access to:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textP, fontFamily: 'Plus Jakarta Sans')),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              _feat('Devices', '${_currentPlan?.maxDevices ?? 1} allowed', Icons.devices_rounded, isDark, textP),
              const Divider(height: 1),
              _feat('AI Requests', '${_currentPlan?.maxAiRequests ?? 50} per month', Icons.smart_toy_rounded, isDark, textP),
              const Divider(height: 1),
              _feat('OCR Scanner', _currentPlan?.type == PlanType.regular ? 'Unlimited' : 'Pro only', Icons.document_scanner_rounded, isDark, textP, 
                locked: _currentPlan?.type != PlanType.regular),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feat(String title, String subtitle, IconData icon, bool isDark, Color textP, {bool locked = false}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: locked ? AppColors.expense.withOpacity(0.1) : AppColors.income.withOpacity(0.1),
        child: Icon(locked ? Icons.lock_rounded : icon, color: locked ? AppColors.expense : AppColors.income, size: 18),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textP)),
      trailing: Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
    );
  }
}
