import '../models/transaction_item.dart';
import '../models/fund_source.dart';
import '../models/budget.dart';

class TransactionCalculationResult {
  final List<FundSource> updatedSources;
  final List<TransactionItem> updatedTransactions;
  final List<Budget> updatedBudgets;

  TransactionCalculationResult({
    required this.updatedSources,
    required this.updatedTransactions,
    required this.updatedBudgets,
  });
}

class TransactionService {
  /// Deterministically apply a new transaction to fund sources and budgets
  static TransactionCalculationResult addTransaction({
    required TransactionItem transaction,
    required List<FundSource> currentSources,
    required List<TransactionItem> currentTransactions,
    required List<Budget> currentBudgets,
  }) {
    final sources = currentSources.map((s) => s.copyWith()).toList();
    final transactions = [transaction, ...currentTransactions];
    final budgets = currentBudgets.map((b) => b.copyWith()).toList();

    // 1. Update Sources deterministically
    final sourceIndex = sources.indexWhere((s) => s.id == transaction.sourceId);
    if (sourceIndex != -1) {
      final src = sources[sourceIndex];
      switch (transaction.type) {
        case TransactionType.income:
          sources[sourceIndex] = src.copyWith(balance: src.balance + transaction.amount);
          break;
        case TransactionType.expense:
          sources[sourceIndex] = src.copyWith(balance: src.balance - transaction.amount);
          break;
        case TransactionType.transfer:
        case TransactionType.saving:
          // Deduct from primary source
          sources[sourceIndex] = src.copyWith(balance: src.balance - transaction.amount);
          // Add to target source if exists
          if (transaction.targetSourceId != null) {
            final targetIndex = sources.indexWhere((s) => s.id == transaction.targetSourceId);
            if (targetIndex != -1) {
              final targetSrc = sources[targetIndex];
              sources[targetIndex] = targetSrc.copyWith(balance: targetSrc.balance + transaction.amount);
            }
          }
          break;
      }
    }

    // 2. Update Budgets if transaction is an expense
    if (transaction.type == TransactionType.expense) {
      for (int i = 0; i < budgets.length; i++) {
        if ((budgets[i].isOverall || budgets[i].categoryId == transaction.categoryId || budgets[i].categoryId == 'all') &&
            budgets[i].month == transaction.dateTime.month &&
            budgets[i].year == transaction.dateTime.year) {
          budgets[i] = budgets[i].copyWith(spentAmount: budgets[i].spentAmount + transaction.amount);
        }
      }
    }

    return TransactionCalculationResult(
      updatedSources: sources,
      updatedTransactions: transactions,
      updatedBudgets: budgets,
    );
  }

  /// Deterministically delete a transaction and reverse all financial effects
  static TransactionCalculationResult deleteTransaction({
    required String transactionId,
    required List<FundSource> currentSources,
    required List<TransactionItem> currentTransactions,
    required List<Budget> currentBudgets,
  }) {
    final txIndex = currentTransactions.indexWhere((t) => t.id == transactionId);
    if (txIndex == -1) {
      return TransactionCalculationResult(
        updatedSources: currentSources,
        updatedTransactions: currentTransactions,
        updatedBudgets: currentBudgets,
      );
    }

    final tx = currentTransactions[txIndex];
    final sources = currentSources.map((s) => s.copyWith()).toList();
    final transactions = List<TransactionItem>.from(currentTransactions)..removeAt(txIndex);
    final budgets = currentBudgets.map((b) => b.copyWith()).toList();

    // Reverse financial effect on sources
    final sourceIndex = sources.indexWhere((s) => s.id == tx.sourceId);
    if (sourceIndex != -1) {
      final src = sources[sourceIndex];
      switch (tx.type) {
        case TransactionType.income:
          // Reverse: subtract income
          sources[sourceIndex] = src.copyWith(balance: src.balance - tx.amount);
          break;
        case TransactionType.expense:
          // Reverse: add expense back
          sources[sourceIndex] = src.copyWith(balance: src.balance + tx.amount);
          break;
        case TransactionType.transfer:
        case TransactionType.saving:
          // Reverse: restore source balance
          sources[sourceIndex] = src.copyWith(balance: src.balance + tx.amount);
          // Reverse: deduct from target source
          if (tx.targetSourceId != null) {
            final targetIndex = sources.indexWhere((s) => s.id == tx.targetSourceId);
            if (targetIndex != -1) {
              final targetSrc = sources[targetIndex];
              sources[targetIndex] = targetSrc.copyWith(balance: targetSrc.balance - tx.amount);
            }
          }
          break;
      }
    }

    // Reverse effect on budgets
    if (tx.type == TransactionType.expense) {
      for (int i = 0; i < budgets.length; i++) {
        if ((budgets[i].isOverall || budgets[i].categoryId == tx.categoryId || budgets[i].categoryId == 'all') &&
            budgets[i].month == tx.dateTime.month &&
            budgets[i].year == tx.dateTime.year) {
          budgets[i] = budgets[i].copyWith(
            spentAmount: (budgets[i].spentAmount - tx.amount).clamp(0.0, double.infinity),
          );
        }
      }
    }

    return TransactionCalculationResult(
      updatedSources: sources,
      updatedTransactions: transactions,
      updatedBudgets: budgets,
    );
  }

