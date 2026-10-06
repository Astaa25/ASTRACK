import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/services/security_service.dart';
import '../auth/login_screen.dart';
import '../settings/about_screen.dart';
import 'admin_gateway_config_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notifyNewUser = true;
  bool _notifySecurityAlert = true;
  String _adminName = 'Administrator';
  String _adminEmail = 'admin@astrack.app';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}

    setState(() {
      _notifyNewUser = prefs.getBool('admin_notify_new_user') ?? true;
      _notifySecurityAlert = prefs.getBool('admin_notify_security') ?? true;
      if (user?.email != null) _adminEmail = user!.email!;
    });

    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && profile['full_name'] != null) {
          setState(() {
            _adminName = profile['full_name'];
          });
        }
      } catch (_) {}
    }
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _adminName);
    final pwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    bool isSaving = false;
    bool obscurePw = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
          final cardColor = isDark ? AppColors.darkCard : Colors.white;
          final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Edit Profil Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                    const SizedBox(height: 4),
                    Text('Ubah nama lengkap atau ganti password akun', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    const SizedBox(height: 20),

                    // Nama
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Baru
                    TextField(
                      controller: pwCtrl,
                      obscureText: obscurePw,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru (Opsional)',
                        hintText: 'Biarkan kosong jika tidak ingin ganti',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePw ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscurePw = !obscurePw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Konfirmasi Password
                    if (pwCtrl.text.isNotEmpty)
                      TextField(
                        controller: confirmPwCtrl,
                        obscureText: obscurePw,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi Baru',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primary),
                        onPressed: isSaving ? null : () async {
                          final newName = nameCtrl.text.trim();
                          final newPw = pwCtrl.text.trim();
                          final confirmPw = confirmPwCtrl.text.trim();

                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
                            return;
                          }

                          if (newPw.isNotEmpty) {
                            if (newPw.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter')));
                              return;
                            }
                            if (newPw != confirmPw) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok')));
                              return;
                            }
                          }

                          setModalState(() => isSaving = true);
                          try {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                              // Update profile table
                              await Supabase.instance.client
                                  .from('profiles')
                                  .update({'full_name': newName})
                                  .eq('id', user.id);

                              // Update password if provided
                              if (newPw.isNotEmpty) {
                                await Supabase.instance.client.auth.updateUser(
                                  UserAttributes(password: newPw),
                                );
                              }
                            }

                            setState(() {
                              _adminName = newName;
                            });

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Profil & kredensial berhasil diperbarui!'),
                                  backgroundColor: AppColors.income,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal memperbarui: $e')),
                            );
                          }
                        },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDark ? AppColors.darkCard : Colors.white;
          final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferensi Notifikasi Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Notifikasi Pendaftaran User', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
                  subtitle: const Text('Kirim pemberitahuan saat ada akun baru menunggu verifikasi', style: TextStyle(fontSize: 12)),
                  value: _notifyNewUser,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('admin_notify_new_user', val);
                    setState(() => _notifyNewUser = val);
                    setSheetState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text('Peringatan Keamanan & Audit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
                  subtitle: const Text('Dapatkan info saat ada aktivitas mencurigakan atau perubahan role', style: TextStyle(fontSize: 12)),
                  value: _notifySecurityAlert,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('admin_notify_security', val);
                    setState(() => _notifySecurityAlert = val);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSecurityModal() {
    final security = SecurityService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
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
                Text('Keamanan Biometrik & PIN Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Kunci Aplikasi dengan PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
                  subtitle: Text(security.isPinEnabled ? 'PIN 6-digit aktif saat membuka aplikasi' : 'Aplikasi belum terkunci PIN', style: const TextStyle(fontSize: 12)),
                  value: security.isPinEnabled,
                  onChanged: (val) async {
                    if (val) {
                      await security.setPin('123456'); // Default setup
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Default diatur ke 123456. Bisa diubah kapan saja.')));
                    } else {
                      await security.removePin();
                    }
                    setSheetState(() {});
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textS = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Pengaturan Admin', style: TextStyle(color: textP, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textP),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profil Admin Card with working Edit
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: primary,
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                title: Text(_adminName, style: TextStyle(color: textP, fontWeight: FontWeight.w700, fontSize: 16)),
                subtitle: Text('$_adminEmail • Administrator', style: TextStyle(color: textS, fontSize: 13)),
                trailing: IconButton(
                  icon: Icon(Icons.edit_rounded, color: primary, size: 22),
                  onPressed: _showEditProfileModal,
                ),
                onTap: _showEditProfileModal,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tampilan & Tema
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, theme, _) {
                      return SwitchListTile(
                        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: primary),
                        title: Text('Mode Gelap', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                        value: isDark,
                        activeColor: primary,
                        onChanged: (_) => theme.toggleTheme(),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.fingerprint, color: primary),
                    title: Text('Kunci Biometrik / PIN', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showSecurityModal,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: primary),
                    title: Text('Notifikasi & Alert', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showNotificationModal,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.hub_rounded, color: primary),
                    title: Text('Payment Gateway & Mode', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                    subtitle: Text('Konfigurasi QRIS manual, Midtrans, Xendit, Stripe & Sandbox', style: TextStyle(color: textS, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGatewayConfigScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: primary),
                    title: Text('Tentang ASTRACK', style: TextStyle(color: textP, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.expense),
                title: const Text('Keluar (Logout)', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
                onTap: () async {
                  final finance = Provider.of<FinanceProvider>(context, listen: false);
                  finance.logout();
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
