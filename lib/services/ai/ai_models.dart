import '../../models/fund_source.dart';
import '../../models/category.dart';
import '../../models/transaction_item.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';
import '../../models/ai_message.dart';

class TransactionDraft {
  final TransactionType type;
  final double amount;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? sourceId;
  final String? sourceName;
  final String? targetSourceId;
  final String? targetSourceName;
  final String? savingsGoalId;
  final DateTime dateTime;
  final String? notes;
  final double confidence;
  final List<String> missingFields;

  TransactionDraft({
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.sourceId,
    this.sourceName,
    this.targetSourceId,
    this.targetSourceName,
    this.savingsGoalId,
    required this.dateTime,
    this.notes,
    this.confidence = 1.0,
    this.missingFields = const [],
  });

  bool get isComplete => missingFields.isEmpty && sourceId != null;

  TransactionItem toTransactionItem({String? id}) {
    return TransactionItem(
      id: id ?? 'tx_ai_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      sourceId: sourceId ?? 'src_default',
      sourceName: sourceName ?? 'Uang Jajan',
      targetSourceId: targetSourceId,
      targetSourceName: targetSourceName,
      savingsGoalId: savingsGoalId,
      dateTime: dateTime,
      notes: notes ?? 'Dicatat via Asisten AI ASTRACK',
    );
  }
}

class BudgetDraft {
  final String categoryId;
  final String categoryName;
  final double limitAmount;
  final int month;
  final int year;
  final bool isOverall;

  BudgetDraft({
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.month,
    required this.year,
    this.isOverall = false,
  });

  Budget toBudget({String? id}) {
    return Budget(
      id: id ?? 'budget_${isOverall ? "overall" : categoryId}_${year}_$month',
      categoryId: categoryId,
      categoryName: categoryName,
      limitAmount: limitAmount,
      spentAmount: 0.0,
      month: month,
      year: year,
      isOverall: isOverall,
    );
  }
}

class SavingsGoalDraft {
  final String name;
  final double targetAmount;
  final String sourceId;
  final String sourceName;
  final DateTime? deadline;
  final double initialAmount;
  final String? iconName;

  SavingsGoalDraft({
    required this.name,
    required this.targetAmount,
    required this.sourceId,
    required this.sourceName,
    this.deadline,
    this.initialAmount = 0.0,
    this.iconName,
  });

  SavingsGoal toSavingsGoal({String? id}) {
    return SavingsGoal(
      id: id ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      sourceId: sourceId,
      sourceName: sourceName,
      deadline: deadline,
      iconName: iconName ?? 'savings',
    );
  }
}

class AIContext {
  final List<FundSource> availableSources;
  final List<FinancialCategory> availableCategories;
  final List<TransactionItem> existingTransactions;
  final List<Budget> budgets;
  final List<SavingsGoal> savingsGoals;
  final String userId;

  AIContext({
    required this.availableSources,
    required this.availableCategories,
    required this.existingTransactions,
    this.budgets = const [],
    this.savingsGoals = const [],
    this.userId = 'current_user',
  });
}

class AIConversation {
  final List<AIMessage> messages;
  TransactionItem? pendingDraft;

  AIConversation({
    List<AIMessage>? messages,
    this.pendingDraft,
  }) : messages = messages ?? [];

  void addMessage(AIMessage message) {
    messages.add(message);
  }

  void clear() {
    messages.clear();
    pendingDraft = null;
  }
}