  /// Deterministically edit a transaction: reverses old effects, applies new effects
  static TransactionCalculationResult editTransaction({
    required TransactionItem updatedTransaction,
    required List<FundSource> currentSources,
    required List<TransactionItem> currentTransactions,
    required List<Budget> currentBudgets,
  }) {
    // 1. Reverse previous effects
    final delResult = deleteTransaction(
      transactionId: updatedTransaction.id,
      currentSources: currentSources,
      currentTransactions: currentTransactions,
      currentBudgets: currentBudgets,
    );

    // 2. Apply new effects
    return addTransaction(
      transaction: updatedTransaction,
      currentSources: delResult.updatedSources,
      currentTransactions: delResult.updatedTransactions,
      currentBudgets: delResult.updatedBudgets,
    );
  }

  /// Total Wealth across all fund sources
  static double calculateTotalBalance(List<FundSource> sources) {
    return sources.fold(0.0, (sum, s) => sum + s.balance);
  }

  /// Total Income in a given date range
  static double calculateTotalIncome(List<TransactionItem> transactions, {DateTime? start, DateTime? end}) {
    return transactions.where((t) {
      if (t.type != TransactionType.income) return false;
      if (start != null && t.dateTime.isBefore(start)) return false;
      if (end != null && t.dateTime.isAfter(end)) return false;
      return true;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total Expense in a given date range
  static double calculateTotalExpense(List<TransactionItem> transactions, {DateTime? start, DateTime? end}) {
    return transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      if (start != null && t.dateTime.isBefore(start)) return false;
      if (end != null && t.dateTime.isAfter(end)) return false;
      return true;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Net Cash Flow = Total Income - Total Expense
  static double calculateNetCashFlow(List<TransactionItem> transactions, {DateTime? start, DateTime? end}) {
    final inc = calculateTotalIncome(transactions, start: start, end: end);
    final exp = calculateTotalExpense(transactions, start: start, end: end);
    return inc - exp;
  }

  /// Savings Rate = ((Income - Expense) / Income) * 100
  static double calculateSavingsRate(List<TransactionItem> transactions, {DateTime? start, DateTime? end}) {
    final inc = calculateTotalIncome(transactions, start: start, end: end);
    final exp = calculateTotalExpense(transactions, start: start, end: end);
    if (inc <= 0) return 0.0;
    final rate = ((inc - exp) / inc) * 100;
    return rate.clamp(0.0, 100.0);
  }

  /// Average Daily Spending
  static double calculateAverageDailySpending(List<TransactionItem> transactions, {DateTime? start, DateTime? end}) {
    final exp = calculateTotalExpense(transactions, start: start, end: end);
    if (exp <= 0) return 0.0;
    final s = start ?? (transactions.isNotEmpty ? transactions.last.dateTime : DateTime.now());
    final e = end ?? DateTime.now();
    final days = e.difference(s).inDays + 1;
    return days > 0 ? (exp / days) : exp;
  }

  /// Top Expense Categories breakdown
  static Map<String, double> calculateTopCategories(List<TransactionItem> transactions, {DateTime? start, DateTime? end, int limit = 5}) {
    final totals = <String, double>{};
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      if (start != null && t.dateTime.isBefore(start)) continue;
      if (end != null && t.dateTime.isAfter(end)) continue;
      totals[t.categoryName] = (totals[t.categoryName] ?? 0.0) + t.amount;
    }
    final sortedEntries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(limit));
  }

  /// Overall Budget Utilization Percentage
  static double calculateBudgetUtilization(List<Budget> budgets) {
    if (budgets.isEmpty) return 0.0;
    final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    if (totalLimit <= 0) return 0.0;
    return (totalSpent / totalLimit) * 100.0;
  }

  /// Safe to Spend Daily:
  /// Liquid funds divided by remaining days in current month, factoring in budget limits.
  static double calculateSafeToSpend({
    required List<FundSource> sources,
    List<Budget> budgets = const [],
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final lastDayOfMonth = DateTime(current.year, current.month + 1, 0).day;
    final remainingDays = (lastDayOfMonth - current.day + 1).clamp(1, 31);

    // Liquid funds: prioritize default source (e.g. Uang Jajan) or total positive balances
    double liquidBalance = 0.0;
    final defaultSources = sources.where((s) => s.isDefault).toList();
    if (defaultSources.isNotEmpty) {
      liquidBalance = defaultSources.fold(0.0, (sum, s) => sum + s.balance);
    } else if (sources.isNotEmpty) {
      liquidBalance = sources.first.balance;
    }

    if (liquidBalance <= 0) {
      liquidBalance = calculateTotalBalance(sources).clamp(0.0, double.infinity);
    }

    // Factor in monthly budgets if defined
    double safeFromBudget = double.infinity;
    final thisMonthBudgets = budgets.where((b) => b.month == current.month && b.year == current.year).toList();
    if (thisMonthBudgets.isNotEmpty) {
      final totalBudgetLimit = thisMonthBudgets.fold(0.0, (sum, b) => sum + b.limitAmount);
      final totalBudgetSpent = thisMonthBudgets.fold(0.0, (sum, b) => sum + b.spentAmount);
      final remainingBudget = (totalBudgetLimit - totalBudgetSpent).clamp(0.0, double.infinity);
      safeFromBudget = remainingBudget / remainingDays;
    }

    final dailyFromLiquid = (liquidBalance / remainingDays).clamp(0.0, double.infinity);
    if (safeFromBudget.isFinite) {
      return dailyFromLiquid < safeFromBudget ? dailyFromLiquid : safeFromBudget;
    }
    return dailyFromLiquid;
  }
}

