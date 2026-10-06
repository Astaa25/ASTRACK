import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/utils/import_validator.dart';
import '../../core/utils/currency_formatter.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _textController = TextEditingController();
  ImportValidationResult? _validationResult;
  bool _isAnalyzing = false;

  void _analyzeCsv() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan teks atau salin data CSV terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final result = finance.validateCsvImport('import_manual.csv', text);

    setState(() {
      _validationResult = result;
      _isAnalyzing = false;
    });
  }

  void _loadSampleData() {
    _textController.text = '''Tanggal,Keterangan,Kategori,Tipe,Nominal,Sumber Dana
2026-10-01,Makan Siang Nasi Padang,Makanan & Minuman,Pengeluaran,28000,Dompet Utama
2026-10-01,Gaji Bulanan,Gaji,Pemasukan,5000000,Rekening Bank
2026-10-02,Beli Pulsa & Kuota,Tagihan,Pengeluaran,50000,Dompet Utama
''';
    _analyzeCsv();
  }

  void _executeImport() {
    final result = _validationResult;
    if (result == null || result.validTransactionsToImport.isEmpty) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final count = result.validTransactionsToImport.length;

    for (final tx in result.validTransactionsToImport) {
      finance.addTransaction(tx);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil mengimpor $count transaksi ke dalam catatan keuangan!'),
        backgroundColor: AppColors.income,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textS = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final result = _validationResult;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Impor Transaksi CSV', style: TextStyle(fontWeight: FontWeight.w800, color: textP)),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textP),
        actions: [
          TextButton(
            onPressed: _loadSampleData,
            child: const Text('Contoh CSV', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedCard : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.income, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Format Kolom CSV yang Didukung',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textP),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Header minimal: Tanggal, Keterangan, Kategori, Tipe, Nominal, Sumber Dana.\n'
                    'Sistem akan otomatis memvalidasi duplikasi data dan memeriksa kecocokan format sebelum diimpor.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: textS),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Textarea
            Text('Tempel / Masukkan Data CSV:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textP)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 6,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: textP),
              decoration: InputDecoration(
                hintText: 'Tanggal,Keterangan,Kategori,Tipe,Nominal,Sumber Dana\n2026-10-01,Kopi,Makanan & Minuman,Pengeluaran,25000,Dompet',
                fillColor: cardBg,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeCsv,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isAnalyzing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.table_view_rounded),
              label: const Text('Pratinjau & Validasi CSV', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            // Validation Results Preview
            if (result != null) ...[
              Text('Hasil Pratinjau & Validasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textP)),
              const SizedBox(height: 10),

              // Summary Counters
              Row(
                children: [
                  Expanded(
                    child: _buildCounterCard(
                      label: 'Valid',
                      count: result.validCount,
                      color: AppColors.income,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCounterCard(
                      label: 'Duplikat',
                      count: result.duplicateCount,
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCounterCard(
                      label: 'Gagal',
                      count: result.invalidCount,
                      color: AppColors.expense,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rows preview list
              ...result.rows.map((row) {
                final tx = row.parsedTransaction;
                final isOk = row.isValid && !row.isDuplicate;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOk
                          ? AppColors.income.withOpacity(0.3)
                          : row.isDuplicate
                              ? AppColors.warning.withOpacity(0.4)
                              : AppColors.expense.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOk
                            ? Icons.check_circle_rounded
                            : row.isDuplicate
                                ? Icons.copy_rounded
                                : Icons.error_outline_rounded,
                        color: isOk
                            ? AppColors.income
                            : row.isDuplicate
                                ? AppColors.warning
                                : AppColors.expense,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx != null ? tx.description : 'Baris #${row.rowIndex}',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textP),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOk
                                  ? '${tx?.categoryName} • ${tx != null ? CurrencyFormatter.format(tx.amount) : ""}'
                                  : (row.errorMessage ?? 'Data tidak valid'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isOk ? textS : (row.isDuplicate ? AppColors.warning : AppColors.expense),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              if (result.validTransactionsToImport.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _executeImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.download_done_rounded),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Konfirmasi & Simpan (${result.validTransactionsToImport.length} Transaksi)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
