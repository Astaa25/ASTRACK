import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Mohon masukkan alamat email yang valid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseAuthService.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      String friendlyMessage = 'Gagal mengirim email reset kata sandi. Periksa koneksi internet Anda.';

      if (errorStr.contains('rate limit') || errorStr.contains('429') || errorStr.contains('over_email_send_rate_limit')) {
        friendlyMessage = 'Terlalu banyak permintaan dalam waktu singkat. Mohon tunggu 5-10 menit sebelum mencoba kembali.';
      } else if (errorStr.contains('user not found')) {
        friendlyMessage = 'Email tidak terdaftar di sistem ASTRACK.';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = friendlyMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          isIndonesian ? 'Lupa Kata Sandi' : 'Forgot Password',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: primary.withAlpha(25),
                              shape: BoxShape.circle,
                              border: Border.all(color: primary.withAlpha(60), width: 1.5),
                            ),
                            child: Icon(
                              _emailSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                              color: primary,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          _emailSent
                              ? (isIndonesian ? 'Tautan Reset Terkirim' : 'Reset Link Sent')
                              : (isIndonesian ? 'Pemulihan Kata Sandi' : 'Recover Account'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _emailSent
                              ? (isIndonesian
                                  ? 'Kami telah mengirimkan tautan pemulihan kata sandi ke ${_emailController.text.trim()}. Silakan periksa kotak masuk atau folder spam email Anda.'
                                  : 'We have sent a password reset link to ${_emailController.text.trim()}. Please check your inbox or spam folder.')
                              : (isIndonesian
                                  ? 'Masukkan email yang terdaftar pada akun ASTRACK Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi Anda.'
                                  : 'Enter the email address registered with your ASTRACK account. We will send a secure link to reset your password.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (!_emailSent) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isIndonesian ? 'Email Terdaftar' : 'Registered Email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 14, color: textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'nama@email.com',
                                    hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                                    prefixIcon: Icon(Icons.email_outlined, color: primary, size: 20),
                                    isDense: true,
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkDeepBg : const Color(0xFFF8FAFC),
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
                                      borderSide: BorderSide(color: primary, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.emerald.withAlpha(60)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppColors.emerald, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isIndonesian
                                        ? 'Setelah mengetuk tautan di email, Anda dapat langsung memasukkan kata sandi baru atau menggunakan layar set kata sandi baru di bawah ini.'
                                        : 'After clicking the email link, you can set a new password directly.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.expense.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.expense),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    Column(
                      children: [
                        const SizedBox(height: 24),
                        if (!_emailSent) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isLoading ? null : _handleSendResetEmail,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Text(
                                      isIndonesian ? 'Kirim Tautan Pemulihan' : 'Send Recovery Link',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.password_rounded, color: Colors.white),
                              label: Text(
                                isIndonesian ? 'Masukkan Kata Sandi Baru' : 'Set New Password',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            isIndonesian ? 'Kembali ke Layar Masuk' : 'Back to Login',
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
