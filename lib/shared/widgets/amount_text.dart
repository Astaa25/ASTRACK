import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/astrack_theme_extension.dart';

enum AmountDisplayType {
  neutral,
  income,
  expense,
  transfer,
  saving,
}

/// High-Taste Amount Text with Tabular Figures for Financial Precision
class AmountText extends StatelessWidget {
  final int amount; // Stored as integer Rupiah
  final AmountDisplayType type;
  final TextStyle? style;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool showSign;
  final bool isCompact;
  final String symbol;

  const AmountText({
    super.key,
    required this.amount,
    this.type = AmountDisplayType.neutral,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.showSign = false,
    this.isCompact = false,
    this.symbol = 'Rp',
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;

    Color color;
    switch (type) {
      case AmountDisplayType.income:
        color = theme.income;
        break;
      case AmountDisplayType.expense:
        color = theme.expense;
        break;
      case AmountDisplayType.transfer:
        color = theme.transfer;
        break;
      case AmountDisplayType.saving:
        color = theme.saving;
        break;
      case AmountDisplayType.neutral:
        color = theme.textPrimary;
        break;
    }

    final formattedText = isCompact
        ? AppLocalizations.formatCompactCurrency(amount, symbol: symbol)
        : AppLocalizations.formatCurrency(
            amount,
            symbol: symbol,
            showSign: showSign,
            isExpense: type == AmountDisplayType.expense,
          );

    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return Text(
      formattedText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontSize: fontSize ?? baseStyle?.fontSize ?? 16,
        fontWeight: fontWeight ?? baseStyle?.fontWeight ?? FontWeight.w700,
        color: style?.color ?? color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
