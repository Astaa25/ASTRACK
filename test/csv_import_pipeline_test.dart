import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/core/utils/import_validator.dart';
import 'package:astrack/models/transaction_item.dart';

void main() {
  group('ASTRACK Phase 5 — CSV Import Pipeline & Duplicate Detection Tests', () {
    final existingTransactions = [
      TransactionItem(
        id: 'tx_existing_1',
        type: TransactionType.expense,
        amount: 50000,
        description: 'Beli Bensin SPBU',
        categoryId: 'cat_trans',
        categoryName: 'Transportasi',
        sourceId: 's1',
        sourceName: 'Dompet Utama',
        dateTime: DateTime(2026, 10, 1),
      ),
    ];

    test('Parses valid CSV rows into TransactionItem objects', () {
      const csvData = '''Tanggal,Keterangan,Kategori,Tipe,Nominal,Sumber Dana
2026-10-02,Makan Siang Soto Betawi,Makanan & Minuman,Pengeluaran,35000,Dompet Utama
2026-10-02,Gaji Freelance,Gaji,Pemasukan,1500000,Dompet Utama
''';

      final result = ImportValidator.validateCsvContent(
        fileName: 'test.csv',
        csvContent: csvData,
        existingTransactions: existingTransactions,
        defaultSourceId: 's1',
        defaultSourceName: 'Dompet Utama',
      );

      expect(result.isFileValid, isTrue);
      expect(result.totalRows, equals(2));
      expect(result.validCount, equals(2));
      expect(result.duplicateCount, equals(0));
      expect(result.invalidCount, equals(0));
      expect(result.validTransactionsToImport.length, equals(2));
    });

    test('Detects duplicate transactions against existing records without crashing', () {
      const csvData = '''Tanggal,Keterangan,Kategori,Tipe,Nominal,Sumber Dana
2026-10-01,Beli Bensin SPBU,Transportasi,Pengeluaran,50000,Dompet Utama
2026-10-03,Belanja Bulanan,Belanja,Pengeluaran,250000,Dompet Utama
''';

      final result = ImportValidator.validateCsvContent(
        fileName: 'records.csv',
        csvContent: csvData,
        existingTransactions: existingTransactions,
        defaultSourceId: 's1',
        defaultSourceName: 'Dompet Utama',
      );

      expect(result.totalRows, equals(2));
      expect(result.duplicateCount, equals(1)); // 'Beli Bensin SPBU' with same date & amount
      expect(result.validCount, equals(1)); // Only 'Belanja Bulanan' is imported
      expect(result.validTransactionsToImport.length, equals(1));
      expect(result.validTransactionsToImport.first.description, equals('Belanja Bulanan'));
    });

    test('Rejects invalid file format or oversized file per security rule', () {
      final extError = ImportValidator.validateFileSecurity(
        fileName: 'malicious_script.exe',
        fileSizeBytes: 1024,
      );
      expect(extError, contains('Format file tidak didukung'));

      final sizeError = ImportValidator.validateFileSecurity(
        fileName: 'huge_data.csv',
        fileSizeBytes: 10 * 1024 * 1024, // 10MB > 5MB limit
      );
      expect(sizeError, contains('melebihi batas 5MB'));
    });
  });
}
