enum SavingsGoalStatus {
  completed,
  onTrack,
  behind;

  String get label {
    switch (this) {
      case SavingsGoalStatus.completed:
        return 'Tercapai 🎉';
      case SavingsGoalStatus.onTrack:
        return 'Sesuai Target (On Track)';
      case SavingsGoalStatus.behind:
        return 'Perlu Dikejar (Behind)';
    }
  }
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String sourceId;
  final String sourceName;
  final DateTime? deadline;
  final String iconName;
  final String colorHex;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.sourceId,
    required this.sourceName,
    this.deadline,
    this.iconName = 'savings',
    this.colorHex = '0D9488',
  });

  double get progressRatio => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progressRatio * 100).round();
  bool get isCompleted => currentAmount >= targetAmount;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  int? get daysRemaining {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get remainingMonths {
    final days = daysRemaining;
    if (days == null || days <= 0) return 1;
    return (days / 30.0).ceil();
  }

  double get recommendedDailySaving {
    if (isCompleted || remainingAmount <= 0) return 0.0;
    final days = daysRemaining;
    if (days == null || days <= 0) return remainingAmount;
    return remainingAmount / days;
  }

  double get recommendedWeeklySaving => recommendedDailySaving * 7;
  double get recommendedMonthlySaving {
    if (isCompleted || remainingAmount <= 0) return 0.0;
    final months = remainingMonths;
    return months > 0 ? (remainingAmount / months) : remainingAmount;
  }

  bool get milestone25 => currentAmount >= targetAmount * 0.25;
  bool get milestone50 => currentAmount >= targetAmount * 0.50;
  bool get milestone75 => currentAmount >= targetAmount * 0.75;
  bool get milestone100 => isCompleted;

  int get highestMilestone {
    if (milestone100) return 100;
    if (milestone75) return 75;
    if (milestone50) return 50;
    if (milestone25) return 25;
    return 0;
  }

  SavingsGoalStatus get status {
    if (isCompleted) return SavingsGoalStatus.completed;
    if (deadline == null) return SavingsGoalStatus.onTrack;
    final days = daysRemaining ?? 0;
    if (days == 0 && !isCompleted) return SavingsGoalStatus.behind;

    // Behind if days remaining is short but progress is far behind
    if (days < 30 && progressPercent < 50) return SavingsGoalStatus.behind;
    if (days < 60 && progressPercent < 25) return SavingsGoalStatus.behind;

    return SavingsGoalStatus.onTrack;
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? sourceId,
    String? sourceName,
    DateTime? deadline,
    String? iconName,
    String? colorHex,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      deadline: deadline ?? this.deadline,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'deadline': deadline?.toIso8601String(),
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      iconName: json['iconName'] as String? ?? 'savings',
      colorHex: json['colorHex'] as String? ?? '0D9488',
    );
  }
}
