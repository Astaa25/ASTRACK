import 'package:flutter/material.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_radius.dart';
import 'amount_text.dart';

/// KPI / Metric Tile for Dashboard and Financial Reports
class StatTile extends StatelessWidget {
  final String label;
  final int? amount;
  final String? customValue;
  final AmountDisplayType amountType;
  final double? trendPercent;
  final bool isTrendPositive;
  final IconData? icon;

  const StatTile({
    super.key,
    required this.label,
    this.amount,
    this.customValue,
    this.amountType = AmountDisplayType.neutral,
    this.trendPercent,
    this.isTrendPositive = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: theme.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: theme.textSecondary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),
              ),
              if (trendPercent != null) ...[
                Icon(
                  isTrendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: isTrendPositive ? theme.income : theme.expense,
                ),
                const SizedBox(width: 2),
                Text(
                  '${trendPercent!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isTrendPositive ? theme.income : theme.expense,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (amount != null)
            AmountText(
              amount: amount!,
              type: amountType,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )
          else if (customValue != null)
            Text(
              customValue!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
