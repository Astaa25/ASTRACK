import '../models/transaction_item.dart';
import '../models/budget.dart';
import '../core/utils/currency_formatter.dart';

class FinancialInsight {
  final String title;
  final String description;
  final String category; // 'spending', 'budget', 'saving', 'recommendation'
  final bool isWarning;

  FinancialInsight({
    required this.title,
    required this.description,
    required this.category,
    this.isWarning = false,
  });
}

class FinancialInsightService {
  /// Generate deterministic, data-driven financial insights
  static List<FinancialInsight> generateInsights({
    required List<TransactionItem> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = <FinancialInsight>[];

    // Filter current month transactions
    final currentMonthTx = transactions.where((t) =>
        t.dateTime.year == now.year && t.dateTime.month == now.month).toList();

    // Filter last month transactions
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthTx = transactions.where((t) =>
        t.dateTime.year == lastMonthDate.year && t.dateTime.month == lastMonthDate.month).toList();

    final currentExpenses = currentMonthTx.where((t) => t.type == TransactionType.expense).toList();
    final lastExpenses = lastMonthTx.where((t) => t.type == TransactionType.expense).toList();

    final currentTotalExpense = currentExpenses.fold(0.0, (s, t) => s + t.amount);

    final currentTotalIncome = currentMonthTx
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);

    // 1. Average Daily Spending Insight
    final daysPassed = now.day > 0 ? now.day : 1;
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (totalDaysInMonth - now.day).clamp(0, 31);

    if (currentTotalExpense > 0) {
      final avgDaily = currentTotalExpense / daysPassed;
      insights.add(FinancialInsight(
        title: 'Rata-Rata Pengeluaran Harian',
        description: 'Rata-rata pengeluaran harian kamu bulan ini adalah ${CurrencyFormatter.format(avgDaily)}.',
        category: 'spending',
      ));
    }

    // 2. Top Spending Category Insight
    if (currentExpenses.isNotEmpty) {
      final catMap = <String, double>{};
      for (final tx in currentExpenses) {
        catMap[tx.categoryName] = (catMap[tx.categoryName] ?? 0.0) + tx.amount;
      }
      final sortedCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topCat = sortedCats.first;
      final pct = currentTotalExpense > 0 ? (topCat.value / currentTotalExpense * 100).toStringAsFixed(1) : '0';

      insights.add(FinancialInsight(
        title: 'Kategori Pengeluaran Terbesar',
        description: 'Kategori "${topCat.key}" menjadi pos pengeluaran terbesar bulan ini (${CurrencyFormatter.format(topCat.value)} atau $pct% dari total pengeluaran).',
        category: 'spending',
      ));

      // 3. Month-over-month category trend
      if (lastExpenses.isNotEmpty) {
        final lastCatMap = <String, double>{};
        for (final tx in lastExpenses) {
          lastCatMap[tx.categoryName] = (lastCatMap[tx.categoryName] ?? 0.0) + tx.amount;
        }

        final lastTopCatVal = lastCatMap[topCat.key] ?? 0.0;
        if (lastTopCatVal > 0) {
          final diff = topCat.value - lastTopCatVal;
          final pctChange = ((diff / lastTopCatVal) * 100).abs().toStringAsFixed(0);
          if (diff > 0) {
            insights.add(FinancialInsight(
              title: 'Peningkatan Pengeluaran',
              description: 'Pengeluaran untuk "${topCat.key}" bulan ini meningkat $pctChange% dibanding bulan lalu.',
              category: 'spending',
              isWarning: true,
            ));
          } else if (diff < 0) {
            insights.add(FinancialInsight(
              title: 'Penghematan Tercapai',
              description: 'Kamu berhasil menghemat $pctChange% untuk kategori "${topCat.key}" dibanding bulan lalu!',
              category: 'spending',
            ));
          }
        }
      }
    }

    // 4. Budget Burn Rate & Exhaustion Forecast
    final totalBudgetLimit = budgets.fold(0.0, (s, b) => s + b.limitAmount);
    final totalBudgetSpent = budgets.fold(0.0, (s, b) => s + b.spentAmount);

    if (totalBudgetLimit > 0) {
      final remainingBudget = totalBudgetLimit - totalBudgetSpent;
      final avgDailySpend = daysPassed > 0 ? (totalBudgetSpent / daysPassed) : 0.0;

      if (remainingBudget > 0 && daysRemaining > 0) {
        final recommendedDaily = remainingBudget / daysRemaining;
        insights.add(FinancialInsight(
          title: 'Rekomendasi Belanja Harian',
          description: 'Untuk menjaga anggaran tetap aman hingga akhir bulan, batas belanja harian yang disarankan adalah ${CurrencyFormatter.format(recommendedDaily)}/hari.',
          category: 'recommendation',
        ));

        if (avgDailySpend > recommendedDaily * 1.2) {
          final daysUntilExhausted = avgDailySpend > 0 ? (remainingBudget / avgDailySpend).floor() : 0;
          final earlyDays = daysRemaining - daysUntilExhausted;
          if (earlyDays > 0) {
            insights.add(FinancialInsight(
              title: 'Peringatan Laju Anggaran',
              description: 'Jika pola pengeluaran ini berlanjut, anggaran diperkirakan habis $earlyDays hari lebih awal dari akhir bulan.',
              category: 'budget',
              isWarning: true,
            ));
          }
        }
      } else if (remainingBudget <= 0) {
        insights.add(FinancialInsight(
          title: 'Anggaran Melebihi Batas',
          description: 'Total pengeluaran telah melampaui batas anggaran yang direncanakan bulan ini sebesar ${CurrencyFormatter.format(totalBudgetSpent - totalBudgetLimit)}.',
          category: 'budget',
          isWarning: true,
        ));
      }
    }

    // 5. Savings Rate Trend
    if (currentTotalIncome > 0) {
      final currentSavings = currentTotalIncome - currentTotalExpense;
      final currentSavingsRate = ((currentSavings / currentTotalIncome) * 100).clamp(0.0, 100.0);

      insights.add(FinancialInsight(
        title: 'Tingkat Tabungan (Savings Rate)',
        description: 'Tingkat tabungan kamu bulan ini adalah ${currentSavingsRate.toStringAsFixed(1)}%. ' +
            (currentSavingsRate >= 20 ? 'Sangat sehat! Pertahankan di atas 20%.' : 'Coba tingkatkan menuju minimal 20%.'),
        category: 'saving',
      ));
    }

    return insights;
  }
}
