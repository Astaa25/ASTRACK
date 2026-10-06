import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/astrack_logo.dart';
import '../../widgets/brand_illustrations.dart';
import 'onboarding_screen.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoadingStart = false;
  bool _isLoadingLogin = false;

  void _onStart() async {
    setState(() => _isLoadingStart = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoadingStart = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _onLogin() async {
    setState(() => _isLoadingLogin = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoadingLogin = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isAnyLoading = _isLoadingStart || _isLoadingLogin;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Brand Header
              Column(
                children: [
                  const SizedBox(height: 12),
                  AstrackLogo(
                    size: 48,
                    showWordmark: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConfig.tagline,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                ],
              ),

              // Hero Illustration
              Column(
                children: [
                  OnboardingCardIllustration(
                    isDark: isDark,
                    width: 320,
                    height: 200,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Kelola Finansial Lebih Tenang,\nRencanakan Masa Depan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Catat pemasukan, pengeluaran, tabungan, dan pantau seluruh sumber dana Anda dalam satu aplikasi modern.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Column(
                children: [
                  // 1. Get Started
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: isAnyLoading ? null : _onStart,
                      child: _isLoadingStart
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Mulai Sekarang',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Login
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isAnyLoading ? null : _onLogin,
                      child: _isLoadingLogin
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            )
                          : const Text(
                              'Masuk ke Akun',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
