import 'package:flutter/material.dart';
import '../../services/saas_backend_service.dart';
import '../../models/saas_models.dart';
import '../../app/theme/app_colors.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _saas = SaaSBackendService();
  bool _isLoading = true;
  
  Subscription? _sub;
  Plan? _plan;
  List<License> _licenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final sub = await _saas.getUserSubscription(widget.userId);
    final plans = await _saas.getPlans();
    final allLicenses = await _saas.getAllLicenses();
    
    setState(() {
      _sub = sub;
      _plan = plans.isNotEmpty ? plans.firstWhere((p) => p.id == sub?.planId, orElse: () => plans.first) : null;
      _licenses = allLicenses.where((l) => l.userId == widget.userId).toList();
      _isLoading = false;
    });
  }

  void _extendLicense(String licenseId, int months) async {
    await _saas.extendLicense(licenseId, DurationType.months, months);
    await _saas.logAuditAction('admin', 'EXTEND_LICENSE', 'Extended license $licenseId by $months months');
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('User Details', style: TextStyle(color: textP, fontWeight: FontWeight.w700, fontFamily: 'Plus Jakarta Sans')),
        iconTheme: IconThemeData(color: textP),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primary))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileHeader(isDark, primary, textP),
              const SizedBox(height: 24),
              _buildSubscriptionCard(isDark, primary, textP),
              const SizedBox(height: 24),
              _buildLicensesList(isDark, primary, textP),
              const SizedBox(height: 24),
              _buildDangerZone(isDark),
            ],
          ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color primary, Color textP) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: primary.withOpacity(0.1),
            child: Icon(Icons.person_rounded, size: 32, color: primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userId, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                const SizedBox(height: 4),
                Text('Joined recently', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(bool isDark, Color primary, Color textP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Subscription', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_plan?.name ?? 'None', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primary), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(_sub?.status.name.toUpperCase() ?? 'INACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem('Devices', '${_plan?.maxDevices ?? 0}', isDark),
                  _statItem('AI Quota', '${_plan?.maxAiRequests ?? 0}', isDark),
                  _statItem('Period End', _sub?.currentPeriodEnd.toString().substring(0,10) ?? '-', isDark),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary, side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {}, // Trigger change plan
                  child: const Text('Change Plan'),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
      ],
    );
  }

  Widget _buildLicensesList(bool isDark, Color primary, Color textP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Licenses', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
            TextButton.icon(
              onPressed: () {
                _saas.createLicense(widget.userId, 'AST-GRANT-${DateTime.now().millisecondsSinceEpoch}', durationType: DurationType.months, durationValue: 1);
                _loadData();
              },
              icon: Icon(Icons.add, size: 16, color: primary),
              label: Text('Grant', style: TextStyle(color: primary)),
            )
          ],
        ),
        const SizedBox(height: 8),
        if (_licenses.isEmpty) 
          const Padding(padding: EdgeInsets.all(16), child: Text('No licenses found.'))
        else
          ..._licenses.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: ListTile(
              title: Text(l.licenseKey, style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace', fontSize: 13, color: textP)),
              subtitle: Text("Status: ${l.status.name} • Exp: ${l.expiresAt?.toString().substring(0,10) ?? 'Lifetime'}", style: const TextStyle(fontSize: 12)),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'ext_1') _extendLicense(l.id, 1);
                  if (val == 'ext_3') _extendLicense(l.id, 3);
                  if (val == 'revoke') _saas.updateLicenseStatus(l.id, LicenseStatus.revoked).then((_) => _loadData());
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'ext_1', child: Text('Extend 1 Month')),
                  const PopupMenuItem(value: 'ext_3', child: Text('Extend 3 Months')),
                  const PopupMenuItem(value: 'revoke', child: Text('Revoke', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ))
      ],
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danger Zone', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _dangerAction('Suspend User', 'Temporarily disable access', Icons.block, isDark),
              const Divider(height: 24),
              _dangerAction('Delete User Data', 'Permanently delete records', Icons.delete_forever, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dangerAction(String title, String subtitle, IconData icon, bool isDark) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), child: Icon(icon, color: Colors.red, size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.red),
        ],
      ),
    );
  }
}
