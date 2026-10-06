import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction_item.dart';
import '../../models/fund_source.dart';
import '../../models/category.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  final TransactionItem? initialTransaction;

  const AddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.initialTransaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TransactionType _selectedType;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  late final String _idempotencyKey;

  FundSource? _selectedSource;
  FundSource? _targetSource;
  FinancialCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final item = widget.initialTransaction;
    if (item != null) {
      _selectedType = item.type;
      _amountController.text = item.amount.toInt().toString();
      _descController.text = item.description;
      _notesController.text = item.notes;
      _selectedDate = item.dateTime;
      _idempotencyKey = item.idempotencyKey ?? 'idemp_${DateTime.now().microsecondsSinceEpoch}';
    } else {
      _selectedType = widget.initialType;
      _idempotencyKey = 'idemp_${DateTime.now().microsecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_isLoading) return; // Prevent double submit

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    final desc = _descController.text.trim();

    if (amount <= 0 || desc.isEmpty || _selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi nominal, deskripsi, dan sumber dana.')),
      );
      return;
    }

    if ((_selectedType == TransactionType.transfer || _selectedType == TransactionType.saving) &&
        _targetSource?.id == _selectedSource?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sumber dana tujuan tidak boleh sama dengan sumber dana asal.')),
      );
      return;
    }

    final finance = Provider.of<FinanceProvider>(context, listen: false);

    final isEdit = widget.initialTransaction != null;
    final tx = TransactionItem(
      id: isEdit ? widget.initialTransaction!.id : 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      amount: amount,
      description: desc,
      categoryId: _selectedType == TransactionType.transfer
          ? 'cat_transfer'
          : (_selectedType == TransactionType.saving
              ? 'cat_saving'
              : (_selectedCategory?.id ?? 'cat_other')),
      categoryName: _selectedType == TransactionType.transfer
          ? 'Transfer'
          : (_selectedType == TransactionType.saving
              ? 'Menabung'
              : (_selectedCategory?.name ?? 'Lainnya')),
      sourceId: _selectedSource!.id,
      sourceName: _selectedSource!.name,
      targetSourceId: (_selectedType == TransactionType.transfer || _selectedType == TransactionType.saving)
          ? _targetSource?.id
          : null,
      targetSourceName: (_selectedType == TransactionType.transfer || _selectedType == TransactionType.saving)
          ? _targetSource?.name
          : null,
      dateTime: _selectedDate,
      notes: _notesController.text.trim(),
      idempotencyKey: _idempotencyKey,
    );

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (isEdit) {
        finance.editTransaction(tx);
      } else {
        finance.addTransaction(tx);
      }
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(isEdit ? 'Transaksi berhasil diperbarui.' : 'Transaksi berhasil disimpan.'),
              ),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;

    final sources = finance.sources;
    final categories = finance.activeCategories;
    final isEdit = widget.initialTransaction != null;

    if (_selectedSource == null && sources.isNotEmpty) {
      if (isEdit && widget.initialTransaction != null) {
        _selectedSource = sources.firstWhere(
          (s) => s.id == widget.initialTransaction!.sourceId,
          orElse: () => sources.first,
        );
      } else {
        _selectedSource = sources.first;
      }
    }

    if (_targetSource == null && sources.length > 1) {
      if (isEdit && widget.initialTransaction?.targetSourceId != null) {
        _targetSource = sources.firstWhere(
          (s) => s.id == widget.initialTransaction!.targetSourceId,
          orElse: () => sources.firstWhere((s) => s.id != _selectedSource?.id, orElse: () => sources[1]),
        );
      } else {
        _targetSource = sources.firstWhere((s) => s.id != _selectedSource?.id, orElse: () => sources[1]);
      }
    }

    if (_selectedCategory == null && categories.isNotEmpty) {
      if (isEdit && widget.initialTransaction != null) {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == widget.initialTransaction!.categoryId,
          orElse: () => categories.firstWhere(
            (c) => _selectedType == TransactionType.income ? c.type == CategoryType.income : c.type == CategoryType.expense,
            orElse: () => categories.first,
          ),
        );
      } else {
        _selectedCategory = categories.firstWhere(
          (c) => _selectedType == TransactionType.income ? c.type == CategoryType.income : c.type == CategoryType.expense,
          orElse: () => categories.first,
        );
      }
    }

    return Container(
      padding: EdgeInsets.only(
        top: 20,
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
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              isEdit ? 'Edit Transaksi' : 'Catat Transaksi',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // 4-Type Segmented Switcher (Expense, Income, Transfer, Saving)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTypeOption('Pengeluaran', TransactionType.expense, AppColors.expense, isDark),
                  _buildTypeOption('Pemasukan', TransactionType.income, AppColors.income, isDark),
                  _buildTypeOption('Transfer', TransactionType.transfer, AppColors.transfer, isDark),
                  _buildTypeOption('Menabung', TransactionType.saving, const Color(0xFF0D9488), isDark),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Field
            Text(
              'Nominal (Rp)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: !isEdit,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Keterangan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: _selectedType == TransactionType.saving
                    ? 'Misal: Tabungan Liburan, Dana Darurat'
                    : (_selectedType == TransactionType.transfer
                        ? 'Misal: Top up e-wallet, Pindah rekening'
                        : 'Misal: Kopi Susu, Bensin, Gaji'),
              ),
            ),

            const SizedBox(height: 16),

            // Source Dropdown
            Text(
              (_selectedType == TransactionType.transfer || _selectedType == TransactionType.saving)
                  ? 'Dari Sumber Dana'
                  : 'Sumber Dana',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<FundSource>(
              value: _selectedSource,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              items: sources.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text('${s.name} (${CurrencyFormatter.format(s.balance)})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSource = val),
            ),

            // Target Source for Transfer or Saving
            if (_selectedType == TransactionType.transfer || _selectedType == TransactionType.saving) ...[
              const SizedBox(height: 16),
              Text(
                _selectedType == TransactionType.saving
                    ? 'Ke Rekening Tabungan'
                    : 'Ke Sumber Dana Tujuan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<FundSource>(
                value: _targetSource,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                items: sources.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text('${s.name} (${CurrencyFormatter.format(s.balance)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _targetSource = val),
              ),
            ],

            // Category Picker for Expense and Income
            if (_selectedType == TransactionType.expense || _selectedType == TransactionType.income) ...[
              const SizedBox(height: 16),
              Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<FinancialCategory>(
                value: _selectedCategory,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                items: categories
                    .where((c) => _selectedType == TransactionType.income
                        ? c.type == CategoryType.income
                        : c.type == CategoryType.expense)
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
            ],

            const SizedBox(height: 16),

            // Notes / Catatan opsional
            Text(
              'Catatan (Opsional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: const InputDecoration(hintText: 'Tambah catatan rincian transaksi...'),
            ),

            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: isEdit ? 'Perbarui Transaksi' : 'Simpan Transaksi',
              isLoading: _isLoading,
              onPressed: _saveTransaction,
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              textColor: isDark ? Colors.black : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, TransactionType type, Color activeColor, bool isDark) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.darkCard : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
