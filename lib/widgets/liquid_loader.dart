import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import 'astrack_logo.dart';

/// Ultra-smooth, engaging Liquid Loader for ASTRACK.
/// Replaces standard boring CircularProgressIndicators with:
/// 1. Glowing orbital liquid rings
/// 2. Breathing ASTRACK geometric core
/// 3. Dynamic rotating financial insight status messages (fade & slide)
class AstrackLiquidLoader extends StatefulWidget {
  final String? initialMessage;
  final bool showRotatingTips;
  final double size;
  final bool isCompact;
  final Color? accentColor;

  const AstrackLiquidLoader({
    super.key,
    this.initialMessage,
    this.showRotatingTips = true,
    this.size = 80,
    this.isCompact = false,
    this.accentColor,
  });

  /// Compact mini liquid loader for small widgets, buttons, and tiles
  const AstrackLiquidLoader.compact({
    super.key,
    this.size = 24,
    this.accentColor,
  })  : isCompact = true,
        showRotatingTips = false,
        initialMessage = null;

  /// Full-screen or modal centered loader with rich status tips
  const AstrackLiquidLoader.full({
    super.key,
    this.initialMessage,
    this.size = 88,
    this.accentColor,
  })  : isCompact = false,
        showRotatingTips = true;

  @override
  State<AstrackLiquidLoader> createState() => _AstrackLiquidLoaderState();
}

class _AstrackLiquidLoaderState extends State<AstrackLiquidLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _tipTimer;
  int _tipIndex = 0;

  static const List<String> _financialTips = [
    'Menyelaraskan buku kas & transaksi...',
    'Menganalisis arus kas & likuiditas...',
    'Menyiapkan insight finansial cerdas...',
    'Mengamankan data finansial dengan enkripsi...',
    'Menghitung proyeksi pertumbuhan aset...',
    'Memvalidasi saldo sumber dana...',
    'Hampir selesai, memoles laporanmu...',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    if (widget.showRotatingTips && !widget.isCompact) {
      _tipTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
        if (mounted) {
          setState(() {
            _tipIndex = (_tipIndex + 1) % _financialTips.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = widget.accentColor ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    if (widget.isCompact) {
      return _buildCompact(primary, isDark);
    }

    final currentMsg = widget.initialMessage ?? _financialTips[_tipIndex];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── Liquid Orb & Core ───
          SizedBox(
            width: widget.size * 1.3,
            height: widget.size * 1.3,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer liquid aura pulse
                    CustomPaint(
                      size: Size(widget.size * 1.3, widget.size * 1.3),
                      painter: _LiquidAuraPainter(
                        animationValue: _animController.value,
                        primaryColor: primary,
                        isDark: isDark,
                      ),
                    ),

                    // Rotating orbital liquid ring
                    Transform.rotate(
                      angle: _animController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size * 1.05, widget.size * 1.05),
                        painter: _LiquidOrbitalRingPainter(
                          primaryColor: primary,
                          accentColor: isDark
                              ? AppColors.darkLightGreen
                              : AppColors.lightDarkGreen,
                        ),
                      ),
                    ),

                    // Counter-rotating inner ring
                    Transform.rotate(
                      angle: -_animController.value * 2 * math.pi * 0.75,
                      child: CustomPaint(
                        size: Size(widget.size * 0.85, widget.size * 0.85),
                        painter: _LiquidInnerRingPainter(
                          primaryColor: primary.withOpacity(0.6),
                        ),
                      ),
                    ),

                    // Breathing Center Logo Badge
                    Transform.scale(
                      scale: 0.94 + 0.08 * math.sin(_animController.value * 2 * math.pi),
                      child: Container(
                        width: widget.size * 0.52,
                        height: widget.size * 0.52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkCard : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(isDark ? 0.35 : 0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: Size(widget.size * 0.32, widget.size * 0.32),
                            painter: AstrackSymbolPainter(
                              strokeColor: primary,
                              accentColor: isDark
                                  ? AppColors.darkLightGreen
                                  : AppColors.lightDarkGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ─── Smooth Rotating Status Messages ───
          if (widget.showRotatingTips || widget.initialMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.25),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  currentMsg,
                  key: ValueKey<String>(currentMsg),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // ─── Indeterminate Liquid Shimmer Capsule Bar ───
          Container(
            width: 110,
            height: 3.5,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final pos = (_animController.value * 2) - 0.5;
                return FractionalTranslation(
                  translation: Offset(pos, 0),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.0),
                          primary,
                          primary.withOpacity(0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(Color primary, bool isDark) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Transform.rotate(
            angle: _animController.value * 2 * math.pi,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CompactLiquidPainter(
                primaryColor: primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper method to show sleek glass loading dialog
void showAstrackLoadingDialog(
  BuildContext context, {
  String? message,
  bool barrierDismissible = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withOpacity(0.92)
                  : Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AstrackLiquidLoader.full(
              initialMessage: message,
              size: 80,
            ),
          ),
        ),
      );
    },
  );
}

// ─── Custom Painters for Liquid Motion ────────────────────────────────────────

class _LiquidAuraPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final bool isDark;

  _LiquidAuraPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final pulse = 0.85 + 0.15 * math.sin(animationValue * 2 * math.pi);
    final auraRadius = maxRadius * pulse;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(isDark ? 0.28 : 0.18),
          primaryColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: auraRadius));

    canvas.drawCircle(center, auraRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidAuraPainter oldDelegate) => true;
}

class _LiquidOrbitalRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _LiquidOrbitalRingPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.0),
          primaryColor.withOpacity(0.3),
          accentColor,
          primaryColor,
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 1.5, false, paint);

    // Glowing liquid droplet tip
    final dropletPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final tipAngle = math.pi * 1.5;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    canvas.drawCircle(Offset(tipX, tipY), 3.5, dropletPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidOrbitalRingPainter oldDelegate) => false;
}

class _LiquidInnerRingPainter extends CustomPainter {
  final Color primaryColor;

  _LiquidInnerRingPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.0),
          primaryColor,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 1.1, false, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidInnerRingPainter oldDelegate) => false;
}

class _CompactLiquidPainter extends CustomPainter {
  final Color primaryColor;

  _CompactLiquidPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.05),
          primaryColor.withOpacity(0.4),
          primaryColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 1.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CompactLiquidPainter oldDelegate) => false;
}
