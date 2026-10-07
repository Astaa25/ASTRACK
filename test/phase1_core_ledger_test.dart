import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:astrack/models/fund_source.dart';
import 'package:astrack/models/category.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/models/budget.dart';
import 'package:astrack/services/transaction_service.dart';
import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/features/transactions/add_transaction_sheet.dart';
import 'package:astrack/features/transactions/transactions_screen.dart';
import 'package:astrack/features/dashboard/dashboard_screen.dart';

Widget createTestApp({
  required Widget child,
  FinanceProvider? financeProvider,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      if (themeProvider != null)
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      if (financeProvider != null)
        ChangeNotifierProvider<FinanceProvider>.value(value: financeProvider),
    ],
    child: MaterialApp(
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Fase 1: Category & FundSource Models with Soft-Archive', () {
    test('FinancialCategory supports isArchived, isDefault, and copyWith', () {
      final cat = FinancialCategory(
        id: 'cat_test_1',
        name: 'Kopi & Nongkrong',
        iconName: 'local_cafe',
        colorHex: 'F59E0B',
        type: CategoryType.expense,
        isDefault: true,
      );

      expect(cat.isArchived, isFalse);
      expect(cat.isDefault, isTrue);

      final archived = cat.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
      expect(archived.name, 'Kopi & Nongkrong');

      // JSON serialization roundtrip
      final json = archived.toJson();
      expect(json['isArchived'], isTrue);
      expect(json['isDefault'], isTrue);

      final fromJson = FinancialCategory.fromJson(json);
      expect(fromJson.id, cat.id);
      expect(fromJson.isArchived, isTrue);
      expect(fromJson.isDefault, isTrue);
    });

    test('FundSource model represents core funds with defaults', () {
      final fund = FundSource(
        id: 'src_jajan',
        name: 'Uang Jajan',
        balance: 500000.0,
        isDefault: true,
      );

      expect(fund.isDefault, isTrue);
      expect(fund.balance, 500000.0);

      final json = fund.toJson();
      final restored = FundSource.fromJson(json);
      expect(restored.name, 'Uang Jajan');
      expect(restored.isDefault, isTrue);
    });
  });

  group('Fase 1: TransactionItem with 4 Types & Idempotency Key', () {
    test('TransactionItem serializes 4 types and idempotencyKey', () {
      final txSaving = TransactionItem(
        id: 'tx_sav_1',
        type: TransactionType.saving,
        amount: 250000.0,
        description: 'Alokasi Tabungan Darurat',
        categoryId: 'cat_saving',
        categoryName: 'Menabung',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: DateTime(2026, 10, 5, 10, 0),
        idempotencyKey: 'idemp_uuid_test_123',
      );

      expect(txSaving.type, TransactionType.saving);
      expect(txSaving.idempotencyKey, 'idemp_uuid_test_123');

      final json = txSaving.toJson();
      expect(json['type'], 'saving');
      expect(json['idempotencyKey'], 'idemp_uuid_test_123');

      final restored = TransactionItem.fromJson(json);
      expect(restored.type, TransactionType.saving);
      expect(restored.targetSourceName, 'Tabungan');
      expect(restored.idempotencyKey, 'idemp_uuid_test_123');
    });
  });

  group('Fase 1: TransactionService Atomic Calculations', () {
    late List<FundSource> initialSources;
    late List<Budget> initialBudgets;

    setUp(() {
      initialSources = [
        FundSource(id: 'src_jajan', name: 'Uang Jajan', balance: 500000.0, isDefault: true),
        FundSource(id: 'src_tabungan', name: 'Tabungan', balance: 1000000.0),
      ];
      initialBudgets = [
        Budget(id: 'b_food', categoryId: 'cat_food', categoryName: 'Food', limitAmount: 600000.0, spentAmount: 100000.0, month: 10, year: 2026),
      ];
    });

    test('TransactionType.income adds to source balance deterministically', () {
      final tx = TransactionItem(
        id: 'tx_inc',
        type: TransactionType.income,
        amount: 150000.0,
        description: 'Uang Tambahan',
        categoryId: 'cat_salary',
        categoryName: 'Salary',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(2026, 10, 5),
      );

      final res = TransactionService.addTransaction(
        transaction: tx,
        currentSources: initialSources,
        currentTransactions: [],
        currentBudgets: initialBudgets,
      );

      expect(res.updatedSources.firstWhere((s) => s.id == 'src_jajan').balance, 650000.0);
    });

    test('TransactionType.expense deducts from source and increments budget spent', () {
      final tx = TransactionItem(
        id: 'tx_exp',
        type: TransactionType.expense,
        amount: 50000.0,
        description: 'Makan Siang',
        categoryId: 'cat_food',
        categoryName: 'Food',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(2026, 10, 5),
      );

      final res = TransactionService.addTransaction(
        transaction: tx,
        currentSources: initialSources,
        currentTransactions: [],
        currentBudgets: initialBudgets,
      );

      expect(res.updatedSources.firstWhere((s) => s.id == 'src_jajan').balance, 450000.0);
      expect(res.updatedBudgets.firstWhere((b) => b.id == 'b_food').spentAmount, 150000.0);
    });

    test('TransactionType.transfer moves money between sources atomically', () {
      final tx = TransactionItem(
        id: 'tx_trf',
        type: TransactionType.transfer,
        amount: 100000.0,
        description: 'Transfer ke Tabungan',
        categoryId: 'cat_transfer',
        categoryName: 'Transfer',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: DateTime(2026, 10, 5),
      );

      final res = TransactionService.addTransaction(
        transaction: tx,
        currentSources: initialSources,
        currentTransactions: [],
        currentBudgets: initialBudgets,
      );

      expect(res.updatedSources.firstWhere((s) => s.id == 'src_jajan').balance, 400000.0);
      expect(res.updatedSources.firstWhere((s) => s.id == 'src_tabungan').balance, 1100000.0);
    });

    test('TransactionType.saving mutates saving allocation atomically', () {
      final tx = TransactionItem(
        id: 'tx_sav',
        type: TransactionType.saving,
        amount: 200000.0,
        description: 'Setor Tabungan Impian',
        categoryId: 'cat_saving',
        categoryName: 'Menabung',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: DateTime(2026, 10, 5),
      );

      final res = TransactionService.addTransaction(
        transaction: tx,
        currentSources: initialSources,
        currentTransactions: [],
        currentBudgets: initialBudgets,
      );

      expect(res.updatedSources.firstWhere((s) => s.id == 'src_jajan').balance, 300000.0);
      expect(res.updatedSources.firstWhere((s) => s.id == 'src_tabungan').balance, 1200000.0);
    });

    test('deleteTransaction reverses all financial mutations accurately', () {
      final tx = TransactionItem(
        id: 'tx_exp',
        type: TransactionType.expense,
        amount: 50000.0,
        description: 'Makan Siang',
        categoryId: 'cat_food',
        categoryName: 'Food',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(2026, 10, 5),
      );

      // Add
      final addRes = TransactionService.addTransaction(
        transaction: tx,
        currentSources: initialSources,
        currentTransactions: [],
        currentBudgets: initialBudgets,
      );

      // Delete (Reverse)
      final delRes = TransactionService.deleteTransaction(
        transactionId: 'tx_exp',
        currentSources: addRes.updatedSources,
        currentTransactions: addRes.updatedTransactions,
        currentBudgets: addRes.updatedBudgets,
      );

      expect(delRes.updatedSources.firstWhere((s) => s.id == 'src_jajan').balance, 500000.0);
      expect(delRes.updatedBudgets.firstWhere((b) => b.id == 'b_food').spentAmount, 100000.0);
      expect(delRes.updatedTransactions.isEmpty, isTrue);
    });

    test('calculateSafeToSpend deterministically calculates daily allowance', () {
      final now = DateTime(2026, 10, 5); // 31 days in October, 27 days remaining (5 to 31 = 27 days)
      final safe = TransactionService.calculateSafeToSpend(
        sources: initialSources, // Uang Jajan = 500.000
        budgets: [],
        now: now,
      );

      final expectedDaily = 500000.0 / 27; // approx 18,518.5
      expect(safe, closeTo(expectedDaily, 0.1));
    });
  });

  group('Fase 1: FinanceProvider Idempotency & Soft-Archive', () {
    late StorageService storage;
    late FinanceProvider finance;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      finance = FinanceProvider(storage);
    });

    test('Idempotency prevents duplicate transaction submission', () {
      final initialBalance = finance.totalBalance;
      const idempotencyKey = 'unique_idemp_key_101';

      final tx = TransactionItem(
        id: 'tx_dup_1',
        type: TransactionType.expense,
        amount: 25000.0,
        description: 'Beli Camilan',
        categoryId: 'cat_food',
        categoryName: 'Food & Beverage',
        sourceId: finance.sources.first.id,
        sourceName: finance.sources.first.name,
        dateTime: DateTime.now(),
        idempotencyKey: idempotencyKey,
      );

      // First call -> success
      finance.addTransaction(tx);
      expect(finance.totalBalance, initialBalance - 25000.0);
      expect(finance.transactions.any((t) => t.id == 'tx_dup_1'), isTrue);

      // Second identical call -> blocked by idempotency guard
      finance.addTransaction(tx);
      // Balance MUST NOT be deducted twice!
      expect(finance.totalBalance, initialBalance - 25000.0);
    });

    test('Soft archive preserves categories used by transactions', () {
      final usedCat = finance.categories.firstWhere((c) => c.name == 'Coffee');
      expect(finance.activeCategories.any((c) => c.id == usedCat.id), isTrue);

      // Add a test transaction using this category to verify soft-archive behaviour
      finance.addTransaction(TransactionItem(
        id: 'tx_soft_arch_test',
        type: TransactionType.expense,
        amount: 25000.0,
        description: 'Beli Kopi',
        categoryId: usedCat.id,
        categoryName: usedCat.name,
        sourceId: finance.sources.first.id,
        sourceName: finance.sources.first.name,
        dateTime: DateTime.now(),
      ));

      // Delete category that is in use -> triggers soft archive
      final success = finance.deleteCategory(usedCat.id);
      expect(success, isTrue);

      // Category should now be in archivedCategories, NOT activeCategories
      expect(finance.activeCategories.any((c) => c.id == usedCat.id), isFalse);
      expect(finance.archivedCategories.any((c) => c.id == usedCat.id), isTrue);

      // Transactions using that category still exist and have valid categoryId
      expect(finance.transactions.any((t) => t.categoryId == usedCat.id), isTrue);

      // Unarchive restores category to active
      finance.unarchiveCategory(usedCat.id);
      expect(finance.activeCategories.any((c) => c.id == usedCat.id), isTrue);
      expect(finance.archivedCategories.any((c) => c.id == usedCat.id), isFalse);
    });

    test('Fund source can be updated with new balance and name', () {
      final src = finance.sources.first;
      final updated = src.copyWith(name: 'Uang Jajan Premium', balance: 999000.0);

      finance.updateFundSource(updated);
      expect(finance.sources.firstWhere((s) => s.id == src.id).name, 'Uang Jajan Premium');
      expect(finance.sources.firstWhere((s) => s.id == src.id).balance, 999000.0);
    });
  });

  group('Fase 1: UI Widgets (AddTransactionSheet, TransactionsScreen, DashboardScreen)', () {
    late StorageService storage;
    late FinanceProvider finance;
    late ThemeProvider theme;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      finance = FinanceProvider(storage);
      theme = ThemeProvider(storage);
    });

    testWidgets('AddTransactionSheet displays 4 types: Pengeluaran, Pemasukan, Transfer, Menabung', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          financeProvider: finance,
          themeProvider: theme,
          child: const Scaffold(
            body: AddTransactionSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catat Transaksi'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Menabung'), findsOneWidget);

      // Tap on 'Menabung'
      await tester.tap(find.text('Menabung'));
      await tester.pumpAndSettle();

      expect(find.text('Ke Rekening Tabungan'), findsOneWidget);
    });

    testWidgets('TransactionsScreen displays daily grouped headers, search, and type filters', (tester) async {
      finance.addTransaction(TransactionItem(
        id: 'tx_ui_coffee_1',
        type: TransactionType.expense,
        amount: 18000.0,
        description: 'Coffee Latte',
        categoryId: 'cat_coffee',
        categoryName: 'Coffee',
        sourceId: finance.sources.first.id,
        sourceName: finance.sources.first.name,
        dateTime: DateTime.now(),
      ));

      await tester.pumpWidget(
        createTestApp(
          financeProvider: finance,
          themeProvider: theme,
          child: const TransactionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Transaksi'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Menabung'), findsOneWidget);

      // Verify daily grouping headers or transaction tiles are rendered
      expect(find.text('Coffee Latte'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders Fund Sources Carousel and Safe-to-Spend Card', (tester) async {
      finance.addFundSource(FundSource(
        id: 'src_tabungan_test',
        name: 'Tabungan',
        balance: 2000000.0,
        iconName: 'piggy_bank',
      ));

      await tester.pumpWidget(
        createTestApp(
          financeProvider: finance,
          themeProvider: theme,
          child: const DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sumber Dana'), findsOneWidget);
      expect(find.text('Dompet Utama'), findsAtLeastNWidgets(1));
      expect(find.text('Tabungan'), findsAtLeastNWidgets(1));
      expect(find.text('Aman Dibelanjakan Hari Ini'), findsOneWidget);
    });
  });
}
