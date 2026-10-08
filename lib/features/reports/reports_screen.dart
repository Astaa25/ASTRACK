import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/printable_report_service.dart';
import '../transactions/csv_import_screen.dart';
import '../subscription/models/astra_feature.dart';
import '../subscription/services/feature_gate_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!nextMonth.isAfter(DateTime(now.year, now.month))) {
      setState(() => _selectedMonth = nextMonth);
    }
  }

  void _exportJsonData(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final jsonStr = finance.exportData();

    Clipboard.setData(ClipboardData(text: jsonStr));

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Export Data Finansial (JSON)',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data berhasil disalin ke papan klip (Clipboard)! Anda dapat menyimpannya sebagai berkas backup cadangan.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jsonStr.length > 300 ? '${jsonStr.substring(0, 300)}...\n\n[Total ${jsonStr.length} karakter]' : jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _exportCsv(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final buffer = StringBuffer('ID,Tipe,Nominal,Keterangan,Kategori,Sumber Dana,Tanggal\n');
    for (final t in finance.transactions) {
      buffer.writeln('${t.id},${t.type.name},${t.amount},"${t.description}","${t.categoryName}","${t.sourceName}",${t.dateTime.toIso8601String()}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Data CSV transaksi berhasil disalin ke Clipboard!'),
        backgroundColor: AppColors.income,
      ),
    );
  }

  void _openPrintableReport(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final htmlContent = PrintableReportService.generateMonthlyReport(
      finance: finance,
      month: _selectedMonth,
    );

    // Copy HTML to clipboard and show preview dialog
    Clipboard.setData(ClipboardData(text: htmlContent));

    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final monthName = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF0ea5e9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Laporan Siap Cetak',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Laporan $monthName telah dibuat',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF059669).withAlpha(40)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'HTML laporan telah disalin ke clipboard. Langkah selanjutnya:',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...[
                    '1. Buka text editor / Notepad',
                    '2. Paste (Ctrl+V) isi clipboard',
                    '3. Simpan dengan ekstensi .html',
                    '4. Buka di browser → Cetak (Ctrl+P)',
                    '5. Pilih "Save as PDF" untuk simpan',
                  ].map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 26),
                        Expanded(child: Text(step, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Salin Ulang Laporan HTML', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: htmlContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ HTML laporan disalin ulang ke clipboard!'), backgroundColor: AppColors.emerald),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;
    final monthFmt = DateFormat('MMMM yyyy', 'id');
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    // Compute filtered stats
    final monthTx = finance.transactions.where((t) {
      return t.dateTime.year == _selectedMonth.year && t.dateTime.month == _selectedMonth.month;
    }).toList();

    double filteredIncome = 0, filteredExpense = 0;
    for (final t in monthTx) {
      if (t.type.name == 'income') filteredIncome += t.amount;
      if (t.type.name == 'expense') filteredExpense += t.amount;
    }
    final filteredNet = filteredIncome - filteredExpense;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Ekspor', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [

            // Month Picker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: textPrimary),
                    onPressed: _prevMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monthFmt.format(_selectedMonth),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${monthTx.length} transaksi',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: isCurrentMonth ? border : textPrimary,
                    ),
                    onPressed: isCurrentMonth ? null : _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Monthly Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkCard, AppColors.darkElevatedCard]
                      : [Colors.white, const Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ringkasan ${monthFmt.format(_selectedMonth)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRow('Total Kekayaan (Aset)', CurrencyFormatter.format(finance.totalBalance), primary, isDark),
                  const Divider(height: 20),
                  _buildRow('Pemasukan', CurrencyFormatter.format(filteredIncome), isDark ? AppColors.incomeDark : AppColors.income, isDark),
                  const Divider(height: 20),
                  _buildRow('Pengeluaran', CurrencyFormatter.format(filteredExpense), isDark ? AppColors.expenseDark : AppColors.expense, isDark),
                  const Divider(height: 20),
                  _buildRow(
                    'Arus Kas Bersih',
                    '${filteredNet >= 0 ? '+' : ''}${CurrencyFormatter.format(filteredNet)}',
                    filteredNet >= 0 ? (isDark ? AppColors.incomeDark : AppColors.income) : (isDark ? AppColors.expenseDark : AppColors.expense),
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Ekspor & Cetak Laporan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih format ekspor yang sesuai kebutuhan',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 14),

            // ─── Printable Report ───────────────────────────────────────────
            _buildExportTile(
              isDark: isDark,
              icon: Icons.picture_as_pdf_rounded,
              iconBg: const Color(0xFF059669),
              title: 'Laporan Bulanan Printable (HTML→PDF)',
              subtitle: 'Laporan profesional siap cetak dengan rincian kategori & transaksi',
              badgeText: 'Baru',
              badgeColor: const Color(0xFF059669),
              onTap: () {
                FeatureGateService.checkAndGate(
                  context,
                  feature: AstraFeatures.advancedReports,
                  onGranted: () => _openPrintableReport(context),
                );
              },
            ),

            const SizedBox(height: 10),

            // ─── CSV Export ─────────────────────────────────────────────────
            _buildExportTile(
              isDark: isDark,
              icon: Icons.table_chart_outlined,
              iconBg: AppColors.income,
              title: 'Ekspor Format CSV (Excel)',
              subtitle: 'Daftar riwayat transaksi terstruktur untuk dibuka di Excel',
              onTap: () => _exportCsv(context),
            ),

            const SizedBox(height: 10),

            // ─── CSV Import ─────────────────────────────────────────────────
            _buildExportTile(
              isDark: isDark,
              icon: Icons.file_upload_outlined,
              iconBg: const Color(0xFF0284C7),
              title: 'Impor Transaksi dari Berkas CSV',
              subtitle: 'Unggah atau tempel data riwayat rekening/pembukuan',
              onTap: () {
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

            const SizedBox(height: 10),

            // ─── JSON Backup ────────────────────────────────────────────────
            _buildExportTile(
              isDark: isDark,
              icon: Icons.backup_outlined,
              iconBg: AppColors.transfer,
              title: 'Cadangkan Data Lengkap (JSON)',
              subtitle: 'Termasuk seluruh akun, budget, tabungan & riwayat transaksi',
              onTap: () => _exportJsonData(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkMuted : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(isDark ? 25 : 6), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconBg, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? AppColors.income).withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: badgeColor ?? AppColors.income),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ),
        Text(value, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w800, color: valColor)),
      ],
    );
  }
}
