import 'transaction_item.dart';
import 'budget.dart';
import 'savings_goal.dart';

class AIMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final TransactionItem? draftTransaction;
  final Budget? draftBudget;
  final SavingsGoal? draftSavingsGoal;
  final List<String>? clarificationOptions;
  final bool isSimulation;
  final bool isDuplicateWarning;
  final bool isConfirmed;
  final String? confidenceLevel; // 'high', 'medium', 'low'
  final bool hasExplicitTime;

  AIMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.draftTransaction,
    this.draftBudget,
    this.draftSavingsGoal,
    this.clarificationOptions,
    this.isSimulation = false,
    this.isDuplicateWarning = false,
    this.isConfirmed = false,
    this.confidenceLevel,
    this.hasExplicitTime = true,
  }) : timestamp = timestamp ?? DateTime.now();

  AIMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    TransactionItem? draftTransaction,
    Budget? draftBudget,
    SavingsGoal? draftSavingsGoal,
    List<String>? clarificationOptions,
    bool? isSimulation,
    bool? isDuplicateWarning,
    bool? isConfirmed,
    String? confidenceLevel,
    bool? hasExplicitTime,
  }) {
    return AIMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      draftTransaction: draftTransaction ?? this.draftTransaction,
      draftBudget: draftBudget ?? this.draftBudget,
      draftSavingsGoal: draftSavingsGoal ?? this.draftSavingsGoal,
      clarificationOptions: clarificationOptions ?? this.clarificationOptions,
      isSimulation: isSimulation ?? this.isSimulation,
      isDuplicateWarning: isDuplicateWarning ?? this.isDuplicateWarning,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      hasExplicitTime: hasExplicitTime ?? this.hasExplicitTime,
    );
  }
}
