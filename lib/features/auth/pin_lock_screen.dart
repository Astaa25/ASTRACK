import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/services/security_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

enum PinMode {
  create,
  confirm,
  unlock,
  change,
}

class PinLockScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;
  final String? originalPin; // Used during create -> confirm transition

  const PinLockScreen({
    super.key,
    required this.mode,
    this.onSuccess,
    this.originalPin,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _shakeAnimCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeAnimCtrl);

    // If unlock mode and biometric enabled, trigger biometric simulation
    if (widget.mode == PinMode.unlock && SecurityService.instance.isBiometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _simulateBiometric();
      });
    }
  }

  @override
  void dispose() {
    _shakeAnimCtrl.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (_isLoading) return;
    if (_pin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += key;
        _errorMessage = '';
      });

      if (_pin.length == 6) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_isLoading) return;
    if (_pin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _triggerError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = msg;
      _pin = '';
    });
    _shakeAnimCtrl.forward(from: 0.0);
  }

  void _handlePinComplete() async {
    setState(() => _isLoading = true);
    final security = SecurityService.instance;

    switch (widget.mode) {
      case PinMode.create:
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PinLockScreen(
              mode: PinMode.confirm,
              originalPin: _pin,
              onSuccess: widget.onSuccess,
            ),
          ),
        );
        break;

      case PinMode.confirm:
        if (_pin == widget.originalPin) {
          await security.setPin(_pin);
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN Keamanan 6-digit berhasil diaktifkan!'),
                backgroundColor: AppColors.income,
              ),
            );
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          setState(() => _isLoading = false);
          _triggerError('PIN konfirmasi tidak cocok. Coba lagi.');
        }
        break;

      case PinMode.unlock:
        if (security.isLockedOut) {
          setState(() => _isLoading = false);
          _triggerError('Terlalu banyak percobaan salah. Tunggu ${security.remainingLockoutSeconds} detik.');
          break;
        }
        final isValid = await security.verifyPin(_pin);
        setState(() => _isLoading = false);
        if (isValid) {
          if (mounted) {
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            }
          }
        } else {
          if (security.isLockedOut) {
            _triggerError('Akun terkunci sementara! Coba lagi dalam ${security.remainingLockoutSeconds} detik.');
          } else {
            _triggerError('PIN salah (${security.failedAttempts}/5). Silakan coba lagi.');
          }
        }
        break;

      case PinMode.change:
        final isValid = await security.verifyPin(_pin);
        setState(() => _isLoading = false);
        if (isValid) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PinLockScreen(
                  mode: PinMode.create,
                  onSuccess: widget.onSuccess,
                ),
              ),
            );
          }
        } else {
          _triggerError('PIN lama salah.');
        }
        break;
    }
  }

  void _simulateBiometric() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 44, color: AppColors.emerald),
              ),
              const SizedBox(height: 16),
              const Text(
                'Autentikasi Biometrik',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sentuh sensor sidik jari atau hadapkan wajah ke layar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Gunakan PIN'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        setState(() => _isLoading = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        SecurityService.instance.unlockApp();
                        if (!mounted) return;
                        if (widget.onSuccess != null) {
                          widget.onSuccess!();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          );
                        }
                      },
                      child: const Text('Verifikasi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showForgotPinDialog() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final email = finance.profile.email;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lupa PIN Keamanan?'),
        content: Text(
          'Demi perlindungan data finansial Anda, reset PIN memerlukan verifikasi kata sandi akun ($email). Silakan keluar dan masuk kembali menggunakan kata sandi Anda untuk mengatur ulang PIN keamanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              finance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar & Masuk Ulang'),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case PinMode.create:
        return 'Buat PIN Keamanan';
      case PinMode.confirm:
        return 'Konfirmasi PIN';
      case PinMode.unlock:
        return 'Masukkan PIN';
      case PinMode.change:
        return 'Masukkan PIN Lama';
    }
  }

  String _getSubtitle() {
    switch (widget.mode) {
      case PinMode.create:
        return 'Buat 6 digit PIN untuk mengamankan data finansial ASTRACK';
      case PinMode.confirm:
        return 'Ketik ulang 6 digit PIN yang sama untuk verifikasi';
      case PinMode.unlock:
        return 'Masukkan 6 digit PIN Anda untuk membuka aplikasi';
      case PinMode.change:
        return 'Verifikasi identitas Anda dengan PIN saat ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bgColor = isDark ? AppColors.darkDeepBg : const Color(0xFFF6FAF7);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (widget.mode != PinMode.unlock)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  // Logo Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ASTRACK SAFE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Icon & Header
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withAlpha(70),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.mode == PinMode.unlock ? Icons.lock_outline_rounded : Icons.lock_reset_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'Plus Jakarta Sans',
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _getSubtitle(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ),

            const SizedBox(height: 28),

            // 6 PIN Dots (Animated with shake on error)
            AnimatedBuilder(
              animation: _shakeAnimCtrl,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnim.value * (1 - _shakeAnimCtrl.value), 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final isFilled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isFilled ? 18 : 14,
                    height: isFilled ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? primary : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? primary : textSecondary.withAlpha(80),
                        width: 2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: primary.withAlpha(120),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            // Error message
            SizedBox(
              height: 32,
              child: Center(
                child: _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Memproses PIN...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          )
                        : null,
              ),
            ),

            const Spacer(flex: 2),

            // Custom Numeric Keypad
            IgnorePointer(
              ignoring: _isLoading,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isLoading ? 0.6 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildKeypadRow(['1', '2', '3'], textPrimary, isDark),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['4', '5', '6'], textPrimary, isDark),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['7', '8', '9'], textPrimary, isDark),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Biometric / Forgot PIN button
                          if (widget.mode == PinMode.unlock && SecurityService.instance.isBiometricEnabled)
                            _buildKeypadButton(
                              child: const Icon(Icons.fingerprint_rounded, size: 28, color: AppColors.emerald),
                              onTap: _simulateBiometric,
                              isDark: isDark,
                            )
                          else if (widget.mode == PinMode.unlock)
                            TextButton(
                              onPressed: _showForgotPinDialog,
                              child: const Text('Lupa?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            )
                          else
                            const SizedBox(width: 72, height: 72),

                          // Digit 0
                          _buildDigitButton('0', textPrimary, isDark),

                          // Backspace
                          _buildKeypadButton(
                            child: Icon(Icons.backspace_outlined, size: 22, color: textPrimary),
                            onTap: _onBackspace,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            if (widget.mode == PinMode.unlock)
              Column(
                children: [
                  TextButton(
                    onPressed: _showForgotPinDialog,
                    child: Text(
                      'Lupa PIN Keamanan?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final finance = Provider.of<FinanceProvider>(context, listen: false);
                      SecurityService.instance.unlockApp();
                      finance.logout();
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Login dengan akun lain'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, Color textColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d, textColor, isDark)).toList(),
    );
  }

  Widget _buildDigitButton(String digit, Color textColor, bool isDark) {
    return _buildKeypadButton(
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          fontFamily: 'Plus Jakarta Sans',
          color: textColor,
        ),
      ),
      onTap: () => _onKeyPressed(digit),
      isDark: isDark,
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
