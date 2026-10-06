import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astrack/data/storage/storage_service.dart';
import 'package:astrack/providers/finance_provider.dart';
import 'package:astrack/providers/theme_provider.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/models/fund_source.dart';
import 'package:astrack/models/category.dart';
import 'package:astrack/models/budget.dart';
import 'package:astrack/models/savings_goal.dart';
import 'package:astrack/models/recurring_transaction.dart';
import 'package:astrack/models/financial_health_score.dart';
import 'package:astrack/services/financial_health_service.dart';
import 'package:astrack/features/budget/budget_screen.dart';
import 'package:astrack/features/savings/savings_screen.dart';
import 'package:astrack/features/statistics/statistics_screen.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late StorageService storage;
  late FinanceProvider finance;
  late ThemeProvider theme;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    finance = FinanceProvider(storage);
    theme = ThemeProvider(storage);

    // Initialize clean test fixtures
    final sources = [
      FundSource(id: 'src_wallet', name: 'Uang Jajan', balance: 5000000.0, isDefault: true),
      FundSource(id: 'src_savings', name: 'Tabungan BCA', balance: 25000000.0),
    ];
    final categories = [
      FinancialCategory(id: 'cat_food', name: 'Food & Beverage', iconName: 'food', colorHex: 'EF4444', type: CategoryType.expense),
      FinancialCategory(id: 'cat_bills', name: 'Bills & Utilities', iconName: 'bill', colorHex: '3B82F6', type: CategoryType.expense),
      FinancialCategory(id: 'cat_salary', name: 'Salary', iconName: 'work', colorHex: '10B981', type: CategoryType.income),
    ];

    for (final s in sources) {
      finance.addFundSource(s);
    }
    for (final c in categories) {
      finance.addCategory(c);
    }
  });

  group('Fase 2: Deterministic Financial Health Score (0-100)', () {
    test('Calculates Grade A (Sangat Sehat) for high savings rate and strong emergency buffer', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final sources = [
        FundSource(id: 's1', name: 'Uang Jajan', balance: 10000000.0, isDefault: true),
        FundSource(id: 's2', name: 'Dana Darurat', balance: 60000000.0),
      ];
      final budgets = [
        Budget(
          id: 'b1',
          categoryId: 'cat_food',
          categoryName: 'Food',
          limitAmount: 4000000.0,
          spentAmount: 2500000.0,
          month: 10,
          year: 2026,
        ),
      ];

      // Income 20 jt, Expense 5 jt in last 30 days -> Savings rate 75%
      final txs = <TransactionItem>[
        TransactionItem(
          id: 't_inc',
          type: TransactionType.income,
          amount: 20000000.0,
          description: 'Gaji',
          categoryId: 'cat_salary',
          categoryName: 'Salary',
          sourceId: 's1',
          sourceName: 'Uang Jajan',
          dateTime: now.subtract(const Duration(days: 5)),
        ),
      ];

      // 15 days of active recording
      for (int i = 1; i <= 15; i++) {
        txs.add(
          TransactionItem(
            id: 't_exp_$i',
            type: TransactionType.expense,
            amount: 300000.0,
            description: 'Makan $i',
            categoryId: 'cat_food',
            categoryName: 'Food',
            sourceId: 's1',
            sourceName: 'Uang Jajan',
            dateTime: now.subtract(Duration(days: i)),
          ),
        );
      }

      final score = FinancialHealthService.calculate(
        transactions: txs,
        sources: sources,
        budgets: budgets,
        now: now,
      );

      expect(score.overallScore, greaterThanOrEqualTo(85));
      expect(score.grade, equals(HealthGrade.excellent));
      expect(score.grade.gradeLetter, equals('A'));
      expect(score.savingsRateScore, equals(35.0));
      expect(score.budgetAdherenceScore, equals(30.0));
      expect(score.emergencyBufferScore, equals(20.0));
      expect(score.recordingRegularityScore, equals(15.0));
      expect(score.recommendations.first, contains('prima'));
    });

    test('Calculates Grade D (Perlu Pembenahan) for deficit spending and exceeded budget', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final sources = [
        FundSource(id: 's1', name: 'Uang Jajan', balance: 200000.0, isDefault: true),
      ];
      final budgets = [
        Budget(
          id: 'b1',
          categoryId: 'cat_food',
          categoryName: 'Food',
          limitAmount: 2000000.0,
          spentAmount: 3500000.0, // Exceeded!
          month: 10,
          year: 2026,
        ),
      ];

      // Income 3 jt, Expense 6 jt -> Deficit
      final txs = [
        TransactionItem(
          id: 't_inc',
          type: TransactionType.income,
          amount: 3000000.0,
          description: 'Pemasukan Kecil',
          categoryId: 'cat_salary',
          categoryName: 'Salary',
          sourceId: 's1',
          sourceName: 'Uang Jajan',
          dateTime: now.subtract(const Duration(days: 20)),
        ),
        TransactionItem(
          id: 't_exp',
          type: TransactionType.expense,
          amount: 6000000.0,
          description: 'Belanja Besar',
          categoryId: 'cat_food',
          categoryName: 'Food',
          sourceId: 's1',
          sourceName: 'Uang Jajan',
          dateTime: now.subtract(const Duration(days: 2)),
        ),
      ];

      final score = FinancialHealthService.calculate(
        transactions: txs,
        sources: sources,
        budgets: budgets,
        now: now,
      );

      expect(score.overallScore, lessThan(50));
      expect(score.grade, equals(HealthGrade.needsAttention));
      expect(score.grade.gradeLetter, equals('D'));
      expect(score.savingsRateScore, equals(0.0));
      expect(score.recommendations, anyElement(contains('defisit')));
    });

    test('Handles brand new user with 0 transactions without crash or NaN', () {
      final score = FinancialHealthService.calculate(
        transactions: [],
        sources: [FundSource(id: 's1', name: 'Uang Jajan', balance: 0.0)],
        budgets: [],
        now: DateTime(2026, 10, 6),
      );

      expect(score.overallScore, isNot(isNaN));
      expect(score.overallScore, inInclusiveRange(0, 100));
      expect(score.recommendations.isNotEmpty, isTrue);
    });
  });

  group('Fase 2: Budgeting Engine & Burn-Rate', () {
    test('Calculates burn-rate, planned daily allowance, and 80%/100% alert thresholds', () {
      final budget = Budget(
        id: 'b1',
        categoryId: 'cat_food',
        categoryName: 'Food',
        limitAmount: 3100000.0,
        spentAmount: 2500000.0, // 80.6% -> Warning!
        month: 10,
        year: 2026,
      );

      expect(budget.totalDaysInMonth, equals(31));
      expect(budget.percentUsed, closeTo(80.64, 0.1));
      expect(budget.alertState, equals(BudgetAlertState.warning));
      expect(budget.plannedDailySpending, closeTo(100000.0, 1.0));
      expect(budget.burnRate, greaterThan(0));
      expect(budget.rolloverBalance, equals(600000.0));

      final exceededBudget = budget.copyWith(spentAmount: 3200000.0);
      expect(exceededBudget.isExceeded, isTrue);
      expect(exceededBudget.alertState, equals(BudgetAlertState.exceeded));
      expect(exceededBudget.recommendedDailySpending, equals(0.0));
    });

    test('Overall budget tracks expenses concurrently with category budgets', () {
      final now = DateTime.now();
      final catBudget = Budget(
        id: 'b_cat',
        categoryId: 'cat_food',
        categoryName: 'Food',
        limitAmount: 2000000.0,
        spentAmount: 0.0,
        month: now.month,
        year: now.year,
        isOverall: false,
      );
      final overallBudget = Budget(
        id: 'b_overall',
        categoryId: 'all',
        categoryName: 'Total Semua',
        limitAmount: 5000000.0,
        spentAmount: 0.0,
        month: now.month,
        year: now.year,
        isOverall: true,
      );

      finance.addBudget(catBudget);
      finance.addBudget(overallBudget);

      // Add expense in cat_food
      final tx = TransactionItem(
        id: 'tx_bgt_test',
        type: TransactionType.expense,
        amount: 500000.0,
        description: 'Makan Resto',
        categoryId: 'cat_food',
        categoryName: 'Food & Beverage',
        sourceId: 'src_wallet',
        sourceName: 'Uang Jajan',
        dateTime: now,
      );

      finance.addTransaction(tx);

      final updatedCat = finance.budgets.firstWhere((b) => b.id == 'b_cat');
      final updatedOverall = finance.budgets.firstWhere((b) => b.id == 'b_overall');

      expect(updatedCat.spentAmount, equals(500000.0));
      expect(updatedOverall.spentAmount, equals(500000.0));

      // Deleting expense reverses both
      finance.deleteTransaction('tx_bgt_test');
      final revertedCat = finance.budgets.firstWhere((b) => b.id == 'b_cat');
      final revertedOverall = finance.budgets.firstWhere((b) => b.id == 'b_overall');

      expect(revertedCat.spentAmount, equals(0.0));
      expect(revertedOverall.spentAmount, equals(0.0));
    });

    test('Monthly rollover transfers unspent surplus to next month', () {
      final now = DateTime.now();
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth <= 0) {
        prevMonth = 12;
        prevYear--;
      }

      // Add budget in previous month with unspent surplus of 400.000 for a unique category
      final prevBudget = Budget(
        id: 'b_prev',
        categoryId: 'cat_rollover_unique',
        categoryName: 'Investasi',
        limitAmount: 2000000.0,
        spentAmount: 1600000.0,
        month: prevMonth,
        year: prevYear,
      );
      finance.addBudget(prevBudget);

      final rolledCount = finance.rolloverPreviousMonthBudgets(carryOverSurplus: true);
      expect(rolledCount, greaterThanOrEqualTo(1));

      final thisMonthBudget = finance.budgets.firstWhere(
        (b) => b.categoryId == 'cat_rollover_unique' && b.month == now.month && b.year == now.year,
      );
      // New limit should be base 2.000.000 + surplus 400.000 = 2.400.000
      expect(thisMonthBudget.limitAmount, equals(2400000.0));
      expect(thisMonthBudget.spentAmount, equals(0.0));
    });
  });

  group('Fase 2: Savings Goals Engine & Atomic Mutations', () {
    test('Calculates milestones and auto-recommended deposit pace', () {
      final deadline = DateTime.now().add(const Duration(days: 100));
      final goal = SavingsGoal(
        id: 'svg_laptop',
        name: 'Beli MacBook',
        targetAmount: 20000000.0,
        currentAmount: 11000000.0, // 55%
        sourceId: 'src_savings',
        sourceName: 'Tabungan BCA',
        deadline: deadline,
      );

      expect(goal.milestone25, isTrue);
      expect(goal.milestone50, isTrue);
      expect(goal.milestone75, isFalse);
      expect(goal.milestone100, isFalse);
      expect(goal.highestMilestone, equals(50));
      expect(goal.remainingAmount, equals(9000000.0));
      expect(goal.recommendedDailySaving, closeTo(90000.0, 5000.0));
      expect(goal.recommendedMonthlySaving, greaterThan(0));
    });

    test('Atomic deposit and withdraw mutate ledger and goal balances with 100% integrity', () {
      final goal = SavingsGoal(
        id: 'svg_motor',
        name: 'Beli Motor',
        targetAmount: 10000000.0,
        currentAmount: 0.0,
        sourceId: 'src_savings',
        sourceName: 'Tabungan BCA',
      );
      finance.addSavingsGoal(goal);

      final initialWalletBalance = finance.sources.firstWhere((s) => s.id == 'src_wallet').balance;
      final initialSavingsBalance = finance.sources.firstWhere((s) => s.id == 'src_savings').balance;

      // 1. Deposit 2.000.000 from Wallet to Savings Goal
      finance.depositToSavingsGoal(
        savingsGoalId: 'svg_motor',
        amount: 2000000.0,
        fromSourceId: 'src_wallet',
      );

      final updatedGoal = finance.savings.firstWhere((g) => g.id == 'svg_motor');
      expect(updatedGoal.currentAmount, equals(2000000.0));
      expect(updatedGoal.milestone25, isFalse); // 20% < 25%

      final postDepositWallet = finance.sources.firstWhere((s) => s.id == 'src_wallet').balance;
      final postDepositSavings = finance.sources.firstWhere((s) => s.id == 'src_savings').balance;
      expect(postDepositWallet, equals(initialWalletBalance - 2000000.0));
      expect(postDepositSavings, equals(initialSavingsBalance + 2000000.0));

      // 2. Withdraw 500.000 from Savings Goal back to Wallet
      finance.withdrawFromSavingsGoal(
        savingsGoalId: 'svg_motor',
        amount: 500000.0,
        toSourceId: 'src_wallet',
      );

      final postWithdrawGoal = finance.savings.firstWhere((g) => g.id == 'svg_motor');
      expect(postWithdrawGoal.currentAmount, equals(1500000.0));

      final finalWallet = finance.sources.firstWhere((s) => s.id == 'src_wallet').balance;
      final finalSavings = finance.sources.firstWhere((s) => s.id == 'src_savings').balance;
      expect(finalWallet, equals(initialWalletBalance - 1500000.0));
      expect(finalSavings, equals(initialSavingsBalance + 1500000.0));
    });
  });

  group('Fase 2: Recurring Transactions & Month-End Clamping', () {
    test('Preserves scheduledDay 31 when transitioning through shorter months (Feb -> Mar)', () {
      final recurring = RecurringTransaction(
        id: 'rec_rent',
        description: 'Sewa Apartemen',
        amount: 3000000.0,
        type: TransactionType.expense,
        categoryId: 'cat_bills',
        categoryName: 'Bills',
        sourceId: 'src_wallet',
        sourceName: 'Uang Jajan',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 1, 31),
        nextOccurrence: DateTime(2026, 1, 31),
        scheduledDay: 31,
      );

      // 1. From Jan 31 -> calculate next date for February 2026 (non-leap year, 28 days)
      final febDate = recurring.calculateNextDate(DateTime(2026, 1, 31));
      expect(febDate.month, equals(2));
      expect(febDate.day, equals(28)); // Safely clamped to 28

      // 2. From Feb 28 -> calculate next date for March 2026 (31 days)
      final marDate = recurring.calculateNextDate(febDate);
      expect(marDate.month, equals(3));
      // CRITICAL: Must jump back to 31, not stay degraded at 28!
      expect(marDate.day, equals(31));

      // 3. From Mar 31 -> calculate next date for April 2026 (30 days)
      final aprDate = recurring.calculateNextDate(marDate);
      expect(aprDate.month, equals(4));
      expect(aprDate.day, equals(30)); // Clamped to 30

      // 4. From Apr 30 -> calculate next date for May 2026 (31 days)
      final mayDate = recurring.calculateNextDate(aprDate);
      expect(mayDate.month, equals(5));
      expect(mayDate.day, equals(31)); // Jumps back to 31!
    });

    test('executeRecurringImmediately records transaction now and advances occurrence', () {
      final recurring = RecurringTransaction(
        id: 'rec_gym',
        description: 'Gym Membership',
        amount: 350000.0,
        type: TransactionType.expense,
        categoryId: 'cat_bills',
        categoryName: 'Bills',
        sourceId: 'src_wallet',
        sourceName: 'Uang Jajan',
        frequency: RecurringFrequency.monthly,
        startDate: DateTime(2026, 10, 1),
        nextOccurrence: DateTime(2026, 10, 25),
        scheduledDay: 25,
      );

      finance.addRecurring(recurring);
      final initialTxCount = finance.transactions.length;

      finance.executeRecurringImmediately('rec_gym');

      expect(finance.transactions.length, equals(initialTxCount + 1));
      final generatedTx = finance.transactions.first;
      expect(generatedTx.amount, equals(350000.0));
      expect(generatedTx.description, contains('Gym Membership'));

      final updatedRecurring = finance.recurring.firstWhere((r) => r.id == 'rec_gym');
      expect(updatedRecurring.nextOccurrence.month, equals(11));
      expect(updatedRecurring.nextOccurrence.day, equals(25));
    });
  });

  group('Fase 2: Presentation & Widget Tests', () {
    testWidgets('BudgetScreen renders with burn-rate and overall budget', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          financeProvider: finance,
          themeProvider: theme,
          child: const BudgetScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anggaran (Budget)'), findsOneWidget);
      expect(find.text('Kontrol Pengeluaran Bulan Ini'), findsOneWidget);
    });

    testWidgets('SavingsScreen renders with milestone badges', (tester) async {
      for (final g in List<SavingsGoal>.from(finance.savings)) {
        finance.deleteSavingsGoal(g.id);
      }

      finance.addSavingsGoal(
        SavingsGoal(
          id: 'svg_test',
          name: 'Dana Liburan',
          targetAmount: 5000000.0,
          currentAmount: 2500000.0,
          sourceId: 'src_savings',
          sourceName: 'Tabungan BCA',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          financeProvider: finance,
          themeProvider: theme,
          child: const SavingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Target Tabungan'), findsOneWidget);
      expect(find.text('Dana Liburan'), findsOneWidget);
      expect(find.text('50%'), findsWidgets);
      expect(find.text('Nabung'), findsOneWidget);
      expect(find.text('Tarik'), findsOneWidget);
    });

    testWidgets('StatisticsScreen renders with 3 tabs including Skor Kesehatan', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          financeProvider: finance,
          themeProvider: theme,
          child: const StatisticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Statistik & Analisis'), findsOneWidget);
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('Tren 6 Bulan'), findsOneWidget);
      expect(find.text('Skor Kesehatan'), findsOneWidget);

      // Switch to Skor Kesehatan tab
      await tester.tap(find.text('Skor Kesehatan'));
      await tester.pumpAndSettle();

      expect(find.text('4 Pilar Penilaian Finansial'), findsOneWidget);
      expect(find.text('Rekomendasi Tindakan'), findsOneWidget);
      expect(find.textContaining('Rasio Tabungan'), findsOneWidget);
      expect(find.textContaining('Disiplin Anggaran'), findsOneWidget);
      expect(find.textContaining('Cadangan Dana Darurat'), findsOneWidget);
    });
  });
}
