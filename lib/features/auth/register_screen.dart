import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  int _step = 1; // 1 = Detail Akun, 2 = Selesai (Menunggu Approval)

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.expense : AppColors.income,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnack('Nama dan email wajib diisi.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('Kata sandi minimal 6 karakter.');
      return;
    }
    if (pass != confirm) {
      _showSnack('Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseAuthService.signUp(email, pass, name);
      if (response.user == null) throw Exception('Pendaftaran gagal. Silakan coba lagi.');

      // Wait for trigger to create profile, though we can assume it's pending
      setState(() {
        _isLoading = false;
        _anim.reset();
        _step = 2; // Move to waiting for approval screen
        _anim.forward();
      });
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bgColor = isDark ? AppColors.darkDeepBg : const Color(0xFFF5FAF7);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textS = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: primary,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Header
          Container(
            color: primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20, right: 20, bottom: 20,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 1 ? 'Buat Akun ASTRACK' : 'Menunggu Persetujuan',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _step == 1 ? 'Lengkapi data diri Anda di bawah' : 'Akun Anda sedang ditinjau Admin',
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: FadeTransition(
                opacity: _fade,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 32, left: 24, right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: _step == 1
                      ? _buildForm(isDark, primary, cardColor, textP, textS)
                      : _buildWaitingScreen(isDark, primary, cardColor, textP, textS),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, Color primary, Color cardColor, Color textP, Color textS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Nama Lengkap', textP),
              const SizedBox(height: 8),
              _buildField(controller: _nameCtrl, hint: 'Contoh: Asta Abrar', icon: Icons.person_outline_rounded, isDark: isDark, primary: primary),
              const SizedBox(height: 20),

              _fieldLabel('Alamat Email', textP),
              const SizedBox(height: 8),
              _buildField(controller: _emailCtrl, hint: 'nama@email.com', icon: Icons.mail_outline_rounded, isDark: isDark, primary: primary),
              const SizedBox(height: 20),

              _fieldLabel('Kata Sandi', textP),
              const SizedBox(height: 8),
              _buildField(
                controller: _passCtrl, hint: 'Minimal 6 karakter', icon: Icons.lock_outline_rounded,
                isDark: isDark, primary: primary, obscure: _obscurePass,
                suffix: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textS),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 20),

              _fieldLabel('Konfirmasi Kata Sandi', textP),
              const SizedBox(height: 8),
              _buildField(
                controller: _confirmPassCtrl, hint: 'Ulangi kata sandi', icon: Icons.lock_outline_rounded,
                isDark: isDark, primary: primary, obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textS),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingScreen(bool isDark, Color primary, Color cardColor, Color textP, Color textS) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.admin_panel_settings_rounded, size: 64, color: AppColors.warning),
          ),
          const SizedBox(height: 24),
          Text(
            'Menunggu Persetujuan Admin',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.w800, color: textP),
          ),
          const SizedBox(height: 12),
          Text(
            'Akun Anda telah berhasil dibuat, namun saat ini statusnya masih dikunci. Admin ASTRACK perlu memverifikasi dan menyetujui akun Anda terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: textS),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali ke Login', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, Color color) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color));

  Widget _buildField({
    required TextEditingController controller,
    required String hint, required IconData icon,
    required bool isDark, required Color primary,
    bool obscure = false, Widget? suffix,
  }) {
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? AppColors.darkElevatedCard : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderCol)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderCol)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
      ),
    );
  }
}
