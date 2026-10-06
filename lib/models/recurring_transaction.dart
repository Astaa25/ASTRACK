import 'transaction_item.dart';
import 'sync_status.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Harian';
      case RecurringFrequency.weekly:
        return 'Mingguan';
      case RecurringFrequency.monthly:
        return 'Bulanan';
      case RecurringFrequency.yearly:
        return 'Tahunan';
    }
  }
}

class RecurringTransaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final String sourceId;
  final String sourceName;
  final String? targetSourceId;
  final String? targetSourceName;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextOccurrence;
  final DateTime? endDate;
  final int scheduledDay; // Original day-of-month target (1-31) to prevent permanent degradation
  final bool isActive;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  RecurringTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.sourceId,
    required this.sourceName,
    this.targetSourceId,
    this.targetSourceName,
    required this.frequency,
    required this.startDate,
    required this.nextOccurrence,
    this.endDate,
    int? scheduledDay,
    this.isActive = true,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.local,
  })  : scheduledDay = scheduledDay ?? startDate.day,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get name => description;

  /// Deterministically calculates the next occurrence with month-end clamping preservation
  DateTime calculateNextDate(DateTime fromDate) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        int newYear = fromDate.year;
        int newMonth = fromDate.month + 1;
        if (newMonth > 12) {
          newYear++;
          newMonth = 1;
        }
        int maxDays = DateTime(newYear, newMonth + 1, 0).day;
        int targetDay = scheduledDay > 0 ? scheduledDay : fromDate.day;
        int newDay = targetDay > maxDays ? maxDays : targetDay;
        return DateTime(newYear, newMonth, newDay, fromDate.hour, fromDate.minute);
      case RecurringFrequency.yearly:
        int newYear = fromDate.year + 1;
        int maxDays = DateTime(newYear, fromDate.month + 1, 0).day;
        int targetDay = scheduledDay > 0 ? scheduledDay : fromDate.day;
        int newDay = targetDay > maxDays ? maxDays : targetDay;
        return DateTime(newYear, fromDate.month, newDay, fromDate.hour, fromDate.minute);
    }
  }

  TransactionItem toTransactionItem({required DateTime occurrenceDate}) {
    return TransactionItem(
      id: 'tx_rec_${id}_${occurrenceDate.millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      description: '$description (Rutin)',
      categoryId: categoryId,
      categoryName: categoryName,
      sourceId: sourceId,
      sourceName: sourceName,
      targetSourceId: targetSourceId,
      targetSourceName: targetSourceName,
      dateTime: occurrenceDate,
      notes: notes.isNotEmpty ? '$notes [Otomatis dari Rutin]' : 'Otomatis dari transaksi rutin: $description',
      recurringId: id,
    );
  }

  RecurringTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    String? sourceId,
    String? sourceName,
    String? targetSourceId,
    String? targetSourceName,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextOccurrence,
    DateTime? endDate,
    int? scheduledDay,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      targetSourceId: targetSourceId ?? this.targetSourceId,
      targetSourceName: targetSourceName ?? this.targetSourceName,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      endDate: endDate ?? this.endDate,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'targetSourceId': targetSourceId,
      'targetSourceName': targetSourceName,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'nextOccurrence': nextOccurrence.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'scheduledDay': scheduledDay,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      targetSourceId: json['targetSourceId'] as String?,
      targetSourceName: json['targetSourceName'] as String?,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      scheduledDay: json['scheduledDay'] as int? ?? (DateTime.parse(json['startDate'] as String).day),
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.local,
      ),
    );
  }
}
