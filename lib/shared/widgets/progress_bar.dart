import 'package:flutter/material.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_radius.dart';
import '../../core/theme/tokens/app_motion.dart';

/// Refined Progress Bar with Semantic Color Transitions and Milestone Indicators
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0+
  final double height;
  final bool enableSemanticColors;
  final Color? customColor;
  final List<double>? milestones; // e.g. [0.5, 0.8]

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.enableSemanticColors = true,
    this.customColor,
    this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;
    final clamped = progress.clamp(0.0, 1.0);

    Color fillColor;
    if (customColor != null) {
      fillColor = customColor!;
    } else if (enableSemanticColors) {
      if (progress >= 1.0) {
        fillColor = theme.expense;
      } else if (progress >= 0.8) {
        fillColor = theme.warning;
      } else {
        fillColor = theme.primaryAccent;
      }
    } else {
      fillColor = theme.primaryAccent;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final isReduceMotion = AppMotion.isReduceMotion(context);

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background track
            Container(
              width: totalWidth,
              height: height,
              decoration: BoxDecoration(
                color: theme.surfaceSubtle,
                borderRadius: AppRadius.full,
              ),
            ),
            // Animated fill
            AnimatedContainer(
              duration: isReduceMotion ? Duration.zero : AppMotion.normal,
              curve: AppMotion.enterCurve,
              width: totalWidth * clamped,
              height: height,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: AppRadius.full,
              ),
            ),
            // Milestone markers
            if (milestones != null)
              ...milestones!.map((m) {
                final markPos = totalWidth * m.clamp(0.0, 1.0);
                return Positioned(
                  left: markPos - 1.5,
                  child: Container(
                    width: 3,
                    height: height + 4,
                    decoration: BoxDecoration(
                      color: theme.border,
                      borderRadius: AppRadius.full,
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
