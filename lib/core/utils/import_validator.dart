import '../../models/transaction_item.dart';

class ImportRow {
  final int rowIndex;
  final bool isValid;
  final bool isDuplicate;
  final String? errorMessage;
  final TransactionItem? parsedTransaction;
  final Map<String, String> rawData;

  ImportRow({
    required this.rowIndex,
    required this.isValid,
    this.isDuplicate = false,
    this.errorMessage,
    this.parsedTransaction,
    required this.rawData,
  });
}

class ImportValidationResult {
  final String fileName;
  final int totalRows;
  final int validCount;
  final int invalidCount;
  final int duplicateCount;
  final List<ImportRow> rows;
  final bool isFileValid;
  final String? fileSecurityError;

  ImportValidationResult({
    required this.fileName,
    required this.totalRows,
    required this.validCount,
    required this.invalidCount,
    required this.duplicateCount,
    required this.rows,
    required this.isFileValid,
    this.fileSecurityError,
  });

  List<TransactionItem> get validTransactionsToImport =>
      rows.where((r) => r.isValid && !r.isDuplicate && r.parsedTransaction != null)
          .map((r) => r.parsedTransaction!)
          .toList();
}

class ImportValidator {
  // Max file size allowed: 5 MB
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['csv', 'json', 'txt'];

