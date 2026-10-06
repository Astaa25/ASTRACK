import '../models/financial_health_score.dart';
import '../models/transaction_item.dart';
import '../models/fund_source.dart';
import '../models/budget.dart';
import 'transaction_service.dart';

class FinancialHealthService {
  /// Deterministically calculates financial health score (0–100) based on:
  /// 1. Savings Rate (35 pts)
  /// 2. Budget Adherence (30 pts)
  /// 3. Emergency Fund Buffer (20 pts)
  /// 4. Recording Regularity (15 pts)
  static FinancialHealthScore calculate({
    required List<TransactionItem> transactions,
    required List<FundSource> sources,
    required List<Budget> budgets,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final thirtyDaysAgo = current.subtract(const Duration(days: 30));

    // Filter transactions from the last 30 days
    final recentTxs = transactions.where((t) => t.dateTime.isAfter(thirtyDaysAgo) && t.dateTime.isBefore(current.add(const Duration(days: 1)))).toList();

    // 1. Savings Rate Calculation (0 - 35 pts)
    final income = TransactionService.calculateTotalIncome(recentTxs);
    final expense = TransactionService.calculateTotalExpense(recentTxs);

    double actualSavingsRate = 0.0;
    double savingsRateScore = 0.0;

    if (income > 0) {
      actualSavingsRate = (income - expense) / income;
      if (actualSavingsRate >= 0.30) {
        savingsRateScore = 35.0;
      } else if (actualSavingsRate >= 0.20) {
        savingsRateScore = 25.0 + ((actualSavingsRate - 0.20) / 0.10) * 10.0;
      } else if (actualSavingsRate >= 0.10) {
        savingsRateScore = 15.0 + ((actualSavingsRate - 0.10) / 0.10) * 10.0;
      } else if (actualSavingsRate > 0.0) {
        savingsRateScore = (actualSavingsRate / 0.10) * 15.0;
      } else {
        savingsRateScore = 0.0;
      }
    } else {
      // No recorded income in last 30 days
      if (expense == 0) {
        actualSavingsRate = 0.0;
        savingsRateScore = 15.0; // Neutral starting score
      } else {
        actualSavingsRate = -1.0;
        savingsRateScore = 0.0;
      }
    }

    // 2. Budget Adherence Calculation (0 - 30 pts)
    final thisMonthBudgets = budgets.where((b) => b.month == current.month && b.year == current.year).toList();
    double budgetAdherenceScore = 15.0; // Default neutral if no budgets set
    double budgetUtilizationRate = 0.0;

    if (thisMonthBudgets.isNotEmpty) {
      final totalBudgetLimit = thisMonthBudgets.fold<double>(0.0, (sum, b) => sum + b.limitAmount);
      final totalBudgetSpent = thisMonthBudgets.fold<double>(0.0, (sum, b) => sum + b.spentAmount);

      if (totalBudgetLimit > 0) {
        budgetUtilizationRate = totalBudgetSpent / totalBudgetLimit;
      }

      int exceededCount = 0;
      for (final b in thisMonthBudgets) {
        if (b.isExceeded) {
          exceededCount++;
        }
      }

      if (exceededCount == 0) {
        if (budgetUtilizationRate <= 0.80) {
          budgetAdherenceScore = 30.0;
        } else if (budgetUtilizationRate <= 1.0) {
          budgetAdherenceScore = 24.0 + (1.0 - budgetUtilizationRate) * 30.0;
        } else {
          budgetAdherenceScore = 20.0;
        }
      } else {
        // Penalty for exceeding budgets
        final penalty = exceededCount * 8.0;
        budgetAdherenceScore = (22.0 - penalty).clamp(0.0, 30.0);
      }
    }

    // 3. Emergency Buffer Calculation (0 - 20 pts)
    final liquidBalance = TransactionService.calculateTotalBalance(sources).clamp(0.0, double.infinity);
    // Average monthly expense from recent transactions or fallback to positive minimum
    final monthlyExpenseEstimate = expense > 0 ? expense : (income > 0 ? income * 0.5 : 0.0);

    double emergencyBufferMonths = 0.0;
    double emergencyBufferScore = 0.0;

    if (monthlyExpenseEstimate > 0) {
      emergencyBufferMonths = liquidBalance / monthlyExpenseEstimate;
      if (emergencyBufferMonths >= 6.0) {
        emergencyBufferScore = 20.0;
      } else if (emergencyBufferMonths >= 3.0) {
        emergencyBufferScore = 15.0 + ((emergencyBufferMonths - 3.0) / 3.0) * 5.0;
      } else if (emergencyBufferMonths >= 1.0) {
        emergencyBufferScore = 8.0 + ((emergencyBufferMonths - 1.0) / 2.0) * 7.0;
      } else {
        emergencyBufferScore = (emergencyBufferMonths * 8.0).clamp(0.0, 8.0);
      }
    } else {
      emergencyBufferMonths = liquidBalance > 0 ? 6.0 : 0.0;
      emergencyBufferScore = liquidBalance > 0 ? 16.0 : 5.0;
    }

    // 4. Recording Regularity Calculation (0 - 15 pts)
    final distinctDays = <String>{};
    for (final t in recentTxs) {
      final key = '${t.dateTime.year}-${t.dateTime.month}-${t.dateTime.day}';
      distinctDays.add(key);
    }
    final activeRecordingDays = distinctDays.length;
    double recordingRegularityScore = 0.0;

    if (activeRecordingDays >= 15) {
      recordingRegularityScore = 15.0;
    } else if (activeRecordingDays >= 8) {
      recordingRegularityScore = 10.0 + ((activeRecordingDays - 8) / 7.0) * 5.0;
    } else if (activeRecordingDays >= 3) {
      recordingRegularityScore = 5.0 + ((activeRecordingDays - 3) / 5.0) * 5.0;
    } else if (activeRecordingDays >= 1) {
      recordingRegularityScore = 3.0;
    } else {
      recordingRegularityScore = 0.0;
    }

    // Total Overall Score
    final rawTotal = savingsRateScore + budgetAdherenceScore + emergencyBufferScore + recordingRegularityScore;
    final overallScore = rawTotal.round().clamp(0, 100);

    // Determine Grade
    HealthGrade grade;
    if (overallScore >= 85) {
      grade = HealthGrade.excellent;
    } else if (overallScore >= 70) {
      grade = HealthGrade.good;
    } else if (overallScore >= 50) {
      grade = HealthGrade.fair;
    } else {
      grade = HealthGrade.needsAttention;
    }

    // Generate Tailored Actionable Recommendations
    final recommendations = <String>[];

    if (savingsRateScore < 20.0) {
      if (actualSavingsRate < 0) {
        recommendations.add('Arus kas defisit (pengeluaran > pemasukan). Evaluasi kebutuhan non-esensial untuk mencegah pengikisan saldo.');
      } else {
        recommendations.add('Rasio tabungan masih di bawah 20%. Usahakan sisihkan dana di awal bulan (pay yourself first) minimal 10-20%.');
      }
    }

    if (thisMonthBudgets.isEmpty) {
      recommendations.add('Tetapkan batas anggaran untuk kategori pengeluaran terbesar Anda agar keuangan lebih terkontrol.');
    } else if (budgetAdherenceScore < 20.0) {
      recommendations.add('Terdapat anggaran yang terlampaui bulan ini. Periksa riwayat pengeluaran dan sesuaikan ritme belanja harian.');
    }

    if (emergencyBufferMonths < 3.0) {
      recommendations.add('Dana darurat saat ini mencakup ${emergencyBufferMonths.toStringAsFixed(1)} bulan pengeluaran. Targetkan cadangan minimal 3–6 bulan.');
    }

    if (recordingRegularityScore < 10.0) {
      recommendations.add('Tingkatkan frekuensi pencatatan transaksi harian Anda agar analisis cashflow tetap akurat.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Kondisi finansial Anda sangat prima! Pertahankan disiplin anggaran dan terus kembangkan target tabungan impian Anda.');
    }

    return FinancialHealthScore(
      overallScore: overallScore,
      grade: grade,
      savingsRateScore: double.parse(savingsRateScore.toStringAsFixed(1)),
      actualSavingsRate: double.parse(actualSavingsRate.toStringAsFixed(2)),
      budgetAdherenceScore: double.parse(budgetAdherenceScore.toStringAsFixed(1)),
      budgetUtilizationRate: double.parse(budgetUtilizationRate.toStringAsFixed(2)),
      emergencyBufferScore: double.parse(emergencyBufferScore.toStringAsFixed(1)),
      emergencyBufferMonths: double.parse(emergencyBufferMonths.toStringAsFixed(1)),
      recordingRegularityScore: double.parse(recordingRegularityScore.toStringAsFixed(1)),
      activeRecordingDays: activeRecordingDays,
      recommendations: recommendations,
    );
  }
}
