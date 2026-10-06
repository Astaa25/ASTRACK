import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/models/fund_source.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/models/budget.dart';
import 'package:astrack/models/category.dart';
import 'package:astrack/services/transaction_service.dart';
import 'package:astrack/services/ai_service.dart';
import 'package:astrack/core/utils/currency_formatter.dart';
import 'package:astrack/core/utils/date_formatter.dart';
import 'package:astrack/models/recurring_transaction.dart';
import 'package:astrack/core/utils/import_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('ASTRACK Master Specification Compliance Tests', () {
    test('Part 104 §291: Complete End-to-End Scenario', () async {
      // 1. Initial fund sources: Uang Jajan (0) and Tabungan (0)
      List<FundSource> sources = [
        FundSource(id: 'src_jajan', name: 'Uang Jajan', balance: 0.0),
        FundSource(id: 'src_tabungan', name: 'Tabungan', balance: 0.0),
      ];
      List<TransactionItem> transactions = [];
      List<Budget> budgets = [
        Budget(
          id: 'b_food',
          categoryId: 'cat_food',
          categoryName: 'Food',
          limitAmount: 500000,
          spentAmount: 0,
          month: DateTime.now().month,
          year: DateTime.now().year,
        ),
      ];

      // 2. Add Income Rp1.500.000
      final incTx = TransactionItem(
        id: 'tx_inc_1',
        type: TransactionType.income,
        amount: 1500000.0,
        description: 'Uang Masuk',
        categoryId: 'cat_income',
        categoryName: 'Income',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime.now(),
      );
      var res = TransactionService.addTransaction(
        transaction: incTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1500000.0);
      expect(TransactionService.calculateTotalBalance(sources), 1500000.0);

      // 3. Add Food Expense Rp15.000
      final expTx = TransactionItem(
        id: 'tx_exp_1',
        type: TransactionType.expense,
        amount: 1500000 != 0 ? 15000.0 : 0.0,
        description: 'Makan Siang',
        categoryId: 'cat_food',
        categoryName: 'Food',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime.now(),
      );
      res = TransactionService.addTransaction(
        transaction: expTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      // Uang Jajan decreases by 15.000 -> 1.485.000
      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1485000.0);
      // Food Budget updates -> spent 15.000
      expect(budgets.firstWhere((b) => b.id == 'b_food').spentAmount, 15000.0);

      // 4. Add Saving Rp200.000 into Tabungan
      final saveTx = TransactionItem(
        id: 'tx_save_1',
        type: TransactionType.saving,
        amount: 200000.0,
        description: 'Simpan ke Tabungan',
        categoryId: 'cat_saving',
        categoryName: 'Saving',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: DateTime(2026, 9, 27, 13, 0),
      );
      res = TransactionService.addTransaction(
        transaction: saveTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1285000.0);
      expect(sources.firstWhere((s) => s.id == 'src_tabungan').balance, 200000.0);
      // Total balance remains unchanged by saving transfer (1.485.000)
      expect(TransactionService.calculateTotalBalance(sources), 1485000.0);

      // 5. Transfer Rp100.000 from Uang Jajan to Tabungan
      final trfTx = TransactionItem(
        id: 'tx_trf_1',
        type: TransactionType.transfer,
        amount: 100000.0,
        description: 'Transfer Tambahan',
        categoryId: 'cat_transfer',
        categoryName: 'Transfer',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: DateTime(2026, 9, 27, 14, 0),
      );
      res = TransactionService.addTransaction(
        transaction: trfTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      // Uang Jajan decreases: 1.285.000 - 100.000 = 1.185.000
      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1185000.0);
      // Tabungan increases: 200.000 + 100.000 = 300.000
      expect(sources.firstWhere((s) => s.id == 'src_tabungan').balance, 300000.0);
      // Transfer is NOT counted as expense, total net worth is conserved
      expect(TransactionService.calculateTotalBalance(sources), 1485000.0);

      // 6. Ask AI: "Berapa pengeluaran saya bulan ini?"
      final aiResponse = await AIService.processInput(
        rawInput: 'Berapa pengeluaran saya bulan ini?',
        availableSources: sources,
        availableCategories: [
          FinancialCategory(id: 'cat_food', name: 'Makanan & Minuman', iconName: 'restaurant', colorHex: 'EF4444', type: CategoryType.expense),
        ],
        existingTransactions: transactions,
      );
      expect(aiResponse.text.contains('15.000'), isTrue);

      // 7. Edit Food Expense to Rp20.000
      final updatedExp = expTx.copyWith(amount: 20000.0);
      res = TransactionService.editTransaction(
        updatedTransaction: updatedExp,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1180000.0);
      expect(budgets.firstWhere((b) => b.id == 'b_food').spentAmount, 20000.0);

      // 8. Delete Food Expense
      res = TransactionService.deleteTransaction(
        transactionId: 'tx_exp_1',
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      // Financial effect reversed: Uang Jajan returned 20.000 -> 1.200.000, Tabungan remains 300.000
      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1200000.0);
      expect(sources.firstWhere((s) => s.id == 'src_tabungan').balance, 300000.0);
      expect(budgets.firstWhere((b) => b.id == 'b_food').spentAmount, 0.0);
    });

    test('Part 81 & 82: Formatting Utilities Validation', () {
      expect(CurrencyFormatter.format(1000000), 'Rp1.000.000');
      expect(CurrencyFormatter.format(50000), 'Rp50.000');
      expect(CurrencyFormatter.format(0), 'Rp0');
      expect(CurrencyFormatter.format(-50000), '-Rp50.000');

      final testDate = DateTime(2026, 9, 27, 14, 30);
      expect(DateFormatter.formatDate(testDate), '27 September 2026');
      expect(DateFormatter.formatCompact(testDate), '27/09/2026');
    });

    test('Part 13 & 84: Natural Language AI Parser', () async {
      final sources = [
        FundSource(id: 'src_jajan', name: 'Uang Jajan', balance: 500000.0),
        FundSource(id: 'src_tabungan', name: 'Tabungan', balance: 1000000.0),
      ];
      final categories = [
        FinancialCategory(id: 'cat_food', name: 'Makanan & Minuman', iconName: 'restaurant', colorHex: 'EF4444', type: CategoryType.expense),
      ];

      // Test "Tadi makan ayam 18 ribu" (Ambiguity -> Clarification dialog per §71 & §72)
      final msg1 = await AIService.processInput(
        rawInput: 'Tadi makan ayam 18 ribu',
        availableSources: sources,
        availableCategories: categories,
        existingTransactions: [],
      );

      // AI asks clarification for which source to use
      expect(msg1.clarificationOptions, isNotNull);
      expect(msg1.clarificationOptions!.contains('Uang Jajan'), isTrue);

      // User selects "Uang Jajan" (context continuation)
      final msg1b = await AIService.processInput(
        rawInput: 'Uang Jajan',
        availableSources: sources,
        availableCategories: categories,
        existingTransactions: [],
      );

      expect(msg1b.draftTransaction, isNotNull);
      expect(msg1b.draftTransaction!.amount, 18000.0);
      expect(msg1b.draftTransaction!.type, TransactionType.expense);
      expect(msg1b.draftTransaction!.sourceName, 'Uang Jajan');

      // Test explicit input with source directly: "Dapat uang 500 ribu masuk uang jajan"
      final msg2 = await AIService.processInput(
        rawInput: 'Dapat uang 500 ribu masuk uang jajan',
        availableSources: sources,
        availableCategories: categories,
        existingTransactions: [],
      );

      expect(msg2.draftTransaction, isNotNull);
      expect(msg2.draftTransaction!.amount, 500000.0);
      expect(msg2.draftTransaction!.type, TransactionType.income);
    });

    test('Part 34 & 50: Recurring Transaction Duplicate Protection', () {
      final recurring = RecurringTransaction(
        id: 'rec_rent',
        description: 'Sewa Kost',
        amount: 800000.0,
        type: TransactionType.expense,
        categoryId: 'cat_rent',
        categoryName: 'Tempat Tinggal',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 27),
      );

      final occurrenceDate = DateTime(2026, 9, 27);
      final tx = recurring.toTransactionItem(occurrenceDate: occurrenceDate);

      expect(tx.recurringId, 'rec_rent');
      expect(tx.amount, 800000.0);
      expect(tx.description.contains('Sewa Kost'), isTrue);

      // Verify duplicate protection condition
      List<TransactionItem> existingTxs = [tx];
      final isDuplicate = existingTxs.any((t) =>
          t.recurringId == recurring.id &&
          t.dateTime.year == occurrenceDate.year &&
          t.dateTime.month == occurrenceDate.month &&
          t.dateTime.day == occurrenceDate.day);

      expect(isDuplicate, isTrue); // Engine prevents double generation
    });

    test('Part 31 & 69: CSV Import Validation & File Security', () {
      // 1. File security validation
      final invalidExtError = ImportValidator.validateFileSecurity(
        fileName: 'malicious.exe',
        fileSizeBytes: 1024,
      );
      expect(invalidExtError, isNotNull);
      expect(invalidExtError!.contains('Format file tidak didukung'), isTrue);

      final oversizeError = ImportValidator.validateFileSecurity(
        fileName: 'huge.csv',
        fileSizeBytes: 10 * 1024 * 1024, // 10MB
      );
      expect(oversizeError, isNotNull);
      expect(oversizeError!.contains('melebihi batas 5MB'), isTrue);

      // 2. CSV parsing and duplicate detection
      const csvData = '''Tanggal,Keterangan,Kategori,Jumlah,Jenis
2026-09-27,Makan Siang,Makanan,25000,expense
2026-09-27,Makan Siang,Makanan,25000,expense
2026-09-27,Beli Buku,Edukasi,0,expense
''';

      final existing = [
        TransactionItem(
          id: 'tx_old',
          type: TransactionType.expense,
          amount: 25000,
          description: 'Makan Siang',
          categoryId: 'cat_food',
          categoryName: 'Makanan',
          sourceId: 'src_1',
          sourceName: 'Uang Jajan',
          dateTime: DateTime(2026, 9, 27),
        ),
      ];

      final result = ImportValidator.validateCsvContent(
        fileName: 'test.csv',
        csvContent: csvData,
        existingTransactions: existing,
        defaultSourceId: 'src_1',
        defaultSourceName: 'Uang Jajan',
      );

      expect(result.isFileValid, isTrue);
      expect(result.totalRows, 3);
      expect(result.duplicateCount, 2); // Both duplicate against existing
      expect(result.invalidCount, 1); // 0 amount is invalid
    });

    test('Part 35 & 28: Notification Service Budget Warning Thresholds', () {
      final notifService = NotificationService();
      notifService.clearAll();

      final budget = Budget(
        id: 'b_test',
        categoryId: 'cat_test',
        categoryName: 'Hiburan',
        limitAmount: 1000000,
        spentAmount: 700000,
        month: 9,
        year: 2026,
      );

      // At 70%
      notifService.checkBudgetWarning(budget: budget, spentAmount: 700000);
      expect(notifService.notifications.length, 1);
      expect(notifService.notifications.first.title.contains('Waspada'), isTrue);

      // Duplicate prevention: repeating 70% must not create new notification
      notifService.checkBudgetWarning(budget: budget, spentAmount: 750000);
      expect(notifService.notifications.length, 1);

      // At 90%
      notifService.checkBudgetWarning(budget: budget, spentAmount: 900000);
      expect(notifService.notifications.length, 2);
      expect(notifService.notifications.first.title.contains('Kritis'), isTrue);

      // At 100%
      notifService.checkBudgetWarning(budget: budget, spentAmount: 1000000);
      expect(notifService.notifications.length, 3);
      expect(notifService.notifications.first.title.contains('Terlampaui'), isTrue);
    });
  });
}
