import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/services/financial_insight_service.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/models/budget.dart';

void main() {
  group('ASTRACK Phase 5 — Financial Insight Service Tests', () {
    final now = DateTime(2026, 10, 15); // Middle of October 2026

    final transactions = [
      // Current Month (October 2026)
      TransactionItem(
        id: 't1',
        type: TransactionType.income,
        amount: 10000000,
        description: 'Gaji Bulanan',
        categoryId: 'c_income',
        categoryName: 'Gaji',
        sourceId: 's1',
        sourceName: 'Rekening Bank',
        dateTime: DateTime(2026, 10, 1),
      ),
      TransactionItem(
        id: 't2',
        type: TransactionType.expense,
        amount: 2500000,
        description: 'Restoran & Belanja Makanan',
        categoryId: 'c_food',
        categoryName: 'Makanan & Minuman',
        sourceId: 's1',
        sourceName: 'Rekening Bank',
        dateTime: DateTime(2026, 10, 5),
      ),
      TransactionItem(
        id: 't3',
        type: TransactionType.expense,
        amount: 1000000,
        description: 'Bensin & Tol',
        categoryId: 'c_trans',
        categoryName: 'Transportasi',
        sourceId: 's1',
        sourceName: 'Rekening Bank',
        dateTime: DateTime(2026, 10, 10),
      ),

      // Last Month (September 2026)
      TransactionItem(
        id: 't4',
        type: TransactionType.expense,
        amount: 1800000,
        description: 'Makan September',
        categoryId: 'c_food',
        categoryName: 'Makanan & Minuman',
        sourceId: 's1',
        sourceName: 'Rekening Bank',
        dateTime: DateTime(2026, 9, 15),
      ),
    ];

    final budgets = [
      Budget(
        id: 'b1',
        categoryId: 'c_food',
        categoryName: 'Makanan & Minuman',
        limitAmount: 3000000,
        spentAmount: 2500000,
        month: 10,
        year: 2026,
      ),
    ];

    test('Generates top spending category and MoM increase insights', () {
      final insights = FinancialInsightService.generateInsights(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );

      expect(insights.isNotEmpty, isTrue);

      final topCategoryInsight = insights.firstWhere((i) => i.title == 'Kategori Pengeluaran Terbesar');
      expect(topCategoryInsight.description, contains('Makanan & Minuman'));

      final momInsight = insights.firstWhere((i) => i.title == 'Peningkatan Pengeluaran');
      expect(momInsight.description, contains('meningkat 39%'));
      expect(momInsight.isWarning, isTrue);
    });

    test('Forecasts budget burn rate and recommended daily spending', () {
      final insights = FinancialInsightService.generateInsights(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );

      final dailyInsight = insights.firstWhere((i) => i.title == 'Rekomendasi Belanja Harian');
      expect(dailyInsight.description, contains('/hari'));

      final burnRateInsight = insights.firstWhere((i) => i.title == 'Peringatan Laju Anggaran');
      expect(burnRateInsight.isWarning, isTrue);
    });

    test('Calculates positive savings rate', () {
      final insights = FinancialInsightService.generateInsights(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );

      final savingsInsight = insights.firstWhere((i) => i.title == 'Tingkat Tabungan (Savings Rate)');
      expect(savingsInsight.description, contains('65.0%'));
    });
  });
}
