import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/savings_goal.dart';
import '../../core/utils/currency_formatter.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _showDepositDialog(BuildContext context, SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;
    String selSrcId = finance.sources.isNotEmpty ? finance.sources.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Alokasikan Tabungan',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target: ${CurrencyFormatter.format(goal.targetAmount)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Sisa untuk capai: ${CurrencyFormatter.format(goal.remainingAmount)}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selSrcId,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                items: finance.sources.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${CurrencyFormatter.format(s.balance)})'))).toList(),
                onChanged: (val) {
                  if (val != null) setDlg(() => selSrcId = val);
                },
                decoration: const InputDecoration(labelText: 'Sumber Dana Asal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: const InputDecoration(hintText: 'Rp 0', labelText: 'Nominal Alokasi', prefixText: 'Rp '),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                if (amt > 0) {
                  finance.depositToSavingsGoal(savingsGoalId: goal.id, amount: amt, fromSourceId: selSrcId);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Nabung'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;
    // Default to first source or default "Uang Jajan"
    String selTargetSrcId = finance.sources.isNotEmpty ? finance.sources.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tarik Saldo Tabungan',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terkumpul: ${CurrencyFormatter.format(goal.currentAmount)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Pindahkan dana tabungan kembali ke dompet / rekening utama Anda.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selTargetSrcId,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                items: finance.sources.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${CurrencyFormatter.format(s.balance)})'))).toList(),
                onChanged: (val) {
                  if (val != null) setDlg(() => selTargetSrcId = val);
                },
                decoration: const InputDecoration(labelText: 'Tujuan Pencairan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Maks ${CurrencyFormatter.format(goal.currentAmount)}',
                  labelText: 'Nominal Pencairan',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                if (amt > 0 && amt <= goal.currentAmount) {
                  finance.withdrawFromSavingsGoal(savingsGoalId: goal.id, amount: amt, toSourceId: selTargetSrcId);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Tarik Saldo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditGoalDialog(BuildContext context, {SavingsGoal? existingGoal}) {
    final nameCtrl = TextEditingController(text: existingGoal?.name ?? '');
    final targetCtrl = TextEditingController(
      text: existingGoal != null ? existingGoal.targetAmount.toInt().toString() : '',
    );
    DateTime? selectedDeadline = existingGoal?.deadline;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existingGoal != null ? 'Ubah Target Tabungan' : 'Buat Target Tabungan',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Misal: Beli Laptop, Liburan, Dana Darurat',
                    labelText: 'Nama Target Impian',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  decoration: const InputDecoration(hintText: 'Rp 0', labelText: 'Target Nominal', prefixText: 'Rp '),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Batas Waktu (Deadline)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                        : 'Tidak ditentukan (Fleksibel)',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline ?? DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDlg(() => selectedDeadline = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final target = double.tryParse(targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                final src = finance.sources.isNotEmpty ? finance.sources.first : null;
                if (name.isNotEmpty && target > 0 && src != null) {
                  if (existingGoal != null) {
                    finance.updateSavingsGoal(existingGoal.copyWith(
                      name: name,
                      targetAmount: target,
                      deadline: selectedDeadline,
                    ));
                  } else {
                    finance.addSavingsGoal(SavingsGoal(
                      id: 'svg_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      targetAmount: target,
                      currentAmount: 0.0,
                      sourceId: src.id,
                      sourceName: src.name,
                      deadline: selectedDeadline,
                    ));
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

  void _confirmDelete(BuildContext context, SavingsGoal goal) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Target?',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text('Hapus target tabungan "${goal.name}"?', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).deleteSavingsGoal(goal.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _goalEmoji(SavingsGoal g) {
    final lower = g.name.toLowerCase();
    if (lower.contains('motor') || lower.contains('mobil') || lower.contains('kendaraan')) return 'vehicle';
    if (lower.contains('rumah') || lower.contains('apartemen')) return 'house';
    if (lower.contains('liburan') || lower.contains('wisata') || lower.contains('travel')) return 'travel';
    if (lower.contains('darurat') || lower.contains('emergency')) return 'emergency';
    if (lower.contains('pendidikan') || lower.contains('kuliah') || lower.contains('sekolah')) return 'education';
    if (lower.contains('nikah') || lower.contains('pernikahan')) return 'wedding';
    return 'goal';
  }

  IconData _goalIcon(SavingsGoal g) {
    switch (_goalEmoji(g)) {
      case 'vehicle':
        return Icons.directions_car_rounded;
      case 'house':
        return Icons.home_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'emergency':
        return Icons.health_and_safety_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'wedding':
        return Icons.favorite_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Widget _buildMilestoneChip(String label, bool reached, Color activeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: reached ? activeColor.withAlpha(35) : (isDark ? Colors.white10 : Colors.black.withAlpha(10)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: reached ? activeColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reached) ...[
            Icon(Icons.check_circle_rounded, size: 12, color: activeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: reached ? FontWeight.w800 : FontWeight.w600,
              color: reached ? activeColor : (isDark ? Colors.white54 : Colors.black45),
            ),
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

    final totalSaved = finance.savings.fold<double>(0, (s, g) => s + g.currentAmount);
    final totalTarget = finance.savings.fold<double>(0, (s, g) => s + g.targetAmount);
    final completed = finance.savings.where((g) => g.progressRatio >= 1.0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Tambah Target',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddOrEditGoalDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Summary
            if (finance.savings.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0D2420), const Color(0xFF112926)]
                        : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total Terkumpul',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                        if (completed > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.income.withAlpha(35), borderRadius: BorderRadius.circular(8)),
                            child: Text('$completed goal tercapai!', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.income)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalSaved),
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppColors.savingDark : AppColors.saving),
                    ),
                    const SizedBox(height: 4),
                    Text('dari target ${CurrencyFormatter.format(totalTarget)}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkElevatedCard : Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppColors.savingDark : AppColors.saving),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            if (finance.savings.isEmpty)
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
                      Icon(Icons.savings_outlined, size: 44, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada target tabungan.\nTambahkan impian pertama Anda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...finance.savings.map((g) {
                final isComplete = g.isCompleted;
                Color statusColor;
                switch (g.status) {
                  case SavingsGoalStatus.completed:
                    statusColor = AppColors.income;
                    break;
                  case SavingsGoalStatus.onTrack:
                    statusColor = const Color(0xFF0284C7); // Sky Blue
                    break;
                  case SavingsGoalStatus.behind:
                    statusColor = const Color(0xFFF97316); // Orange
                    break;
                }

                return Dismissible(
                  key: Key(g.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (dir) async {
                    _confirmDelete(context, g);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.expense.withAlpha(35), borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showAddOrEditGoalDialog(context, existingGoal: g),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(22),
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
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: statusColor.withAlpha(35), shape: BoxShape.circle),
                                      child: Icon(_goalIcon(g), color: statusColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          Text(g.status.label, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withAlpha(35), borderRadius: BorderRadius.circular(12)),
                                child: Text('${g.progressPercent}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Terkumpul: ${CurrencyFormatter.format(g.currentAmount)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Target: ${CurrencyFormatter.format(g.targetAmount)}',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: g.progressRatio.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Milestone Badges Row
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMilestoneChip('25%', g.milestone25, statusColor, isDark),
                                const SizedBox(width: 8),
                                _buildMilestoneChip('50%', g.milestone50, statusColor, isDark),
                                const SizedBox(width: 8),
                                _buildMilestoneChip('75%', g.milestone75, statusColor, isDark),
                                const SizedBox(width: 8),
                                _buildMilestoneChip('100% 🎉', g.milestone100, statusColor, isDark),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Detail metrics row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Sisa: ${CurrencyFormatter.format(g.remainingAmount)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (g.daysRemaining != null)
                                      Flexible(
                                        child: Text(
                                          '${g.daysRemaining} hari lagi',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                        ),
                                      )
                                    else
                                      const Flexible(child: Text('Target Fleksibel', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic))),
                                  ],
                                ),
                                if (g.daysRemaining != null && !isComplete) ...[
                                  const Divider(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Saran Setoran:',
                                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                                      ),
                                      Text(
                                        '${CurrencyFormatter.format(g.recommendedMonthlySaving)} / bulan  •  ${CurrencyFormatter.format(g.recommendedDailySaving)} / hari',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Actions Row: Nabung & Tarik Saldo
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (!isComplete)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        foregroundColor: isDark ? AppColors.savingDark : AppColors.saving,
                                        side: BorderSide(color: isDark ? AppColors.savingDark : AppColors.saving),
                                      ),
                                      onPressed: () => _showDepositDialog(context, g),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Nabung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(color: AppColors.income.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.income),
                                          SizedBox(width: 6),
                                          Text('Goal Tercapai!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.income)),
                                        ],
                                      ),
                                    ),
                                  if (g.currentAmount > 0)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        foregroundColor: const Color(0xFF0284C7),
                                        side: const BorderSide(color: Color(0xFF0284C7)),
                                      ),
                                      onPressed: () => _showWithdrawDialog(context, g),
                                      icon: const Icon(Icons.arrow_outward_rounded, size: 15),
                                      label: const Text('Tarik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.expense,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _confirmDelete(context, g),
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
