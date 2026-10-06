import 'sync_status.dart';

enum TransactionType { income, expense, transfer, saving }

class TransactionItem {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String categoryId;
  final String categoryName;
  final String sourceId;
  final String sourceName;
  final String? targetSourceId; // For transfer and saving
  final String? targetSourceName;
  final String? savingsGoalId; // For marking transfers as savings deposits
  final DateTime dateTime;
  final String notes;
  final bool isSimulated;
  final String? recurringId;
  final String? idempotencyKey;
  final SyncStatus syncStatus;
  final DateTime updatedAt;

  /// Integer representation in Rupiah (zero floating point roundoff)
  int get amountInt => amount.round();

  TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.sourceId,
    required this.sourceName,
    this.targetSourceId,
    this.targetSourceName,
    this.savingsGoalId,
    required this.dateTime,
    this.notes = '',
    this.isSimulated = false,
    this.recurringId,
    this.idempotencyKey,
    this.syncStatus = SyncStatus.local,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  TransactionItem copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? description,
    String? categoryId,
    String? categoryName,
    String? sourceId,
    String? sourceName,
    String? targetSourceId,
    String? targetSourceName,
    String? savingsGoalId,
    DateTime? dateTime,
    String? notes,
    bool? isSimulated,
    String? recurringId,
    String? idempotencyKey,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      targetSourceId: targetSourceId ?? this.targetSourceId,
      targetSourceName: targetSourceName ?? this.targetSourceName,
      savingsGoalId: savingsGoalId ?? this.savingsGoalId,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      isSimulated: isSimulated ?? this.isSimulated,
      recurringId: recurringId ?? this.recurringId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'targetSourceId': targetSourceId,
      'targetSourceName': targetSourceName,
      'savingsGoalId': savingsGoalId,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'isSimulated': isSimulated,
      'recurringId': recurringId,
      'idempotencyKey': idempotencyKey,
      'syncStatus': syncStatus.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      categoryId: json['categoryId'] as String? ?? 'cat_other',
      categoryName: json['categoryName'] as String? ?? 'Other',
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      targetSourceId: json['targetSourceId'] as String?,
      targetSourceName: json['targetSourceName'] as String?,
      savingsGoalId: json['savingsGoalId'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      notes: json['notes'] as String? ?? '',
      isSimulated: json['isSimulated'] as bool? ?? false,
      recurringId: json['recurringId'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.local,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
