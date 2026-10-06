import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/budget.dart';
import '../../core/utils/currency_formatter.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _showAddOrEditBudgetDialog(BuildContext context, {Budget? existingBudget}) {
    final limitCtrl = TextEditingController(
      text: existingBudget != null ? existingBudget.limitAmount.toInt().toString() : '',
    );
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final isDark = theme.isDarkMode;

    bool isOverall = existingBudget?.isOverall ?? false;
    String? selCatId = existingBudget != null && !existingBudget.isOverall
        ? existingBudget.categoryId
        : (finance.activeCategories.isNotEmpty ? finance.activeCategories.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existingBudget != null ? 'Ubah Anggaran' : 'Buat Batas Anggaran',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option for Overall vs Category
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Per Kategori'),
                      selected: !isOverall,
                      onSelected: (sel) {
                        setDlg(() => isOverall = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Total Semua Pengeluaran'),
                      selected: isOverall,
                      onSelected: (sel) {
                        setDlg(() => isOverall = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!isOverall) ...[
                  DropdownButtonFormField<String>(
                    value: selCatId,
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    items: finance.activeCategories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) => setDlg(() => selCatId = val),
                    decoration: const InputDecoration(labelText: 'Kategori Pengeluaran'),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Batas Anggaran (Rp)',
                    labelText: 'Nominal Batas Limit',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sistem akan mengirim notifikasi saat pengeluaran mencapai 80% dan 100% dari batas ini.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final limit = double.tryParse(limitCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                if (limit > 0) {
                  final now = DateTime.now();
                  if (isOverall) {
                    final budget = Budget(
                      id: existingBudget?.id ?? 'bgt_overall_${now.month}_${now.year}',
                      categoryId: 'all',
                      categoryName: 'Total Semua Pengeluaran',
                      limitAmount: limit,
                      spentAmount: existingBudget?.spentAmount ?? 0.0,
                      month: now.month,
                      year: now.year,
                      isOverall: true,
                    );
                    finance.addBudget(budget);
                  } else if (selCatId != null) {
                    final cat = finance.categories.firstWhere((c) => c.id == selCatId);
                    final budget = Budget(
                      id: existingBudget?.id ?? 'bgt_${cat.id}_${now.month}_${now.year}',
                      categoryId: cat.id,
                      categoryName: cat.name,
                      limitAmount: limit,
                      spentAmount: existingBudget?.spentAmount ?? 0.0,
                      month: now.month,
                      year: now.year,
                      isOverall: false,
                    );
                    finance.addBudget(budget);
                  }
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRolloverSheet(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.autorenew_rounded, color: AppColors.income),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rollover Anggaran Bulanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rollover menyalin target anggaran dari bulan lalu ke bulan ini. Anda juga dapat mengakumulasikan sisa surplus anggaran yang tidak terpakai.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final count = finance.rolloverPreviousMonthBudgets(carryOverSurplus: false);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berhasil menyalin $count anggaran dari bulan lalu.')),
                      );
                    },
                    child: const Text('Salin Target Saja'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.income, foregroundColor: Colors.white),
                    onPressed: () {
                      final count = finance.rolloverPreviousMonthBudgets(carryOverSurplus: true);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berhasil rollover $count anggaran beserta surplus.')),
                      );
                    },
                    child: const Text('+ Akumulasi Surplus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Budget budget) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Anggaran?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Hapus anggaran "${budget.categoryName}"?',
          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).deleteBudget(budget.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;

    // Filter current month budgets
    final now = DateTime.now();
    final activeBudgets = finance.budgets.where((b) => b.month == now.month && b.year == now.year).toList();

    // Summary stats
    final totalLimit = activeBudgets.fold<double>(0, (s, b) => s + b.limitAmount);
    final totalSpent = activeBudgets.fold<double>(0, (s, b) => s + b.spentAmount);
    final overBudget = activeBudgets.where((b) => b.percentUsed >= 100).length;
    final warningBudget = activeBudgets.where((b) => b.percentUsed >= 80 && b.percentUsed < 100).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran (Budget)', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Rollover Bulan Lalu',
            icon: const Icon(Icons.autorenew_rounded),
            onPressed: () => _showRolloverSheet(context),
          ),
          IconButton(
            tooltip: 'Tambah Anggaran',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddOrEditBudgetDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Overview card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0D1F12), const Color(0xFF102817)]
                      : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 36, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kontrol Pengeluaran Bulan Ini',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Batas: ${CurrencyFormatter.format(totalLimit)}  •  Terpakai: ${CurrencyFormatter.format(totalSpent)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (overBudget > 0 || warningBudget > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (overBudget > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.expense.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$overBudget terlampaui (100%+)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.expense),
                                  ),
                                ),
                              if (warningBudget > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$warningBudget waspada (80%+)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Daftar Anggaran Aktif',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                if (activeBudgets.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${activeBudgets.length} item',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if (activeBudgets.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded, size: 44, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada anggaran bulan ini.\nTekan + untuk membuat batas anggaran pertama atau gunakan tombol Rollover.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeBudgets.map((b) {
                Color statusColor;
                String statusLabel;
                switch (b.alertState) {
                  case BudgetAlertState.exceeded:
                    statusColor = AppColors.expense;
                    statusLabel = 'Terlampaui (${b.percentUsed.toStringAsFixed(0)}%)';
                    break;
                  case BudgetAlertState.critical:
                    statusColor = const Color(0xFFEA580C); // Deep Orange
                    statusLabel = 'Kritis (${b.percentUsed.toStringAsFixed(0)}%)';
                    break;
                  case BudgetAlertState.warning:
                    statusColor = AppColors.warning;
                    statusLabel = 'Waspada (${b.percentUsed.toStringAsFixed(0)}%)';
                    break;
                  case BudgetAlertState.safe:
                    statusColor = AppColors.income;
                    statusLabel = 'Aman (${b.percentUsed.toStringAsFixed(0)}%)';
                    break;
                }

                return Dismissible(
                  key: Key(b.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (dir) async {
                    _confirmDelete(context, b);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withAlpha(35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showAddOrEditBudgetDialog(context, existingBudget: b),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withAlpha(90)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (b.isOverall) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                      ),
                                    ],
                                    Flexible(
                                      child: Text(
                                        b.categoryName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Terpakai: ${CurrencyFormatter.format(b.spentAmount)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Batas: ${CurrencyFormatter.format(b.limitAmount)}',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (b.spentAmount / b.limitAmount).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Advanced Metrics Row: Sisa, Sisa Hari, Burn Rate
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Sisa Anggaran', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.format(b.remaining),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: b.remaining >= 0 ? AppColors.income : AppColors.expense,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text('Sisa Hari', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${b.daysRemaining} hari',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Saran Harian', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${CurrencyFormatter.format(b.recommendedDailySpending)}/hari',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.income),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Burn Rate: ${CurrencyFormatter.format(b.burnRate)}/hari',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: b.isBurningTooFast ? AppColors.expense : AppColors.income,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Proyeksi: ${CurrencyFormatter.format(b.projectedSpending)}',
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Ketuk kartu untuk ubah nominal batas',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.expense,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _confirmDelete(context, b),
                                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
