import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../services/supabase_auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;

    final profile = finance.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // User Avatar & Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.18),
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0] : 'A',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.isGuest ? 'Mode Tamu (Offline)' : 'Akun Terverifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightDarkGreen,
                      ),
                    ),
                  ),
                  if (!profile.isGuest) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileModal(context, finance),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Profil & Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Sumber Dana', '${finance.sources.length} Akun', isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard('Transaksi', '${finance.transactions.length} Total', isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard('Target Tabungan', '${finance.savings.length} Impian', isDark),
                ),
              ],
            ),

            if (profile.isGuest) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text(
                    'Konversi Akun (Simpan Data Saya)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  await SupabaseAuthService.signOut();
                  finance.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        ],
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, FinanceProvider finance) {
    final nameCtrl = TextEditingController(text: finance.profile.name);
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
                    Text('Edit Profil & Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP)),
                    const SizedBox(height: 4),
                    Text('Ubah nama tampilan atau ganti kata sandi akun', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                              await Supabase.instance.client
                                  .from('profiles')
                                  .update({
                                    'full_name': newName,
                                    'updated_at': DateTime.now().toIso8601String(),
                                  })
                                  .eq('id', user.id);

                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(
                                  data: {'full_name': newName},
                                  password: newPw.isNotEmpty ? newPw : null,
                                ),
                              );
                            }

                            finance.updateProfile(
                              finance.profile.copyWith(name: newName),
                            );

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Profil & kata sandi berhasil disimpan!'),
                                  backgroundColor: AppColors.income,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal memperbarui profil: $e')),
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
}
