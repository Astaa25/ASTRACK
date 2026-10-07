import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/services/security_service.dart';
import 'about_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../auth/pin_lock_screen.dart';
import '../subscription/subscription_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_pricing_screen.dart';
import '../admin/admin_coupons_screen.dart';
import 'manage_categories_screen.dart';
import 'privacy_data_screen.dart';
import 'appearance_screen.dart';
import 'language_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDailyReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDailyReminderEnabled = prefs.getBool('astrack_daily_reminder') ?? false;
    });
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('astrack_daily_reminder', value);
    setState(() {
      _isDailyReminderEnabled = value;
    });

    if (!mounted) return;
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Pengingat harian diaktifkan! Anda akan diingatkan setiap jam 20:00.'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔕 Pengingat harian dinonaktifkan.'),
        ),
      );
    }
  }
  void _showSecurityModal(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final security = SecurityService.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security_rounded, color: AppColors.emerald, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Keamanan Aplikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // PIN Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: security.isPinEnabled
                        ? AppColors.emerald.withAlpha(15)
                        : (isDark ? AppColors.darkElevatedCard : AppColors.lightBg),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: security.isPinEnabled
                          ? AppColors.emerald.withAlpha(60)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        security.isPinEnabled
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: security.isPinEnabled ? AppColors.emerald : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              security.isPinEnabled ? 'PIN Aktif' : 'PIN Nonaktif',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: security.isPinEnabled ? AppColors.emerald : Colors.grey,
                              ),
                            ),
                            Text(
                              security.isPinEnabled
                                  ? 'Aplikasi terkunci dengan PIN 6-digit'
                                  : 'Aktifkan PIN untuk keamanan data finansial',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Biometric toggle
                if (security.isPinEnabled)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Autentikasi Biometrik', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Gunakan sidik jari / Face ID sebagai alternatif PIN', style: TextStyle(fontSize: 12)),
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.emerald),
                    value: security.isBiometricEnabled,
                    activeColor: AppColors.emerald,
                    onChanged: (val) async {
                      await security.setBiometricsEnabled(val);
                      setSheetState(() {});
                      if (context.mounted) setState(() {});
                    },
                  ),

                const SizedBox(height: 8),

                // Action Buttons
                if (!security.isPinEnabled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_moderator_rounded),
                      label: const Text('Buat PIN Keamanan', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PinLockScreen(
                              mode: PinMode.create,
                              onSuccess: () {
                                Navigator.of(context).pop();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PIN berhasil diaktifkan! Aplikasi akan terkunci otomatis.'),
                                    backgroundColor: AppColors.emerald,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else ...[  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emerald,
                        side: const BorderSide(color: AppColors.emerald),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Ganti PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PinLockScreen(
                              mode: PinMode.change,
                              onSuccess: () {
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.no_encryption_rounded),
                      label: const Text('Nonaktifkan PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showDialog(
                          context: context,
                          builder: (alertCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Nonaktifkan PIN?'),
                            content: const Text('Aplikasi tidak akan lagi terkunci secara otomatis. Lanjutkan?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(alertCtx).pop(),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
                                onPressed: () async {
                                  await security.removePin();
                                  if (alertCtx.mounted) Navigator.of(alertCtx).pop();
                                  setState(() {});
                                },
                                child: const Text('Nonaktifkan'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Bersihkan Seluruh Data Finansial?',
          style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Text(
          'Tindakan ini akan menghapus seluruh catatan transaksi, pagu anggaran, target tabungan, dan mengosongkan saldo dompet Anda.',
          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
            onPressed: () {
              finance.clearAllFinancialData();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Seluruh data finansial telah dibersihkan.')),
              );
            },
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan (Settings)', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Section 0: Subscription & Admin
            _buildSectionHeader('AKUN & LANGGANAN', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.star_rounded, color: Colors.orange),
                    title: Text('Paket Langganan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    subtitle: Text('Kelola langganan ASTRACK Anda', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                  ),
                  const Divider(height: 1),
                  if (finance.profile.isAdmin) ...[
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue),
                      title: Text('Super Admin Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      subtitle: Text('Khusus Developer', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.price_change_rounded, color: AppColors.emerald),
                      title: Text('Product Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      subtitle: Text('Kelola harga produk dan durasi', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPricingScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.confirmation_number_rounded, color: Colors.purple),
                      title: Text('Coupons', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      subtitle: Text('Kelola kupon & diskon promosi', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCouponsScreen())),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1.5: Categories & Data
            _buildSectionHeader('KATEGORI & DATA', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.category_rounded, color: AppColors.primary),
                    title: Text('Kelola Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    subtitle: Text('Atur pengeluaran & pemasukan', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Appearance & Personalization
            _buildSectionHeader('PERSONALISASI & TAMPILAN', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.accentColor.getColor(isDark).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: theme.accentColor.getColor(isDark),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Tampilan & Tema',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${theme.themeMode == ThemeMode.dark ? "Gelap" : theme.themeMode == ThemeMode.light ? "Terang" : "Sistem"} · ${theme.accentColor.name} · ${theme.uiStyle.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.accentColor.getColor(isDark).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: theme.accentColor.getColor(isDark),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Bahasa Aplikasi (Language)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      theme.locale.languageCode == 'en' ? 'English (US)' : 'Bahasa Indonesia (ID)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Privacy & Security
            _buildSectionHeader('PRIVASI & KEAMANAN', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Sembunyikan Saldo saat Buka', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    subtitle: Text('Tampilkan "Rp ••••••••" secara default demi privasi', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    value: finance.hideBalance,
                    activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    onChanged: (val) => finance.toggleHideBalance(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      SecurityService.instance.isPinEnabled
                          ? Icons.lock_rounded
                          : Icons.fingerprint_rounded,
                      color: SecurityService.instance.isPinEnabled
                          ? AppColors.emerald
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                    title: Text('Kunci Biometrik / PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    subtitle: Text(
                      SecurityService.instance.isPinEnabled
                          ? 'PIN aktif · Ketuk untuk kelola keamanan'
                          : 'Aktifkan penguncian aplikasi saat tidak aktif',
                      style: TextStyle(fontSize: 12, color: SecurityService.instance.isPinEnabled ? AppColors.emerald : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (SecurityService.instance.isPinEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => _showSecurityModal(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Notifications
            _buildSectionHeader('NOTIFIKASI & PENGINGAT', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: SwitchListTile(
                title: Text('Pengingat Harian (Push Notification)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('Ingatkan saya mencatat keuangan setiap jam 20:00 malam', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                value: _isDailyReminderEnabled,
                activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                secondary: Icon(
                  _isDailyReminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: _isDailyReminderEnabled ? AppColors.emerald : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                onChanged: _toggleDailyReminder,
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Data Management
            _buildSectionHeader('MANAJEMEN DATA', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.emerald),
                    title: Text(
                      'Pusat Data & Privasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Cadangan JSON, pemulihan data, sinkronisasi cloud',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyDataScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.emerald),
                    title: Text(
                      'Sinkronisasi Google Sheets',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Pencatatan otomatis per akun ke Google Spreadsheet',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Buka tab Spreadsheet lalu klik ikon cloud di kanan atas untuk mengatur Google Sheets.'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.expense),
                    title: const Text('Bersihkan Seluruh Data Finansial', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.expense)),
                    subtitle: Text('Hapus seluruh transaksi, anggaran, dan target tabungan', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showResetConfirmDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 4: About
            _buildSectionHeader('TENTANG APLIKASI', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, size: 20),
                ),
                title: Text('Tentang ASTRACK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('Versi ${AppConfig.version} • Oleh ${AppConfig.author}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Section 5: Account Session (Logout / Conversion)
            _buildSectionHeader('SESI AKUN', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  if (finance.profile.isGuest)
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
                      title: const Text('Konversi Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      subtitle: Text('Buat akun permanen & simpan seluruh data lokal Anda', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.expense),
                    title: const Text('Keluar dari Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.expense)),
                    subtitle: Text('Kembali ke layar masuk aplikasi', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      finance.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
