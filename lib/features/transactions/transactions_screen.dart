import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction_item.dart';
import '../../widgets/transaction_tile.dart';
import '../../core/utils/currency_formatter.dart';
import 'add_transaction_sheet.dart';
import 'csv_import_screen.dart';
import '../subscription/models/astra_feature.dart';
import '../subscription/services/feature_gate_service.dart';
import '../../widgets/liquid_loader.dart';

enum TransactionSortOrder {
  newest,
  oldest,
  highestAmount,
  lowestAmount;

  String get label {
    switch (this) {
      case TransactionSortOrder.newest:
        return 'Terbaru';
      case TransactionSortOrder.oldest:
        return 'Terlama';
      case TransactionSortOrder.highestAmount:
        return 'Nominal Terbesar';
      case TransactionSortOrder.lowestAmount:
        return 'Nominal Terkecil';
    }
  }
}

enum DateRangeFilter {
  all('Semua Waktu'),
  today('Hari Ini'),
  last7Days('7 Hari Terakhir'),
  thisMonth('Bulan Ini');

  final String label;
  const DateRangeFilter(this.label);
}

class TransactionsScreen extends StatefulWidget {
  final String? initialCategoryFilter;

  const TransactionsScreen({super.key, this.initialCategoryFilter});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _selectedFilter = 'Semua';
  String? _categoryFilter;
  String? _sourceFilter;
  DateRangeFilter _dateFilter = DateRangeFilter.all;
  TransactionSortOrder _sortOrder = TransactionSortOrder.newest;

  int _displayedCount = 20;
  int _totalFilteredCount = 0;

