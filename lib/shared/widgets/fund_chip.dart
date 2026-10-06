import 'package:flutter/material.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/localization/app_localizations.dart';

/// Reusable Fund Chip for "Uang Jajan", "Tabungan", etc.
class FundChip extends StatelessWidget {
  final String title;
  final int? balance;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const FundChip({
    super.key,
    required this.title,
    this.balance,
    this.icon = Icons.account_balance_wallet_outlined,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;

    final bgColor = isSelected
        ? theme.primaryAccent.withValues(alpha: 0.12)
        : theme.surfaceSubtle;
    final borderColor = isSelected
        ? theme.primaryAccent
        : theme.border;
    final iconColor = isSelected
        ? theme.primaryAccent
        : theme.textSecondary;
    final textColor = isSelected
        ? theme.primaryAccent
        : theme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.getDuration(context, AppMotion.fast),
        curve: AppMotion.enterCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: theme.chipBorderRadius,
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (balance != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.formatCurrency(balance!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.primaryAccent : theme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
