import 'package:flutter/material.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_radius.dart';

enum PlanTypeVariant {
  free,
  basic,
  pro,
}

/// Refined Badge for Subscription Plan Identification
class PlanBadge extends StatelessWidget {
  final PlanTypeVariant variant;
  final String? customLabel;

  const PlanBadge({
    super.key,
    required this.variant,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;

    Color bgColor;
    Color textColor;
    Color borderColor;
    String label;

    switch (variant) {
      case PlanTypeVariant.pro:
        bgColor = theme.primaryEmerald.withValues(alpha: 0.15);
        textColor = theme.primaryEmerald;
        borderColor = theme.primaryEmerald.withValues(alpha: 0.4);
        label = customLabel ?? 'PRO';
        break;
      case PlanTypeVariant.basic:
        bgColor = theme.warning.withValues(alpha: 0.15);
        textColor = theme.warning;
        borderColor = theme.warning.withValues(alpha: 0.4);
        label = customLabel ?? 'BASIC';
        break;
      case PlanTypeVariant.free:
        bgColor = theme.surfaceSubtle;
        textColor = theme.textSecondary;
        borderColor = theme.border;
        label = customLabel ?? 'FREE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.sm,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
