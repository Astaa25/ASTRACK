import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/astrack_logo.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../update/models/app_update_info.dart';
import '../update/services/app_update_service.dart';
import '../update/screens/force_update_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pathController;
  late AnimationController _textController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pathAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pathController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);
    _pathAnimation = CurvedAnimation(parent: _pathController, curve: Curves.easeInOut);
    _textAnimation = CurvedAnimation(parent: _textController, curve: Curves.easeOut);

    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // 1. Background fades in
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 150));

    // 2. ASTRACK symbol appears (fade + scale)
    _scaleController.forward();

    // 3. Tracking path line animation
    await Future.delayed(const Duration(milliseconds: 200));
    _pathController.forward();

    // 4. Wordmark & Tagline reveal
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();

    // 5. Total initialization target 1.4 seconds
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Check login session & onboarding state
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final profile = finance.profile;

    if (!mounted) return;

    // Check for APK update (fail-open offline)
    try {
      final (updateStatus, updateInfo) = await AppUpdateService().check();
      if (!mounted) return;
      if (updateStatus == UpdateStatus.forced && updateInfo != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ForceUpdateScreen(info: updateInfo)),
        );
        return;
      }
    } catch (_) {}

    Widget destination;
    if (profile.isLoggedIn) {
      // User is already logged in → persist session to AdminDashboard or Dashboard
      destination = profile.isAdmin ? const AdminDashboardScreen() : const DashboardScreen();
    } else if (!onboardingDone && !profile.hasCompletedOnboarding) {
      // First install → show onboarding feature slides
      destination = const OnboardingScreen();
    } else {
      // Not logged in or logged out → show login screen
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pathController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? AppColors.darkDeepBg : Colors.white;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtleTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle emerald radial glow in Dark Mode
          if (isDark)
            Positioned(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.darkPrimary.withOpacity(0.12 * _fadeAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Central Branding Presentation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated ASTRACK Symbol
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevatedCard : AppColors.lightLightGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1.5,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: AppColors.darkPrimary.withOpacity(0.20),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: AppColors.lightPrimary.withOpacity(0.08),
                                  blurRadius: 20,
                                )
                              ],
                      ),
                      child: AnimatedBuilder(
                        animation: _pathAnimation,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(80, 80),
                            painter: AstrackSymbolPainter(
                              strokeColor: primaryColor,
                              accentColor: isDark ? AppColors.darkLightGreen : AppColors.lightDarkGreen,
                              progress: _pathAnimation.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated Wordmark
                FadeTransition(
                  opacity: _textAnimation,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'AST',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                            letterSpacing: -0.5,
                            color: textColor,
                          ),
                        ),
                        TextSpan(
                          text: 'RACK',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 32,
                            letterSpacing: -0.5,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline: Track Your Money, Shape Your Future
                FadeTransition(
                  opacity: _textAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      AppConfig.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtleTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Minimal Thin Loading Indicator
                FadeTransition(
                  opacity: _textAnimation,
                  child: SizedBox(
                    width: 48,
                    height: 2.5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