  /// Validate file security (extension, size, safety) per Part 69 §218
  static String? validateFileSecurity({
    required String fileName,
    required int fileSizeBytes,
  }) {
    final ext = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Format file tidak didukung (.$ext). Gunakan format CSV atau JSON.';
    }
    if (fileSizeBytes > maxFileSizeBytes) {
      return 'Ukuran file melebihi batas 5MB (${(fileSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB).';
    }
    return null;
  }

  /// Parse and validate CSV data
  static ImportValidationResult validateCsvContent({
    required String fileName,
    required String csvContent,
    required List<TransactionItem> existingTransactions,
    required String defaultSourceId,
    required String defaultSourceName,
  }) {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ImportValidationResult(
        fileName: fileName,
        totalRows: 0,
        validCount: 0,
        invalidCount: 0,
        duplicateCount: 0,
        rows: [],
        isFileValid: false,
        fileSecurityError: 'File kosong atau tidak memiliki baris data.',
      );
    }

    // Detect header
    final headerLine = lines.first;
    final headers = headerLine.split(',').map((h) => h.trim().replaceAll('"', '').toLowerCase()).toList();

    int dateCol = -1;
    int descCol = -1;
    int amountCol = -1;
    int incomeCol = -1;
    int expenseCol = -1;
    int categoryCol = -1;
    int typeCol = -1;

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (h.contains('tanggal') || h.contains('date')) dateCol = i;
      if (h.contains('keterangan') || h.contains('description') || h.contains('deskripsi')) descCol = i;
      if (h.contains('kategori') || h.contains('category')) categoryCol = i;
      if (h.contains('jenis') || h.contains('type') || h.contains('tipe')) typeCol = i;
      if (h.contains('jumlah') || h.contains('amount') || h.contains('nominal') || h.contains('total')) amountCol = i;
      if (h.contains('pemasukan') || h.contains('income') || h.contains('kredit')) incomeCol = i;
      if (h.contains('pengeluaran') || h.contains('expense') || h.contains('debit')) expenseCol = i;
    }

    // Must have date and description and at least one amount representation
    if (descCol == -1) {
      return ImportValidationResult(
        fileName: fileName,
        totalRows: lines.length - 1,
        validCount: 0,
        invalidCount: lines.length - 1,
        duplicateCount: 0,
        rows: [],
        isFileValid: false,
        fileSecurityError: 'Kolom Keterangan / Deskripsi tidak ditemukan dalam file.',
      );
    }

    final List<ImportRow> evaluatedRows = [];
    int validCount = 0;
    int invalidCount = 0;
    int duplicateCount = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final cols = line.split(',').map((c) => c.trim().replaceAll('"', '')).toList();

      final rawData = <String, String>{};
      for (int h = 0; h < headers.length && h < cols.length; h++) {
        rawData[headers[h]] = cols[h];
      }

      if (cols.length < headers.length) {
        evaluatedRows.add(ImportRow(
          rowIndex: i,
          isValid: false,
          errorMessage: 'Jumlah kolom tidak sesuai dengan header.',
          rawData: rawData,
        ));
        invalidCount++;
        continue;
      }

      final desc = cols[descCol];
      if (desc.isEmpty) {
        evaluatedRows.add(ImportRow(
          rowIndex: i,
          isValid: false,
          errorMessage: 'Keterangan tidak boleh kosong.',
          rawData: rawData,
        ));
        invalidCount++;
        continue;
      }

      DateTime date = DateTime.now();
      if (dateCol != -1 && dateCol < cols.length) {
        final parsedDate = DateTime.tryParse(cols[dateCol]);
        if (parsedDate != null) {
          date = parsedDate;
        }
      }

      double amount = 0.0;
      TransactionType type = TransactionType.expense;

      if (incomeCol != -1 && incomeCol < cols.length && cols[incomeCol].isNotEmpty) {
        final incVal = double.tryParse(cols[incomeCol].replaceAll(RegExp(r'[^\d.]'), ''));
        if (incVal != null && incVal > 0) {
          amount = incVal;
          type = TransactionType.income;
        }
      }

      if (amount == 0 && expenseCol != -1 && expenseCol < cols.length && cols[expenseCol].isNotEmpty) {
        final expVal = double.tryParse(cols[expenseCol].replaceAll(RegExp(r'[^\d.]'), ''));
        if (expVal != null && expVal > 0) {
          amount = expVal;
          type = TransactionType.expense;
        }
      }

      if (amount == 0 && amountCol != -1 && amountCol < cols.length) {
        final val = double.tryParse(cols[amountCol].replaceAll(RegExp(r'[^\d.]'), ''));
        if (val != null && val > 0) {
          amount = val;
          if (typeCol != -1 && typeCol < cols.length) {
            final tStr = cols[typeCol].toLowerCase();
            if (tStr.contains('income') || tStr.contains('pemasukan')) {
              type = TransactionType.income;
            } else if (tStr.contains('transfer')) {
              type = TransactionType.transfer;
            } else if (tStr.contains('saving') || tStr.contains('tabung')) {
              type = TransactionType.saving;
            } else {
              type = TransactionType.expense;
            }
          }
        }
      }

      if (amount <= 0) {
        evaluatedRows.add(ImportRow(
          rowIndex: i,
          isValid: false,
          errorMessage: 'Jumlah nominal harus lebih dari 0.',
          rawData: rawData,
        ));
        invalidCount++;
        continue;
      }

      final category = (categoryCol != -1 && categoryCol < cols.length && cols[categoryCol].isNotEmpty)
          ? cols[categoryCol]
          : 'Lainnya';

      // Check duplicates (Part 13 §76 & Part 31 §146)
      final isDup = existingTransactions.any((tx) =>
          tx.description.toLowerCase().trim() == desc.toLowerCase().trim() &&
          tx.amount == amount &&
          tx.dateTime.year == date.year &&
          tx.dateTime.month == date.month &&
          tx.dateTime.day == date.day);

      final transaction = TransactionItem(
        id: 'tx_imp_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: type,
        amount: amount,
        description: desc,
        categoryId: 'cat_import',
        categoryName: category,
        sourceId: defaultSourceId,
        sourceName: defaultSourceName,
        dateTime: date,
        notes: 'Diimpor dari file: $fileName',
      );

      if (isDup) {
        duplicateCount++;
      } else {
        validCount++;
      }

      evaluatedRows.add(ImportRow(
        rowIndex: i,
        isValid: true,
        isDuplicate: isDup,
        parsedTransaction: transaction,
        rawData: rawData,
      ));
    }

    return ImportValidationResult(
      fileName: fileName,
      totalRows: lines.length - 1,
      validCount: validCount,
      invalidCount: invalidCount,
      duplicateCount: duplicateCount,
      rows: evaluatedRows,
      isFileValid: true,
    );
  }
}
