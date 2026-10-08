import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/saas_backend_service.dart';
import '../../models/saas_models.dart';
import '../../app/theme/app_colors.dart';
import 'plan_builder_screen.dart';
import 'admin_user_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/admin_bottom_nav.dart';
import 'dart:convert';
import 'admin_statistics_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pricing_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_payment_queue_screen.dart';
import 'admin_gateway_config_screen.dart';
import 'admin_app_versions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _saas = SaaSBackendService();
  int _currentTabIndex = 0;
  bool _isLoading = true;
  
  int _totalUsers = 0;
  int _activeSubs = 0;
  double _revenue = 0.0;
  
  List<Plan> _plans = [];
  List<License> _licenses = [];
  List<Map<String, dynamic>> _recentActivity = [];

  int _activeProducts = 0;
  int _activeCoupons = 0;
  int _couponUsage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _saas.initializeDatabase(); // Ensure SaaS DB is seeded
    final subs = await _saas.getAllSubscriptions();
    final plans = await _saas.getPlans();
    final licenses = await _saas.getAllLicenses();
    final prefs = await SharedPreferences.getInstance();
    
    final logsRaw = prefs.getStringList('saas_audit_logs') ?? [];
    _recentActivity = logsRaw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList().reversed.take(5).toList();

    double revenue = 0.0;

    for (var sub in subs) {
      if (sub.status == SubscriptionStatus.active) {
        if (plans.isNotEmpty) {
          final plan = plans.firstWhere((p) => p.id == sub.planId, orElse: () => plans.first);
          revenue += plan.monthlyPrice;
        }
      }
    }


    // Exclude suspended / rejected accounts from total users count
    int activeUsersCount = subs.where((s) => s.status == SubscriptionStatus.active).length;
    try {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, status');
      final validNonSuspended = profiles
          .where((p) => (p['status'] ?? '').toString().toLowerCase() != 'suspended' &&
                        (p['status'] ?? '').toString().toLowerCase() != 'rejected')
          .length;
      if (validNonSuspended > 0) {
        activeUsersCount = validNonSuspended;
      }
    } catch (_) {}

    Map<String, dynamic> pricingSummary = {};
    try {
      pricingSummary = await _saas.getAdminPricingSummary();
    } catch (_) {}

    setState(() {
      _activeSubs = subs.where((s) => s.status == SubscriptionStatus.active).length;
      _totalUsers = activeUsersCount; 
      _plans = plans;
      _licenses = licenses;
      _revenue = revenue;
      _activeProducts = pricingSummary['active_products'] ?? plans.where((p) => p.isActive).length;
      _activeCoupons = pricingSummary['active_coupons'] ?? 0;
      _couponUsage = pricingSummary['total_coupon_usage'] ?? 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Admin Dashboard', style: TextStyle(color: textP, fontWeight: FontWeight.w700, fontFamily: 'Plus Jakarta Sans')),
        iconTheme: IconThemeData(color: textP),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: primary,
            ),
            onPressed: () => theme.toggleTheme(),
          ),
          Container(
            margin: const EdgeInsets.only(right: 20, left: 4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: primary.withOpacity(0.18),
              child: Text(
                'A',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: primary),
              ),
            ),
          ),
        ],
      ),
      body: _currentTabIndex == 0 
        ? (_isLoading 
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _buildHeader(isDark, primary, textP),
                  const SizedBox(height: 24),
                  _buildKPIs(isDark),
                  const SizedBox(height: 32),
                  _buildQuickActions(isDark, primary),
                  const SizedBox(height: 32),
                  _buildUserGrowthChart(isDark, primary, textP),
                  const SizedBox(height: 32),
                  _buildRecentActivity(isDark, textP),
                  const SizedBox(height: 32),
                  _buildPlans(isDark, primary, textP),
                  const SizedBox(height: 32),
                  _buildLicenses(isDark, textP),
                  const SizedBox(height: 40),
                ],
              ),
            ))
        : Center(child: Text('Under Construction', style: TextStyle(color: textP))),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _currentTabIndex,
        isDark: isDark,
        onTabSelected: (idx) {
          if (idx == 1) {
             Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          } else if (idx == 2) {
             Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()));
          } else if (idx == 3) {
             Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsScreen()));
          } else {
             setState(() => _currentTabIndex = idx);
          }
        },
        onCenterFabPressed: () async {
           final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanBuilderScreen()));
           if (result == true) _loadData();
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primary, Color textP) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(isDark ? 0.2 : 0.1),
                    primary.withOpacity(isDark ? 0.05 : 0.02)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Morning, Admin', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                        const SizedBox(height: 4),
                        Text("Here's what's happening with ASTRACK today.", style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPIs(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = screenWidth < 360 ? 0.95 : 1.1;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        _kpiCard('Users', _totalUsers.toString(), _totalUsers > 0 ? '+12%' : '', Icons.people_alt_rounded, Colors.blue, isDark),
        _kpiCard('Active Pro', _activeSubs.toString(), _activeSubs > 0 ? '+5%' : '', Icons.star_rounded, Colors.orange, isDark),
        _kpiCard('Active Products', _activeProducts.toString(), '${_plans.length} Total', Icons.inventory_2_rounded, AppColors.emerald, isDark),
        _kpiCard('Active Coupons', _activeCoupons.toString(), 'Ready', Icons.confirmation_number_rounded, Colors.purple, isDark),
        _kpiCard('Coupon Usage', _couponUsage.toString(), 'Redemptions', Icons.local_offer_rounded, Colors.teal, isDark),
        _kpiCard('Revenue (Mo)', _revenue > 0 ? 'Rp${(_revenue/1000000).toStringAsFixed(1)}M' : '—', _revenue > 0 ? '+18%' : 'No data', Icons.account_balance_wallet_rounded, AppColors.income, isDark),
      ],
    );
  }

  Widget _kpiCard(String title, String val, String subtitle, IconData icon, Color color, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      builder: (context, anim, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * anim),
          child: Opacity(
            opacity: anim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : color.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(val, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtitle.contains('+') ? AppColors.income : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _actionBtn('App Versions', Icons.system_update_rounded, Colors.indigo, isDark, () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAppVersionsScreen()));
                _loadData();
              }),
              _actionBtn('Payment Queue', Icons.receipt_long_rounded, Colors.blue, isDark, () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPaymentQueueScreen()));
                _loadData();
              }),
              _actionBtn('Gateway & Mode', Icons.hub_rounded, Colors.deepPurple, isDark, () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminGatewayConfigScreen()));
                _loadData();
              }),
              _actionBtn('Product Pricing', Icons.price_change_rounded, AppColors.emerald, isDark, () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPricingScreen()));
                _loadData();
              }),
              _actionBtn('Coupons', Icons.confirmation_number_rounded, Colors.purple, isDark, () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCouponsScreen()));
                _loadData();
              }),
              _actionBtn('Create Plan', Icons.add_chart_rounded, primary, isDark, () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanBuilderScreen()));
                if (result == true) _loadData();
              }),
              _actionBtn('Manage User', Icons.person_search_rounded, Colors.teal, isDark, () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUserDetailScreen(userId: 'current_user_123')));
              }),
              _actionBtn('Grant License', Icons.key_rounded, Colors.purple, isDark, () {
                _saas.createLicense('manual_grant', 'AST-MANUAL-${DateTime.now().millisecondsSinceEpoch}');
                _saas.logAuditAction('admin', 'GRANT_LICENSE', 'Manually granted license');
                _loadData();
              }),
              _actionBtn('Grant Trial', Icons.timer_rounded, Colors.orange, isDark, () {}),
              _actionBtn('Broadcast', Icons.campaign_rounded, Colors.blue, isDark, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart(bool isDark, Color primary, Color textP) {
    final months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
    final values = [0.3, 0.45, 0.6, 0.8, 0.7, 1.0]; // Mock normalized data

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User Growth', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Active Users (Last 6 Months)', 
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('+42%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.income)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutQuart,
                          width: 24,
                          height: 90 * values[index], // Max height 90
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [primary, primary.withOpacity(0.3)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(months[index], style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark, Color textP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: _recentActivity.isEmpty 
          ? const Padding(padding: EdgeInsets.all(20), child: Text('No recent activity'))
          : Column(
            children: _recentActivity.map((log) {
              final date = DateTime.parse(log['time']);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.income.withOpacity(0.1),
                  child: const Icon(Icons.history, color: AppColors.income, size: 18),
                ),
                title: Text(log['desc'] ?? '', style: TextStyle(fontSize: 13, color: textP, fontWeight: FontWeight.w500)),
                subtitle: Text("${date.hour}:${date.minute.toString().padLeft(2,'0')} - ${log['action']}", style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlans(bool isDark, Color primary, Color textP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dynamic Plans', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
            InkWell(
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPricingScreen()));
                _loadData();
              },
              child: Text('Manage', style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._plans.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(child: Text(p.name, style: TextStyle(fontWeight: FontWeight.w700, color: textP), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(p.type.name.toUpperCase(), style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${p.description}\nRp${p.monthlyPrice}/mo • Max Devices: ${p.maxDevices}', style: const TextStyle(fontSize: 12, height: 1.4)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        )),
      ],
    );
  }

  Widget _buildLicenses(bool isDark, Color textP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('License Management', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
        const SizedBox(height: 12),
        ..._licenses.map((l) {
          final isExpired = l.expiresAt != null && l.expiresAt!.isBefore(DateTime.now());
          final statusColor = isExpired ? AppColors.expense : (l.status == LicenseStatus.active ? AppColors.income : Colors.orange);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: ListTile(
              title: Text(l.licenseKey, style: TextStyle(fontWeight: FontWeight.w700, color: textP, fontFamily: 'monospace')),
              subtitle: Text('User: ${l.userId}\nExpires: ${l.expiresAt?.toString().substring(0,10) ?? 'Lifetime'}', style: const TextStyle(fontSize: 12)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'extend') _showExtendDialog(l);
                  if (val == 'revoke') _saas.updateLicenseStatus(l.id, LicenseStatus.revoked);
                  if (val == 'activate') _saas.updateLicenseStatus(l.id, LicenseStatus.active);
                  if (val == 'delete') _saas.deleteLicense(l.id);
                  if (val != 'extend') _loadData();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'extend', child: Text('Extend Duration')),
                  const PopupMenuItem(value: 'activate', child: Text('Activate')),
                  const PopupMenuItem(value: 'revoke', child: Text('Revoke')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
              leading: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showExtendDialog(License license) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Extend License'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _extendOption(ctx, license.id, '1 Month', 1),
              _extendOption(ctx, license.id, '3 Months', 3),
              _extendOption(ctx, license.id, '6 Months', 6),
              _extendOption(ctx, license.id, '1 Year', 12),
            ],
          ),
        );
      }
    );
  }

  Widget _extendOption(BuildContext ctx, String id, String label, int months) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        Navigator.pop(ctx);
        await _saas.extendLicense(id, DurationType.months, months);
        await _saas.logAuditAction('admin', 'EXTEND_LICENSE', 'Extended license by $months months');
        _loadData();
      },
    );
  }
}
