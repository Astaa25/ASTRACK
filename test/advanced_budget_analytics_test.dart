import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/models/budget.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/services/transaction_service.dart';

void main() {
  group('ASTRACK Advanced Budget & Financial Analytics Tests', () {
    test('Budget alert thresholds: safe, warning, critical, exceeded', () {
      final now = DateTime.now();

      // Safe (< 70%)
      final safeBudget = Budget(
        id: 'b1',
        categoryId: 'c1',
        categoryName: 'Food',
        limitAmount: 1000000,
        spentAmount: 500000,
        month: now.month,
        year: now.year,
      );
      expect(safeBudget.alertState, BudgetAlertState.safe);
      expect(safeBudget.remaining, 500000.0);
      expect(safeBudget.isExceeded, isFalse);

      // Warning (>= 70%)
      final warnBudget = safeBudget.copyWith(spentAmount: 750000);
      expect(warnBudget.alertState, BudgetAlertState.warning);

      // Critical (>= 90%)
      final critBudget = safeBudget.copyWith(spentAmount: 920000);
      expect(critBudget.alertState, BudgetAlertState.critical);

      // Exceeded (>= 100%)
      final excBudget = safeBudget.copyWith(spentAmount: 1100000);
      expect(excBudget.alertState, BudgetAlertState.exceeded);
      expect(excBudget.remaining, 0.0);
      expect(excBudget.isExceeded, isTrue);
      expect(excBudget.recommendedDailySpending, 0.0);
    });

    test('Financial analytics: net cash flow, savings rate, daily average, top categories', () {
      final now = DateTime.now();
      final transactions = [
        TransactionItem(
          id: 't1',
          type: TransactionType.income,
          amount: 5000000,
          description: 'Gaji Bulanan',
          categoryId: 'c_inc',
          categoryName: 'Gaji',
          sourceId: 's1',
          sourceName: 'BCA',
          dateTime: DateTime(now.year, now.month, 1),
        ),
        TransactionItem(
          id: 't2',
          type: TransactionType.expense,
          amount: 1500000,
          description: 'Belanja Bulanan',
          categoryId: 'c_groceries',
          categoryName: 'Belanja',
          sourceId: 's1',
          sourceName: 'BCA',
          dateTime: DateTime(now.year, now.month, 2),
        ),
        TransactionItem(
          id: 't3',
          type: TransactionType.expense,
          amount: 500000,
          description: 'Nongkrong Kafe',
          categoryId: 'c_food',
          categoryName: 'Makanan & Minuman',
          sourceId: 's1',
          sourceName: 'BCA',
          dateTime: DateTime(now.year, now.month, 3),
        ),
      ];

      // Net Cash Flow = 5.000.000 - 2.000.000 = 3.000.000
      final netCash = TransactionService.calculateNetCashFlow(transactions);
      expect(netCash, 3000000.0);

      // Savings Rate = (3.000.000 / 5.000.000) * 100 = 60%
      final savingsRate = TransactionService.calculateSavingsRate(transactions);
      expect(savingsRate, 60.0);

      // Top categories
      final topCats = TransactionService.calculateTopCategories(transactions);
      expect(topCats['Belanja'], 1500000.0);
      expect(topCats['Makanan & Minuman'], 500000.0);
    });
  });
}
