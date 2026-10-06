import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final bool isHidden;
  final VoidCallback onToggleHide;
  final bool isDark;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.isHidden,
    required this.onToggleHide,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Light: soft emerald gradient; Dark: deep card with emerald glow
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B15), Color(0xFF122922)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF111413), // Deep Obsidian
                  Color(0xFF192520), // Slight Emerald reflection
                  Color(0xFF0B0E0D), // Pure Black base
                ],
                stops: [0.0, 0.5, 1.0],
              ),
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: AppColors.darkBorder, width: 1)
            : null,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppColors.darkPrimary.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF111413).withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Decorative circles — gives depth on both modes
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkPrimary.withOpacity(0.06)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkPrimary.withOpacity(0.04)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Sparkline Chart Background
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            height: 80,
            child: Opacity(
              opacity: isDark ? 0.3 : 0.4,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 6,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 2),
                        FlSpot(2, 4),
                        FlSpot(3, 3),
                        FlSpot(4, 5),
                        FlSpot(5, 4),
                        FlSpot(6, 6),
                      ],
                      isCurved: true,
                      color: AppColors.goldAccent.withOpacity(0.6),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Total Balance label & Privacy Eye Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Saldo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.white.withOpacity(0.80),
                        letterSpacing: 0.2,
                      ),
                    ),
                    InkWell(
                      onTap: onToggleHide,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.white.withOpacity(0.80),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Large Currency Value
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: isHidden
                      ? Text(
                          CurrencyFormatter.maskedBalance(),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: isDark ? AppColors.darkTextPrimary : Colors.white,
                          ),
                        )
                      : TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: totalBalance),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              CurrencyFormatter.format(value),
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: isDark ? AppColors.darkTextPrimary : Colors.white,
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),

                // Divider
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : Colors.white.withOpacity(0.25),
                ),

                const SizedBox(height: 16),

                // Income / Expense summary breakdown
                Row(
                  children: [
                    // Income
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.incomeDark.withOpacity(0.14)
                                  : Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.incomeDark
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkMuted
                                        : Colors.white.withOpacity(0.72),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: isHidden
                                      ? Text(
                                          'Rp ••••••',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? AppColors.incomeDark : Colors.white,
                                          ),
                                        )
                                      : TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: monthlyIncome),
                                          duration: const Duration(milliseconds: 1000),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return Text(
                                              CurrencyFormatter.format(value),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: isDark ? AppColors.incomeDark : Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 36,
                      width: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(width: 16),

                    // Expense
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.expenseDark.withOpacity(0.14)
                                  : Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.expenseDark
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkMuted
                                        : Colors.white.withOpacity(0.72),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: isHidden
                                      ? Text(
                                          'Rp ••••••',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? AppColors.expenseDark : Colors.white,
                                          ),
                                        )
                                      : TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: monthlyExpense),
                                          duration: const Duration(milliseconds: 1000),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return Text(
                                              CurrencyFormatter.format(value),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: isDark ? AppColors.expenseDark : Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
            ),
          ),
        );
      },
    );
  }
}
