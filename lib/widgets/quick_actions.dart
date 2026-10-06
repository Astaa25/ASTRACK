import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

class QuickActionsRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onTransfer;
  final VoidCallback onScan;
  final VoidCallback onAskAI;

  const QuickActionsRow({
    super.key,
    required this.isDark,
    required this.onIncome,
    required this.onExpense,
    required this.onTransfer,
    required this.onScan,
    required this.onAskAI,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildItem(
            label: 'Masuk',
            icon: Icons.add_rounded,
            color: isDark ? AppColors.incomeDark : AppColors.income,
            onTap: onIncome,
          ),
        ),
        Expanded(
          child: _buildItem(
            label: 'Keluar',
            icon: Icons.remove_rounded,
            color: isDark ? AppColors.expenseDark : AppColors.expense,
            onTap: onExpense,
          ),
        ),
        Expanded(
          child: _buildItem(
            label: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            color: isDark ? AppColors.transferDark : AppColors.transfer,
            onTap: onTransfer,
          ),
        ),
        Expanded(
          child: _buildItem(
            label: 'Scan Struk',
            icon: Icons.document_scanner_outlined,
            color: isDark ? AppColors.savingDark : AppColors.saving,
            onTap: onScan,
          ),
        ),
        Expanded(
          child: _buildItem(
            label: 'Analisis',
            icon: Icons.psychology_outlined,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            onTap: onAskAI,
            isHighlight: true,
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isHighlight
                    ? (isDark ? AppColors.darkPrimary.withOpacity(0.18) : AppColors.lightLightGreen)
                    : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isHighlight
                      ? (isDark ? AppColors.darkPrimary.withOpacity(0.5) : AppColors.lightPrimary)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isHighlight ? 1.5 : 1,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: isHighlight
                              ? AppColors.darkPrimary.withOpacity(0.15)
                              : Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Center(
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
