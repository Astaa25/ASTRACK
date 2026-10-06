import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final Set<String> _dismissingUserIds = {};

  final List<String> _categories = ['Request', 'Aktif', 'Ditolak', 'Free', 'Pro'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Fetch profiles
      final profilesData = await supabase
          .from('profiles')
          .select('id, email, full_name, status, updated_at');
          
      // 2. Fetch roles to identify and exclude admins
      final rolesData = await supabase
          .from('user_roles')
          .select('user_id, role_id');

      // 3. Fetch subscriptions
      final subsData = await supabase
          .from('subscriptions')
          .select('user_id, plan_id, status, expires_at');

      final adminUserIds = rolesData
          .where((r) => r['role_id'] == 'admin')
          .map((r) => r['user_id'].toString())
          .toSet();

      final List<Map<String, dynamic>> parsedList = [];

      for (var p in profilesData) {
        final userId = p['id'].toString();
        final email = (p['email'] ?? '').toString();

        // JANGAN TAMPILKAN ADMIN (hanya tampilkan user reguler/pelanggan)
        if (adminUserIds.contains(userId) || email.trim().toLowerCase() == 'astaabrar@gmail.com') {
          continue;
        }

        // Find subscription
        final userSub = subsData.firstWhere(
          (s) => s['user_id'].toString() == userId,
          orElse: () => <String, dynamic>{},
        );

        final planId = userSub['plan_id']?.toString() ?? 'plan_free';
        final isPro = planId == 'plan_pro';
        final planName = isPro ? 'PRO' : 'FREE';

        DateTime? proExpires;
        if (userSub['expires_at'] != null) {
          try {
            proExpires = DateTime.parse(userSub['expires_at'].toString()).toLocal();
          } catch (_) {}
        }

        DateTime lastActive = DateTime.now();
        if (p['updated_at'] != null) {
          try {
            lastActive = DateTime.parse(p['updated_at'].toString()).toLocal();
          } catch (_) {}
        }

        parsedList.add({
          'id': userId,
          'full_name': (p['full_name'] != null && p['full_name'].toString().isNotEmpty)
              ? p['full_name'].toString()
              : email.split('@').first,
          'email': email,
          'status': (p['status'] ?? 'pending').toString().toLowerCase(),
          'plan': planName,
          'pro_expires': proExpires,
          'last_active': lastActive,
        });
      }

      setState(() {
        _users = parsedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _isLoading = false;
      });
    }
  }

  void _handleUserAction(Map<String, dynamic> u, String newStatus) async {
    final userId = u['id'].toString();
    setState(() {
      _dismissingUserIds.add(userId);
    });

    // Berikan animasi slide & fade out yang halus (260ms) sebelum pindah data
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    await _updateUserStatus(userId, newStatus, userFullName: u['full_name']);

    if (mounted) {
      setState(() {
        _dismissingUserIds.remove(userId);
      });
    }
  }

  Future<void> _updateUserStatus(String userId, String newStatus, {String? userFullName}) async {
    final oldUser = _users.firstWhere((u) => u['id'] == userId, orElse: () => {});
    final oldStatus = oldUser['status']?.toString();

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'status': newStatus})
          .eq('id', userId);
    } catch (_) {}

    setState(() {
      final idx = _users.indexWhere((u) => u['id'] == userId);
      if (idx != -1) {
        _users[idx]['status'] = newStatus;
      }
    });

    if (mounted) {
      final name = userFullName ?? 'Pengguna';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: newStatus == 'approved' ? AppColors.income : const Color(0xFFD32F2F),
          content: Row(
            children: [
              Icon(
                newStatus == 'approved' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  newStatus == 'approved'
                      ? '✓ $name berhasil disetujui & aktif!'
                      : '✕ Pendaftaran $name ditolak (masuk ke tab Ditolak).',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          action: (oldStatus != null && oldStatus != newStatus)
              ? SnackBarAction(
                  label: 'Urungkan',
                  textColor: Colors.white,
                  onPressed: () {
                    _updateUserStatus(userId, oldStatus, userFullName: userFullName);
                  },
                )
              : null,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterUsers(int tabIndex) {
    switch (tabIndex) {
      case 0: // Request
        return _users.where((u) => u['status'] == 'pending').toList();
      case 1: // Aktif (Semua pengguna yang approved)
        return _users.where((u) => u['status'] == 'approved').toList();
      case 2: // Ditolak (Kategori khusus rejected!)
        return _users.where((u) => u['status'] == 'rejected').toList();
      case 3: // Free (HANYA pengguna aktif berpaket Free)
        return _users.where((u) => u['status'] == 'approved' && u['plan'] == 'FREE').toList();
      case 4: // Pro (HANYA pengguna aktif berpaket Pro)
        return _users.where((u) => u['status'] == 'approved' && u['plan'] == 'PRO').toList();
      default:
        return _users;
    }
  }

  Widget _buildTab(String label, int count, Color? badgeColor) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0 && badgeColor != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor == AppColors.goldAccent ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final pendingCount = _users.where((u) => u['status'] == 'pending').length;
    final activeCount = _users.where((u) => u['status'] == 'approved').length;
    final rejectedCount = _users.where((u) => u['status'] == 'rejected').length;
    final freeCount = _users.where((u) => u['status'] == 'approved' && u['plan'] == 'FREE').length;
    final proCount = _users.where((u) => u['status'] == 'approved' && u['plan'] == 'PRO').length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Manajemen Pengguna',
          style: TextStyle(color: textP, fontWeight: FontWeight.w700, fontFamily: 'Plus Jakarta Sans'),
        ),
        iconTheme: IconThemeData(color: textP),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              tabs: [
                _buildTab('Request', pendingCount, AppColors.expense),
                _buildTab('Aktif', activeCount, AppColors.income),
                _buildTab('Ditolak', rejectedCount, const Color(0xFFD32F2F)),
                _buildTab('Free', freeCount, null),
                _buildTab('Pro', proCount, AppColors.goldAccent),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              color: primary,
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_categories.length, (index) {
                  final filtered = _filterUsers(index);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            index == 2 ? Icons.cancel_outlined : Icons.people_outline_rounded,
                            size: 54,
                            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            index == 2
                                ? 'Belum ada pendaftaran yang ditolak'
                                : 'Tidak ada pengguna di kategori ini',
                            style: TextStyle(
                              color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final u = filtered[i];
                      return _buildUserCard(u, isDark, primary, cardColor, textP);
                    },
                  );
                }),
              ),
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u, bool isDark, Color primary, Color cardColor, Color textP) {
    final userId = u['id'].toString();
    final isDismissing = _dismissingUserIds.contains(userId);
    final isPro = u['plan'] == 'PRO';
    final isSuspended = u['status'] == 'suspended';
    final isPending = u['status'] == 'pending';
    final isRejected = u['status'] == 'rejected';

    String planBadgeText = u['plan'];
    Color planBadgeBg;
    Color planBadgeTextColor;

    if (isRejected) {
      planBadgeText = 'DITOLAK';
      planBadgeBg = AppColors.expense.withValues(alpha: 0.12);
      planBadgeTextColor = AppColors.expense;
    } else if (isPending) {
      planBadgeText = 'PENDING';
      planBadgeBg = AppColors.warning.withValues(alpha: 0.15);
      planBadgeTextColor = AppColors.warning;
    } else if (isSuspended) {
      planBadgeText = 'SUSPENDED';
      planBadgeBg = AppColors.expense;
      planBadgeTextColor = Colors.white;
    } else if (isPro) {
      planBadgeText = 'PRO';
      planBadgeBg = AppColors.goldAccent;
      planBadgeTextColor = Colors.black;
    } else {
      planBadgeText = 'FREE';
      planBadgeBg = isDark ? AppColors.darkElevatedCard : AppColors.lightBorder;
      planBadgeTextColor = textP;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      opacity: isDismissing ? 0.0 : 1.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        offset: isDismissing ? const Offset(-1.0, 0) : Offset.zero,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPro
                  ? AppColors.goldAccent.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isPro ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isPro ? AppColors.goldAccent.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isRejected
                        ? AppColors.expense.withValues(alpha: 0.12)
                        : (isPro ? AppColors.goldAccent.withValues(alpha: 0.2) : primary.withValues(alpha: 0.1)),
                    child: Icon(
                      isRejected ? Icons.person_off_rounded : Icons.person,
                      color: isRejected
                          ? AppColors.expense
                          : (isPro ? AppColors.goldAccent : primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u['full_name'],
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textP),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          u['email'],
                          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: planBadgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      planBadgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: planBadgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status Akun', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPending
                                  ? AppColors.warning
                                  : (isSuspended || isRejected ? AppColors.expense : AppColors.income),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            u['status'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isRejected ? AppColors.expense : textP,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isPro && u['pro_expires'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Berlaku Hingga', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          u['pro_expires'].year >= 2090
                              ? 'Lifetime'
                              : DateFormat('dd MMM yyyy').format(u['pro_expires']),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldAccent),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Aktivitas Terakhir', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(u['last_active']),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textP),
                        ),
                      ],
                    ),
                ],
              ),

              // Actions for pending
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _handleUserAction(u, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.expense,
                          side: const BorderSide(color: AppColors.expense, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        onPressed: () => _handleUserAction(u, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.income,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ] else if (isSuspended || isRejected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    onPressed: () => _handleUserAction(u, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    label: const Text('Aktifkan Kembali', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
