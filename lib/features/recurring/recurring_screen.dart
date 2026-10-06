import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/recurring_transaction.dart';
import '../../models/transaction_item.dart';
import '../../models/category.dart';
import '../../models/fund_source.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  void _showAddOrEditSubscriptionSheet([RecurringTransaction? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSubscriptionSheet(initialItem: existing),
    );
  }

  void _toggleSubscription(FinanceProvider finance, RecurringTransaction sub) {
    final updated = sub.copyWith(isActive: !sub.isActive);
    finance.updateRecurring(updated);
  }

  void _deleteSubscription(FinanceProvider finance, RecurringTransaction sub) {
    finance.deleteRecurring(sub.id);
  }

  void _confirmExecuteNow(BuildContext context, FinanceProvider finance, RecurringTransaction sub) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eksekusi Tagihan Sekarang?'),
        content: Text(
          'Catat tagihan "${sub.description}" (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(sub.amount)}) sekarang dan majukan jadwal berikutnya?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.income, foregroundColor: Colors.white),
            onPressed: () {
              finance.executeRecurringImmediately(sub.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tagihan "${sub.description}" berhasil dicatat ke mutasi!')),
              );
            },
            child: const Text('Eksekusi'),
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
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    final subscriptions = finance.recurring;
    final activeCount = subscriptions.where((s) => s.isActive).length;

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan & Berlangganan', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditSubscriptionSheet(),
        backgroundColor: AppColors.expense,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Tagihan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: subscriptions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_repeat_rounded, size: 64, color: AppColors.expense),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Belum Ada Tagihan Rutin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Catat tagihan internet, kost, atau\nlangganan agar terjadwal otomatis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.expense, AppColors.expense.withAlpha(200)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.expense.withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Tagihan Aktif',
                                style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$activeCount Tagihan Terjadwal',
                                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),

                  const Text('Daftar Tagihan Rutin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  ...subscriptions.map((sub) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showAddOrEditSubscriptionSheet(sub),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: sub.isActive ? AppColors.expense.withAlpha(20) : Colors.grey.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      sub.isActive ? Icons.autorenew_rounded : Icons.pause_circle_outline_rounded,
                                      color: sub.isActive ? AppColors.expense : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.description,
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormatter.format(sub.amount),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: sub.isActive ? AppColors.expense : Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: sub.isActive,
                                    activeColor: AppColors.expense,
                                    onChanged: (val) => _toggleSubscription(finance, sub),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          sub.categoryName,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          sub.sourceName,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Berikutnya: ${sub.nextOccurrence.day}/${sub.nextOccurrence.month}/${sub.nextOccurrence.year}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (sub.isActive)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.income,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      onPressed: () => _confirmExecuteNow(context, finance, sub),
                                      icon: const Icon(Icons.bolt_rounded, size: 16),
                                      label: const Text('Catat Sekarang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.expense,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Tagihan?'),
                                          content: Text('Apakah Anda yakin ingin menghapus tagihan ${sub.description}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteSubscription(finance, sub);
                                              },
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
      ),
    );
  }
}

class AddSubscriptionSheet extends StatefulWidget {
  final RecurringTransaction? initialItem;
  const AddSubscriptionSheet({super.key, this.initialItem});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late int _selectedDay;
  String? _selectedCatId;
  String? _selectedSrcId;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameCtrl = TextEditingController(text: item?.description ?? '');
    _amountCtrl = TextEditingController(text: item != null ? item.amount.toInt().toString() : '');
    _selectedDay = item?.scheduledDay ?? 1;
    _selectedCatId = item?.categoryId;
    _selectedSrcId = item?.sourceId;
    _selectedFrequency = item?.frequency ?? RecurringFrequency.monthly;
  }

  void _save(FinanceProvider finance) {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) return;

    final amt = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amt <= 0) return;

    final cat = finance.activeCategories.firstWhere(
      (c) => c.id == _selectedCatId,
      orElse: () => finance.activeCategories.isNotEmpty
          ? finance.activeCategories.first
          : FinancialCategory(id: 'cat_lainnya', name: 'Lainnya', iconName: 'more', colorHex: '6B7280'),
    );

    final src = finance.sources.firstWhere(
      (s) => s.id == _selectedSrcId,
      orElse: () => finance.sources.isNotEmpty
          ? finance.sources.first
          : FundSource(id: 'src_cash', name: 'Uang Jajan', balance: 0.0, iconName: 'wallet', colorHex: '087F5B'),
    );

    final now = DateTime.now();
    DateTime nextOcc = DateTime(now.year, now.month, _selectedDay.clamp(1, 28));
    if (nextOcc.isBefore(now)) {
      nextOcc = DateTime(now.year, now.month + 1, _selectedDay.clamp(1, 28));
    }

    if (widget.initialItem != null) {
      final updated = widget.initialItem!.copyWith(
        description: _nameCtrl.text.trim(),
        amount: amt,
        categoryId: cat.id,
        categoryName: cat.name,
        sourceId: src.id,
        sourceName: src.name,
        frequency: _selectedFrequency,
        scheduledDay: _selectedDay,
      );
      finance.updateRecurring(updated);
    } else {
      final newSub = RecurringTransaction(
        id: const Uuid().v4(),
        description: _nameCtrl.text.trim(),
        amount: amt,
        type: TransactionType.expense,
        categoryId: cat.id,
        categoryName: cat.name,
        sourceId: src.id,
        sourceName: src.name,
        frequency: _selectedFrequency,
        startDate: now,
        nextOccurrence: nextOcc,
        scheduledDay: _selectedDay,
      );
      finance.addRecurring(newSub);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final finance = Provider.of<FinanceProvider>(context, listen: false);

    _selectedCatId ??= finance.activeCategories.isNotEmpty ? finance.activeCategories.first.id : null;
    _selectedSrcId ??= finance.sources.isNotEmpty ? finance.sources.first.id : null;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialItem != null ? 'Ubah Tagihan Rutin' : 'Tambah Tagihan Rutin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Tagihan (contoh: Kuota Internet, Kost)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCatId,
                    items: finance.activeCategories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCatId = val),
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSrcId,
                    items: finance.sources
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSrcId = val),
                    decoration: const InputDecoration(labelText: 'Sumber Dana'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RecurringFrequency>(
              value: _selectedFrequency,
              items: RecurringFrequency.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFrequency = val);
              },
              decoration: const InputDecoration(labelText: 'Frekuensi Pengulangan'),
            ),
            const SizedBox(height: 14),
            Text('Jadwal Tanggal Transaksi (1-31):', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedDay,
              items: List.generate(31, (i) => i + 1).map((d) {
                return DropdownMenuItem(value: d, child: Text('Tanggal $d'));
              }).toList(),
              onChanged: (val) => setState(() => _selectedDay = val ?? 1),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 6),
            Text(
              'Untuk bulan yang lebih pendek (seperti Februari), tanggal akan disesuaikan secara aman (clamped) tanpa merusak jadwal target tanggal 31.',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _save(finance),
                child: Text(
                  widget.initialItem != null ? 'Simpan Perubahan' : 'Simpan Tagihan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
