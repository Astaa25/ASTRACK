import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/storage/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final storage = StorageService();
        await storage.init();
        final regEmail = storage.getRegisteredEmail();
        if (mounted && regEmail != null && regEmail.isNotEmpty && _emailController.text.isEmpty) {
          setState(() {
            _emailController.text = regEmail;
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSnack('Silakan masukkan alamat email Anda.');
      return;
    }
    if (password.isEmpty) {
      _showSnack('Silakan masukkan kata sandi Anda.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final response = await SupabaseAuthService.signIn(email, password);
      if (response.user == null) throw Exception('Login failed');

      final status = await SupabaseAuthService.getUserStatus(response.user!.id);
      
      if (status == 'pending') {
        setState(() => _isLoading = false);
        _showSnack('Akun Anda masih menunggu persetujuan Admin.');
        await SupabaseAuthService.signOut();
        return;
      } else if (status == 'rejected') {
        setState(() => _isLoading = false);
        _showSnack('Pendaftaran akun Anda ditolak oleh Admin.');
        await SupabaseAuthService.signOut();
        return;
      }

      final isAdmin = await SupabaseAuthService.isAdmin(response.user!.id, email: email);

      // Sync with FinanceProvider for local state compatibility
      final finance = Provider.of<FinanceProvider>(context, listen: false);

      // Fetch latest name from Supabase profiles table, fallback to userMetadata & local cache
      String userFullName = '';
      try {
        final profileRow = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', response.user!.id)
            .maybeSingle();
        if (profileRow != null && profileRow['full_name'] != null && profileRow['full_name'].toString().trim().isNotEmpty) {
          userFullName = profileRow['full_name'].toString().trim();
        }
      } catch (_) {}

      if (userFullName.isEmpty) {
        userFullName = response.user?.userMetadata?['full_name']?.toString().trim() ?? '';
      }

      if (userFullName.isEmpty) {
        final local = finance.profile;
        if (local.email.trim().toLowerCase() == email.trim().toLowerCase() && local.name.isNotEmpty && local.name != 'Pengguna Baru') {
          userFullName = local.name;
        } else {
          userFullName = email.split('@').first;
        }
      }

      finance.login(
        email: email,
        password: password,
        name: userFullName,
        isAdmin: isAdmin,
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => isAdmin ? const AdminDashboardScreen() : const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
        _showSnack(
          'Kata sandi salah atau tidak cocok. Silakan periksa kembali atau reset sandi.',
          actionLabel: 'Lupa Sandi?',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            );
          },
        );
      } else if (msg.contains('email not confirmed')) {
        _showSnack('Email belum dikonfirmasi! Silakan periksa folder masuk atau spam email Anda untuk verifikasi.');
      } else if (msg.contains('user not found')) {
        _showSnack('Akun dengan email ini belum terdaftar.');
      } else {
        _showSnack(e.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final raw = e.toString().replaceAll('Exception: ', '');
      _showSnack('Gagal masuk: $raw');
    }
  }

  void _showSnack(String msg, {String? actionLabel, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.expense,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.amberAccent,
              onPressed: onAction,
            )
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bgColor = isDark ? AppColors.darkDeepBg : const Color(0xFFF5FAF7);
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: primary,
      // Key fix: resizeToAvoidBottomInset handles keyboard
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── HEADER brand (fixed, collapses on scroll) ───────────
          Container(
            color: primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 20,
            ),
            child: Row(
              children: [
                // Logo icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.track_changes_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                // Full wordmark — never truncated
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'AST',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextSpan(
                        text: 'RACK',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Colors.white.withAlpha(200),
                  ),
                  onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                ),
              ],
            ),
          ),

          // ── SCROLLABLE FORM card ─────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 28,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang Kembali 👋',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masuk untuk memantau keuangan dan masa depan finansial Anda.',
                              style: TextStyle(fontSize: 13, color: textSecondary),
                            ),
                            const SizedBox(height: 22),

                            // Email
                            _fieldLabel('Email', textPrimary),
                            const SizedBox(height: 6),
                            _buildField(
                              controller: _emailController,
                              hint: 'nama@email.com',
                              icon: Icons.mail_outline_rounded,
                              isDark: isDark,
                              border: border,
                              bgColor: bgColor,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 14),

                            // Password
                            _fieldLabel('Kata Sandi', textPrimary),
                            const SizedBox(height: 6),
                            _buildField(
                              controller: _passwordController,
                              hint: 'Masukkan kata sandi',
                              icon: Icons.lock_outline_rounded,
                              isDark: isDark,
                              border: border,
                              bgColor: bgColor,
                              obscure: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                ),
                                child: Text(
                                  'Lupa Kata Sandi?',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5, color: Colors.white))
                                    : const Text(
                                        'Masuk ke Akun',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Register
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primary,
                                  side: BorderSide(color: border, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(context)
                                        .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                child: const Text(
                                  'Buat Akun Baru',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color border,
    required Color bgColor,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon,
            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
            size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkElevatedCard : const Color(0xFFF7FAF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
