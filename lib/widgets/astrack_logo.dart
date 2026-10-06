import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class AstrackLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;
  final bool isDark;
  final double? fontSize;

  const AstrackLogo({
    super.key,
    this.size = 40,
    this.showWordmark = true,
    this.showTagline = false,
    this.isDark = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark;
    final primaryColor = effectiveIsDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = effectiveIsDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtleTextColor = effectiveIsDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        // Custom Geometric Symbol (ASTA + TRACK)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: effectiveIsDark ? AppColors.darkElevatedCard : AppColors.lightLightGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              color: effectiveIsDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: effectiveIsDark
                ? [
                    BoxShadow(
                      color: AppColors.darkPrimary.withOpacity(0.12),
                      blurRadius: size * 0.4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: AstrackSymbolPainter(
              strokeColor: primaryColor,
              accentColor: effectiveIsDark ? AppColors.darkLightGreen : AppColors.lightDarkGreen,
            ),
          ),
        ),

        if (showWordmark) ...[
          SizedBox(width: size * 0.25),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wordmark: Single unified word ASTRACK with subtle typographic emphasis
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'AST',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize ?? (size * 0.52),
                        letterSpacing: -0.5,
                        color: textColor,
                      ),
                    ),
                    TextSpan(
                      text: 'RACK',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize ?? (size * 0.52),
                        letterSpacing: -0.5,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 2),
                Text(
                  'Track Your Money, Shape Your Future',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w500,
                    color: subtleTextColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    ),
  );
  }
}

/// Custom Painter for the ASTRACK geometric symbol
/// Represents ASTA (structure 'A') + TRACK (continuous upward progress path)
class AstrackSymbolPainter extends CustomPainter {
  final Color strokeColor;
  final Color accentColor;
  final double progress; // For splash path animation (0.0 to 1.0)

  AstrackSymbolPainter({
    required this.strokeColor,
    required this.accentColor,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Geometric A structure
    final aPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final aPath = Path();
    aPath.moveTo(w * 0.25, h * 0.76);
    aPath.lineTo(w * 0.50, h * 0.24);
    aPath.lineTo(w * 0.75, h * 0.76);
    canvas.drawPath(aPath, aPaint);

    // Upward financial tracking path curve crossing through
    final trackPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    final trackPath = Path();
    trackPath.moveTo(w * 0.20, h * 0.58);
    trackPath.cubicTo(
      w * 0.35, h * 0.58,
      w * 0.50, h * 0.44,
      w * 0.82, h * 0.34,
    );

    if (progress >= 1.0) {
      canvas.drawPath(trackPath, trackPaint);

      // Node dot at top right
      final dotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.82, h * 0.34), w * 0.08, dotPaint);
    } else {
      // Animate path along progress
      // Extract sub-path
      final pathMetrics = trackPath.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        final metric = pathMetrics.first;
        final subPath = metric.extractPath(0.0, metric.length * progress);
        canvas.drawPath(subPath, trackPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AstrackSymbolPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor;
  }
}
