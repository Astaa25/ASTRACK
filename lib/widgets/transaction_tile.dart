import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../app/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../core/widgets/app_card.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final bool isDark;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.item,
    required this.isDark,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color amountColor;
    String sign = '';
    IconData icon;
    Color iconBg;

    switch (item.type) {
      case TransactionType.income:
        amountColor = isDark ? AppColors.incomeDark : AppColors.income;
        sign = '+';
        icon = Icons.arrow_downward_rounded;
        iconBg = amountColor;
        break;
      case TransactionType.expense:
        amountColor = isDark ? AppColors.expenseDark : AppColors.expense;
        sign = '-';
        icon = _getCategoryIcon(item.categoryName);
        iconBg = amountColor;
        break;
      case TransactionType.transfer:
        amountColor = isDark ? AppColors.transferDark : AppColors.transfer;
        sign = '';
        icon = Icons.swap_horiz_rounded;
        iconBg = amountColor;
        break;
      case TransactionType.saving:
        amountColor = isDark ? AppColors.savingDark : AppColors.saving;
        sign = '';
        icon = Icons.savings_rounded;
        iconBg = amountColor;
        break;
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Hapus Transaksi?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            content: Text(
              'Saldo sumber dana akan dihitung ulang secara otomatis.',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: onTap,
        borderRadius: 20,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        hasShadow: !isDark, // only light mode gets the card shadow
        child: Row(
          children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconBg.withValues(alpha: 0.15),
                      iconBg.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconBg.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(icon, color: amountColor, size: 24),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.type == TransactionType.transfer
                        ? '${item.sourceName} ➔ ${item.targetSourceName ?? ""}'
                        : '${item.categoryName} • ${item.sourceName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${CurrencyFormatter.format(item.amount)}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: amountColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatRelative(item.dateTime),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String catName) {
    final lower = catName.toLowerCase();
    if (lower.contains('coffee') || lower.contains('kopi')) return Icons.coffee_rounded;
    if (lower.contains('transport') || lower.contains('bensin')) return Icons.directions_car_rounded;
    if (lower.contains('food') || lower.contains('makan')) return Icons.restaurant_rounded;
    if (lower.contains('shop') || lower.contains('belanja')) return Icons.shopping_bag_outlined;
    if (lower.contains('bill') || lower.contains('tagihan')) return Icons.receipt_long_rounded;
    if (lower.contains('entertain') || lower.contains('hiburan')) return Icons.movie_outlined;
    if (lower.contains('salary') || lower.contains('gaji')) return Icons.work_outline;
    return Icons.receipt_outlined;
  }
}
