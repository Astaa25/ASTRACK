enum BudgetAlertState {
  safe,
  warning,
  critical,
  exceeded;

  String get label {
    switch (this) {
      case BudgetAlertState.safe:
        return 'Aman (<80%)';
      case BudgetAlertState.warning:
        return 'Waspada (80%+)';
      case BudgetAlertState.critical:
        return 'Kritis (90%+)';
      case BudgetAlertState.exceeded:
        return 'Terlampaui (100%+)';
    }
  }

  String get icon {
    switch (this) {
      case BudgetAlertState.safe:
        return '✅';
      case BudgetAlertState.warning:
        return '💡';
      case BudgetAlertState.critical:
        return '⚠️';
      case BudgetAlertState.exceeded:
        return '🚨';
    }
  }
}

class Budget {
  final String id;
  final String categoryId;
  final String categoryName;
  final double limitAmount;
  final double spentAmount;
  final String period; // 'monthly', 'weekly'
  final int month;
  final int year;
  final bool isOverall;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    this.spentAmount = 0.0,
    this.period = 'monthly',
    required this.month,
    required this.year,
    this.isOverall = false,
  });

  double get percentUsed => limitAmount > 0 ? (spentAmount / limitAmount) * 100 : 0.0;
  bool get isExceeded => spentAmount > limitAmount;

  double get remaining => (limitAmount - spentAmount).clamp(0.0, double.infinity);

  int get totalDaysInMonth => DateTime(year, month + 1, 0).day;

  int get elapsedDays {
    final now = DateTime.now();
    if (now.year == year && now.month == month) {
      return now.day > 0 ? now.day : 1;
    } else if (DateTime(year, month).isBefore(DateTime(now.year, now.month))) {
      return totalDaysInMonth;
    } else {
      return 1;
    }
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (period == 'weekly') {
      final daysUntilEndOfWeek = 7 - now.weekday;
      return daysUntilEndOfWeek > 0 ? daysUntilEndOfWeek : 1;
    }
    // Monthly
    final remainingDays = totalDaysInMonth - now.day + 1;
    return remainingDays > 0 ? remainingDays : 1;
  }

  /// Initial planned daily allowance
  double get plannedDailySpending => totalDaysInMonth > 0 ? (limitAmount / totalDaysInMonth) : 0.0;

  /// Current burn rate (actual spending per elapsed day)
  double get burnRate => spentAmount / elapsedDays;

  /// Whether current pace will exceed budget before month ends
  bool get isBurningTooFast => burnRate > plannedDailySpending;

  /// Recommended daily spending for remaining days to stay within budget
  double get recommendedDailySpending {
    if (isExceeded) return 0.0;
    final days = daysRemaining;
    return days > 0 ? (remaining / days) : 0.0;
  }

  /// Projected spending at end of month based on current burn rate
  double get projectedSpending => burnRate * totalDaysInMonth;

  /// Unspent surplus or deficit available for monthly rollover
  double get rolloverBalance => limitAmount - spentAmount;

  BudgetAlertState get alertState {
    final pct = percentUsed;
    if (pct >= 100.0) return BudgetAlertState.exceeded;
    if (pct >= 90.0) return BudgetAlertState.critical;
    if (pct >= 70.0) return BudgetAlertState.warning;
    return BudgetAlertState.safe;
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    double? limitAmount,
    double? spentAmount,
    String? period,
    int? month,
    int? year,
    bool? isOverall,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      month: month ?? this.month,
      year: year ?? this.year,
      isOverall: isOverall ?? this.isOverall,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'period': period,
      'month': month,
      'year': year,
      'isOverall': isOverall,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? 'monthly',
      month: json['month'] as int,
      year: json['year'] as int,
      isOverall: json['isOverall'] as bool? ?? false,
    );
  }
}