  @override
  void initState() {
    super.initState();
    _categoryFilter = widget.initialCategoryFilter;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_displayedCount < _totalFilteredCount) {
        setState(() {
          _displayedCount = (_displayedCount + 20).clamp(0, _totalFilteredCount);
        });
      }
    }
  }

  void _openEditSheet(TransactionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialTransaction: item,
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionItem item) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textS = isDark ? AppColors.darkMuted : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textP),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(item.amount),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: item.type == TransactionType.income
                        ? AppColors.income
                        : (item.type == TransactionType.expense
                            ? AppColors.expense
                            : (item.type == TransactionType.saving
                                ? const Color(0xFF0D9488)
                                : AppColors.transfer)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            _buildDetailRow('Tipe Transaksi', _getTypeLabel(item.type), textS, textP),
            _buildDetailRow('Kategori', item.categoryName, textS, textP),
            _buildDetailRow('Sumber Dana', item.sourceName, textS, textP),
            if (item.targetSourceName != null)
              _buildDetailRow(
                item.type == TransactionType.saving ? 'Tujuan Tabungan' : 'Tujuan Transfer',
                item.targetSourceName!,
                textS,
                textP,
              ),
            _buildDetailRow('Waktu', DateFormat('dd MMMM yyyy, HH:mm').format(item.dateTime), textS, textP),
            if (item.notes.isNotEmpty)
              _buildDetailRow('Catatan', item.notes, textS, textP),

            const SizedBox(height: 24),
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEditSheet(item);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Duplicate Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Duplikat'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final clone = TransactionItem(
                        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                        type: item.type,
                        amount: item.amount,
                        description: '${item.description} (Salinan)',
                        categoryId: item.categoryId,
                        categoryName: item.categoryName,
                        sourceId: item.sourceId,
                        sourceName: item.sourceName,
                        targetSourceId: item.targetSourceId,
                        targetSourceName: item.targetSourceName,
                        dateTime: DateTime.now(),
                        notes: item.notes,
                        idempotencyKey: 'idemp_${DateTime.now().microsecondsSinceEpoch}',
                      );
                      finance.addTransaction(clone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaksi berhasil diduplikat!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Delete Button
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.expense.withOpacity(0.12),
                    foregroundColor: AppColors.expense,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () {
                    Navigator.pop(ctx);
                    finance.deleteTransaction(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi berhasil dihapus.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'PEMASUKAN';
      case TransactionType.expense:
        return 'PENGELUARAN';
      case TransactionType.transfer:
        return 'TRANSFER';
      case TransactionType.saving:
        return 'MENABUNG';
    }
  }

  Widget _buildDetailRow(String label, String value, Color textS, Color textP) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: textS)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textP)),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) {
      return 'Hari Ini • ${DateFormat('d MMMM yyyy').format(date)}';
    } else if (check == yesterday) {
      return 'Kemarin • ${DateFormat('d MMMM yyyy').format(date)}';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;

    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    // 1. Filter list
    List<TransactionItem> filtered = finance.transactions.where((t) {
      if (_categoryFilter != null && t.categoryName.toLowerCase() != _categoryFilter!.toLowerCase()) {
        return false;
      }
      if (_sourceFilter != null && t.sourceName.toLowerCase() != _sourceFilter!.toLowerCase()) {
        return false;
      }
      if (_selectedFilter == 'Pengeluaran' && t.type != TransactionType.expense) return false;
      if (_selectedFilter == 'Pemasukan' && t.type != TransactionType.income) return false;
      if (_selectedFilter == 'Transfer' && t.type != TransactionType.transfer) return false;
      if (_selectedFilter == 'Menabung' && t.type != TransactionType.saving) return false;

      // Date range filter
      switch (_dateFilter) {
        case DateRangeFilter.today:
          if (t.dateTime.year != now.year || t.dateTime.month != now.month || t.dateTime.day != now.day) {
            return false;
          }
          break;
        case DateRangeFilter.last7Days:
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          if (t.dateTime.isBefore(sevenDaysAgo)) return false;
          break;
        case DateRangeFilter.thisMonth:
          if (t.dateTime.year != now.year || t.dateTime.month != now.month) return false;
          break;
        case DateRangeFilter.all:
          break;
      }

      if (query.isNotEmpty) {
        final matchesDesc = t.description.toLowerCase().contains(query);
        final matchesCat = t.categoryName.toLowerCase().contains(query);
        final matchesSrc = t.sourceName.toLowerCase().contains(query);
        final matchesNotes = t.notes.toLowerCase().contains(query);
        return matchesDesc || matchesCat || matchesSrc || matchesNotes;
      }
      return true;
    }).toList();

    // 2. Sort list
    switch (_sortOrder) {
      case TransactionSortOrder.newest:
        filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case TransactionSortOrder.oldest:
        filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case TransactionSortOrder.highestAmount:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOrder.lowestAmount:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    _totalFilteredCount = filtered.length;
    final pagedItems = filtered.take(_displayedCount).toList();

    // 3. Group by Day (List harian)
    final Map<DateTime, List<TransactionItem>> dailyGroups = {};
    for (final item in pagedItems) {
      final dateKey = DateTime(item.dateTime.year, item.dateTime.month, item.dateTime.day);
      dailyGroups.putIfAbsent(dateKey, () => []).add(item);
    }

    final activeFiltersCount = (_categoryFilter != null ? 1 : 0) +
        (_sourceFilter != null ? 1 : 0) +
        (_dateFilter != DateRangeFilter.all ? 1 : 0) +
        (_selectedFilter != 'Semua' ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Impor CSV',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () {
              FeatureGateService.checkAndGate(
                context,
                feature: AstraFeatures.csvImportExport,
                onGranted: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Tambah Transaksi',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddTransactionSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _displayedCount = 20),
                    style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi (misal: "kopi", "bensin")...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                      ),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _displayedCount = 20);
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filter by Type chips
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer', 'Menabung'].map((f) {
                              final isSel = _selectedFilter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: isSel,
                                  selectedColor: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: isSel
                                        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                                  side: BorderSide(
                                    color: isSel
                                        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  onSelected: (_) => setState(() {
                                    _selectedFilter = f;
                                    _displayedCount = 20;
                                  }),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Filter Date Dropdown
                      PopupMenuButton<DateRangeFilter>(
                        icon: Icon(
                          Icons.calendar_today_rounded,
                          size: 19,
                          color: _dateFilter != DateRangeFilter.all
                              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                              : (isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                        ),
                        tooltip: 'Filter Tanggal',
                        onSelected: (dateF) => setState(() {
                          _dateFilter = dateF;
                          _displayedCount = 20;
                        }),
                        itemBuilder: (ctx) => DateRangeFilter.values.map((df) {
                          final isSel = _dateFilter == df;
                          return PopupMenuItem(
                            value: df,
                            child: Row(
                              children: [
                                if (isSel) const Icon(Icons.check_rounded, size: 16, color: AppColors.income) else const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(df.label, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.normal)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Sort dropdown menu
                      PopupMenuButton<TransactionSortOrder>(
                        icon: const Icon(Icons.sort_rounded, size: 22),
                        tooltip: 'Urutkan Transaksi',
                        onSelected: (order) => setState(() => _sortOrder = order),
                        itemBuilder: (ctx) => TransactionSortOrder.values.map((order) {
                          final isSel = _sortOrder == order;
                          return PopupMenuItem(
                            value: order,
                            child: Row(
                              children: [
                                if (isSel) const Icon(Icons.check_rounded, size: 16, color: AppColors.income) else const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(order.label, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.normal)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Filter Pills with clear option
                  if (activeFiltersCount > 0) ...[
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_categoryFilter != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text('Kategori: $_categoryFilter', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                onDeleted: () => setState(() => _categoryFilter = null),
                              ),
                            ),
                          if (_sourceFilter != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text('Sumber: $_sourceFilter', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                onDeleted: () => setState(() => _sourceFilter = null),
                              ),
                            ),
                          if (_dateFilter != DateRangeFilter.all)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(_dateFilter.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                onDeleted: () => setState(() => _dateFilter = DateRangeFilter.all),
                              ),
                            ),
                          TextButton(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                            onPressed: () => setState(() {
                              _categoryFilter = null;
                              _sourceFilter = null;
                              _dateFilter = DateRangeFilter.all;
                              _selectedFilter = 'Semua';
                              _searchController.clear();
                              _displayedCount = 20;
                            }),
                            child: const Text('Reset Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Daily Grouped List with Infinite Scroll & Swipe Actions
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada transaksi yang cocok.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 84),
                      itemCount: dailyGroups.keys.length + (_displayedCount < _totalFilteredCount ? 1 : 0),
                      itemBuilder: (context, groupIndex) {
                        // Pagination loading tile at bottom
                        if (groupIndex == dailyGroups.keys.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: AstrackLiquidLoader.compact(size: 24),
                            ),
                          );
                        }

                        final dateKey = dailyGroups.keys.elementAt(groupIndex);
                        final dayTransactions = dailyGroups[dateKey]!;

                        // Calculate day total net
                        final dayExpense = dayTransactions
                            .where((t) => t.type == TransactionType.expense)
                            .fold(0.0, (sum, t) => sum + t.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Daily Header (List harian)
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4, right: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDateHeader(dateKey),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                  if (dayExpense > 0) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '-${CurrencyFormatter.format(dayExpense)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Day items with Swipe actions
                            ...dayTransactions.map((item) {
                              return Dismissible(
                                key: Key('tx_${item.id}'),
                                direction: DismissDirection.horizontal,
                                // Swipe right: Edit
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Swipe left: Delete
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.expense.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.expense)),
                                      SizedBox(width: 8),
                                      Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    // Swipe right -> Open Edit Sheet
                                    _openEditSheet(item);
                                    return false;
                                  } else {
                                    // Swipe left -> Delete
                                    finance.deleteTransaction(item.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Transaksi dihapus.')),
                                    );
                                    return true;
                                  }
                                },
                                child: TransactionTile(
                                  item: item,
                                  isDark: isDark,
                                  onTap: () => _showTransactionDetails(context, item),
                                  onDelete: () => finance.deleteTransaction(item.id),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
