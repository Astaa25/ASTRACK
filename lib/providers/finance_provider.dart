import 'package:flutter/material.dart';
import '../data/storage/storage_service.dart';
import '../models/user_profile.dart';
import '../models/fund_source.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';
import '../models/financial_health_score.dart';
import '../services/financial_health_service.dart';
import '../services/transaction_service.dart';
import '../services/notification_service.dart';
import '../services/financial_sync_service.dart';
import '../core/utils/import_validator.dart';

class FinanceProvider extends ChangeNotifier {
  final StorageService _storage;

  late UserProfile _profile;
  List<FundSource> _sources = [];
  List<FinancialCategory> _categories = [];
  List<TransactionItem> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savings = [];
  List<RecurringTransaction> _recurring = [];
  final Set<String> _processedIdempotencyKeys = {};

  bool _hideBalance = true;

  FinanceProvider(this._storage) {
    loadAllData();
  }

  UserProfile get profile => _profile;
  List<FundSource> get sources => _sources;
  List<FinancialCategory> get categories => _categories;
  List<FinancialCategory> get activeCategories => _categories.where((c) => !c.isArchived).toList();
  List<FinancialCategory> get archivedCategories => _categories.where((c) => c.isArchived).toList();
  List<TransactionItem> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savings => _savings;
  List<SavingsGoal> get savingsGoals => _savings;
  List<RecurringTransaction> get recurring => _recurring;
  bool get hideBalance => _hideBalance;
  double get safeToSpendDaily => TransactionService.calculateSafeToSpend(sources: _sources, budgets: _budgets);
  FinancialHealthScore get financialHealthScore => FinancialHealthService.calculate(transactions: _transactions, sources: _sources, budgets: _budgets);

  void setBudget(Budget budget) => addBudget(budget);


  void loadAllData() {
    _profile = _storage.loadProfile();
    _sources = _storage.loadSources();
    _categories = _storage.loadCategories();
    _transactions = _storage.loadTransactions();
    _budgets = _storage.loadBudgets();
    _savings = _storage.loadSavings();
    _recurring = _storage.loadRecurring();
    _hideBalance = _storage.getHideBalance();
    _processRecurringSchedule();
    notifyListeners();
  }

  void toggleHideBalance() {
    _hideBalance = !_hideBalance;
    _storage.setHideBalance(_hideBalance);
    notifyListeners();
  }

  void updateProfile(UserProfile newProfile) {
    _profile = newProfile;
    _storage.saveProfile(_profile);
    notifyListeners();
  }

  /// Login user
  bool login({required String email, required String password, String? name, bool isAdmin = false}) {
    final isDesignatedAdmin = email.trim().toLowerCase() == 'astaabrar@gmail.com';
    _profile = _profile.copyWith(
      email: email,
      name: name ?? (email.split('@').first),
      isGuest: false,
      isLoggedIn: true,
      hasCompletedOnboarding: true,
      isAdmin: isAdmin || isDesignatedAdmin,
    );
    _storage.saveProfile(_profile);
    notifyListeners();
    return true;
  }

  /// Register user
  void register({required String name, required String email, required String password}) {
    _profile = _profile.copyWith(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      isGuest: false,
      isLoggedIn: true,
      hasCompletedOnboarding: true,
      hasCompletedSetup: false,
    );
    // Clear demo/sample data for brand new user
    _transactions = [];
    _budgets = [];
    _savings = [];
    _recurring = [];
    _sources = [];
    _storage.saveTransactions(_transactions);
    _storage.saveBudgets(_budgets);
    _storage.saveSavings(_savings);
    _storage.saveRecurring(_recurring);
    _storage.saveSources(_sources);
    _storage.saveProfile(_profile);
    _storage.saveRegisteredAccount(email, password); // Save credentials
    notifyListeners();
  }

  /// Guest Mode (Part 7 §38)
  void loginAsGuest() {
    _profile = _profile.copyWith(
      id: 'usr_guest',
      name: 'Tamu ASTRACK',
      email: 'guest@astrack.local',
      isGuest: true,
      isLoggedIn: true,
      hasCompletedOnboarding: true,
    );
    _storage.saveProfile(_profile);
    notifyListeners();
  }

  /// Guest Conversion (Part 7 §39: Create Account & Keep My Data)
  void convertGuestToAccount({required String name, required String email, required String password}) {
    _profile = _profile.copyWith(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      isGuest: false,
      isLoggedIn: true,
      hasCompletedOnboarding: true,
    );
    _storage.saveProfile(_profile);
    notifyListeners();
  }

  /// Logout user
  void logout() {
    _profile = _profile.copyWith(
      isLoggedIn: false,
    );
    _storage.saveProfile(_profile);
    notifyListeners();
  }

  /// Add a new transaction deterministically
  void addTransaction(TransactionItem transaction) {
    // Idempotency check: block duplicate execution of identical mutation
    if (transaction.idempotencyKey != null && transaction.idempotencyKey!.isNotEmpty) {
      if (_processedIdempotencyKeys.contains(transaction.idempotencyKey)) {
        return;
      }
      _processedIdempotencyKeys.add(transaction.idempotencyKey!);
    }

    final result = TransactionService.addTransaction(
      transaction: transaction,
      currentSources: _sources,
      currentTransactions: _transactions,
      currentBudgets: _budgets,
    );

    _sources = result.updatedSources;
    _transactions = result.updatedTransactions;
    _budgets = result.updatedBudgets;

    _storage.saveSources(_sources);
    _storage.saveTransactions(_transactions);
    _storage.saveBudgets(_budgets);

    // Check budget threshold alerts (Part 28 §139 & Part 35 §157)
    if (transaction.type == TransactionType.expense) {
      for (final b in _budgets.where((bg) => bg.isOverall || bg.categoryId == transaction.categoryId || bg.categoryId == 'all')) {
        NotificationService().checkBudgetWarning(
          budget: b,
          spentAmount: b.spentAmount,
        );
      }
    }

    notifyListeners();

    if (FinancialSyncService().isCloudAvailable) {
      syncWithCloud();
    }
  }

  /// Delete a transaction and reverse all financial consequences
  void deleteTransaction(String transactionId) {
    final result = TransactionService.deleteTransaction(
      transactionId: transactionId,
      currentSources: _sources,
      currentTransactions: _transactions,
      currentBudgets: _budgets,
    );

    _sources = result.updatedSources;
    _transactions = result.updatedTransactions;
    _budgets = result.updatedBudgets;

    _storage.saveSources(_sources);
    _storage.saveTransactions(_transactions);
    _storage.saveBudgets(_budgets);

    notifyListeners();

    if (FinancialSyncService().isCloudAvailable) {
      FinancialSyncService().deleteRemoteTransaction(transactionId);
      syncWithCloud();
    }
  }

  /// Edit existing transaction with automatic recalculation of fund sources and budgets
  void editTransaction(TransactionItem updatedTransaction) {
    final result = TransactionService.editTransaction(
      updatedTransaction: updatedTransaction,
      currentSources: _sources,
      currentTransactions: _transactions,
      currentBudgets: _budgets,
    );

    _sources = result.updatedSources;
    _transactions = result.updatedTransactions;
    _budgets = result.updatedBudgets;

    _storage.saveSources(_sources);
    _storage.saveTransactions(_transactions);
    _storage.saveBudgets(_budgets);

    notifyListeners();

    if (FinancialSyncService().isCloudAvailable) {
      syncWithCloud();
    }
  }

  /// Bidirectional Cloud Synchronization
  Future<SyncResult> syncWithCloud() async {
    final result = await FinancialSyncService().syncAll(
      sources: _sources,
      categories: _categories,
      transactions: _transactions,
      budgets: _budgets,
      savings: _savings,
      recurring: _recurring,
      onRemoteMerged: (mergedS, mergedC, mergedT, mergedB, mergedG, mergedR) {
        _sources = mergedS;
        _categories = mergedC;
        _transactions = mergedT;
        _budgets = mergedB;
        _savings = mergedG;
        _recurring = mergedR;

        _storage.saveSources(_sources);
        _storage.saveCategories(_categories);
        _storage.saveTransactions(_transactions);
        _storage.saveBudgets(_budgets);
        _storage.saveSavings(_savings);
        _storage.saveRecurring(_recurring);
        notifyListeners();
      },
    );
    notifyListeners();
    return result;
  }

  Future<bool> syncAllToGoogleSheets() async {
    return true; // Spreadsheet sync removed
  }

  /// Add a new Category
  void addCategory(FinancialCategory category) {
    _categories = [..._categories, category];
    _storage.saveCategories(_categories);
    notifyListeners();
  }

  /// Update existing Category
  void updateCategory(FinancialCategory category) {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _categories[idx] = category;
      _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  /// Soft-archive Category so historical transactions retain category metadata
  void archiveCategory(String categoryId) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      _categories[idx] = _categories[idx].copyWith(isArchived: true);
      _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  /// Unarchive Category
  void unarchiveCategory(String categoryId) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      _categories[idx] = _categories[idx].copyWith(isArchived: false);
      _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  /// Delete Category (Soft-archives if transactions exist, hard deletes otherwise)
  bool deleteCategory(String categoryId) {
    final isUsed = _transactions.any((t) => t.categoryId == categoryId);
    if (isUsed) {
      // Soft-archive when in use to preserve history & ledger integrity
      archiveCategory(categoryId);
      return true;
    }
    _categories.removeWhere((c) => c.id == categoryId);
    _storage.saveCategories(_categories);
    notifyListeners();
    return true;
  }

  /// Add a new Fund Source
  void addFundSource(FundSource source) {
    _sources = [..._sources, source];
    _storage.saveSources(_sources);
    notifyListeners();
  }

  /// Update existing Fund Source
  void updateFundSource(FundSource source) {
    final idx = _sources.indexWhere((s) => s.id == source.id);
    if (idx != -1) {
      _sources[idx] = source;
      _storage.saveSources(_sources);
      notifyListeners();
    }
  }

  /// Delete Fund Source
  void deleteFundSource(String sourceId) {
    _sources.removeWhere((s) => s.id == sourceId);
    _storage.saveSources(_sources);
    notifyListeners();
  }

  /// Add a new Budget
  void addBudget(Budget budget) {
    // Check if category already has budget this month, replace if so
    final existingIdx = _budgets.indexWhere((b) => b.categoryId == budget.categoryId && b.month == budget.month);
    if (existingIdx != -1) {
      _budgets[existingIdx] = budget;
    } else {
      _budgets = [..._budgets, budget];
    }
    _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  /// Add a new Savings Goal
  void addSavingsGoal(SavingsGoal goal) {
    _savings = [..._savings, goal];
    _storage.saveSavings(_savings);
    notifyListeners();
  }

  /// Delete a Budget
  void deleteBudget(String budgetId) {
    _budgets.removeWhere((b) => b.id == budgetId);
    _storage.saveBudgets(_budgets);
    notifyListeners();
  }

  /// Carry over previous month unspent balances or copy budget targets to the current month
  int rolloverPreviousMonthBudgets({bool carryOverSurplus = false}) {
    final now = DateTime.now();
    int prevMonth = now.month - 1;
    int prevYear = now.year;
    if (prevMonth <= 0) {
      prevMonth = 12;
      prevYear--;
    }

    final prevBudgets = _budgets.where((b) => b.month == prevMonth && b.year == prevYear).toList();
    if (prevBudgets.isEmpty) return 0;

    int rolledOverCount = 0;
    for (final prev in prevBudgets) {
      final existingIdx = _budgets.indexWhere((b) => b.categoryId == prev.categoryId && b.month == now.month && b.year == now.year);
      double newLimit = prev.limitAmount;
      if (carryOverSurplus && prev.rolloverBalance > 0) {
        newLimit += prev.rolloverBalance;
      }

      if (existingIdx != -1) {
        if (carryOverSurplus && prev.rolloverBalance > 0) {
          _budgets[existingIdx] = _budgets[existingIdx].copyWith(limitAmount: _budgets[existingIdx].limitAmount + prev.rolloverBalance);
          rolledOverCount++;
        }
      } else {
        _budgets.add(Budget(
          id: 'bgt_roll_${DateTime.now().millisecondsSinceEpoch}_${prev.categoryId}',
          categoryId: prev.categoryId,
          categoryName: prev.categoryName,
          limitAmount: newLimit,
          spentAmount: 0.0,
          period: prev.period,
          month: now.month,
          year: now.year,
          isOverall: prev.isOverall,
        ));
        rolledOverCount++;
      }
    }

    if (rolledOverCount > 0) {
      _storage.saveBudgets(_budgets);
      notifyListeners();
    }
    return rolledOverCount;
  }

  /// Delete a Savings Goal
  void deleteSavingsGoal(String goalId) {
    _savings.removeWhere((g) => g.id == goalId);
    _storage.saveSavings(_savings);
    notifyListeners();
  }

  /// Update a Savings Goal (e.g. mark complete)
  void updateSavingsGoal(SavingsGoal goal) {
    final idx = _savings.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _savings[idx] = goal;
      _storage.saveSavings(_savings);
      notifyListeners();
    }
  }

  /// Add/transfer money into savings goal
  void depositToSavingsGoal({
    required String savingsGoalId,
    required double amount,
    required String fromSourceId,
  }) {
    final goalIdx = _savings.indexWhere((g) => g.id == savingsGoalId);
    if (goalIdx == -1) return;

    final goal = _savings[goalIdx];
    final fromSource = _sources.firstWhere((s) => s.id == fromSourceId);

    final tx = TransactionItem(
      id: 'tx_sav_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.transfer, // Changed from saving to transfer
      amount: amount,
      description: 'Tabungan: ${goal.name}',
      categoryId: 'cat_transfer', // Changed to transfer category
      categoryName: 'Transfer',
      sourceId: fromSource.id,
      sourceName: fromSource.name,
      targetSourceId: goal.sourceId,
      targetSourceName: goal.sourceName,
      savingsGoalId: goal.id, // Mark as savings deposit
      dateTime: DateTime.now(),
      notes: 'Alokasi target impian ${goal.name}',
    );

    addTransaction(tx);

    // Update goal current amount
    _savings[goalIdx] = goal.copyWith(currentAmount: goal.currentAmount + amount);
    _storage.saveSavings(_savings);
    NotificationService().notifySavingsProgress(_savings[goalIdx]);
    notifyListeners();
  }

  /// Withdraw money from savings goal back to a fund source
  void withdrawFromSavingsGoal({
    required String savingsGoalId,
    required double amount,
    required String toSourceId,
  }) {
    final goalIdx = _savings.indexWhere((g) => g.id == savingsGoalId);
    if (goalIdx == -1) return;

    final goal = _savings[goalIdx];
    if (amount <= 0 || goal.currentAmount < amount) return;

    final toSource = _sources.firstWhere((s) => s.id == toSourceId);

    final tx = TransactionItem(
      id: 'tx_wd_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.transfer,
      amount: amount,
      description: 'Tarik Tabungan: ${goal.name}',
      categoryId: 'cat_transfer',
      categoryName: 'Transfer',
      sourceId: goal.sourceId,
      sourceName: goal.sourceName,
      targetSourceId: toSource.id,
      targetSourceName: toSource.name,
      savingsGoalId: goal.id,
      dateTime: DateTime.now(),
      notes: 'Pencairan tabungan impian ${goal.name}',
    );

    addTransaction(tx);

    _savings[goalIdx] = goal.copyWith(currentAmount: (goal.currentAmount - amount).clamp(0.0, double.infinity));
    _storage.saveSavings(_savings);
    notifyListeners();
  }

  // --- Recurring Transactions Management (Part 34 & 50) ---
  void _processRecurringSchedule() {
    final now = DateTime.now();
    bool hasUpdates = false;

    for (int i = 0; i < _recurring.length; i++) {
      final item = _recurring[i];
      if (!item.isActive) continue;

      DateTime nextDate = item.nextOccurrence;
      while (nextDate.isBefore(now) || (nextDate.year == now.year && nextDate.month == now.month && nextDate.day == now.day)) {
        // Protect against duplicate execution (Part 34 §156)
        final alreadyGenerated = _transactions.any((tx) =>
            tx.recurringId == item.id &&
            tx.dateTime.year == nextDate.year &&
            tx.dateTime.month == nextDate.month &&
            tx.dateTime.day == nextDate.day);

        if (!alreadyGenerated) {
          final tx = item.toTransactionItem(occurrenceDate: nextDate);
          final res = TransactionService.addTransaction(
            transaction: tx,
            currentSources: _sources,
            currentTransactions: _transactions,
            currentBudgets: _budgets,
          );
          _sources = res.updatedSources;
          _transactions = res.updatedTransactions;
          _budgets = res.updatedBudgets;
          hasUpdates = true;
        }

        nextDate = item.calculateNextDate(nextDate);
        if (item.endDate != null && nextDate.isAfter(item.endDate!)) {
          _recurring[i] = item.copyWith(isActive: false, nextOccurrence: nextDate);
          hasUpdates = true;
          break;
        } else {
          _recurring[i] = item.copyWith(nextOccurrence: nextDate);
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates) {
      _storage.saveSources(_sources);
      _storage.saveTransactions(_transactions);
      _storage.saveBudgets(_budgets);
      _storage.saveRecurring(_recurring);
    }
  }

  void addRecurring(RecurringTransaction item) {
    _recurring = [..._recurring, item];
    _storage.saveRecurring(_recurring);
    _processRecurringSchedule();
    notifyListeners();
  }

  void updateRecurring(RecurringTransaction item) {
    final idx = _recurring.indexWhere((r) => r.id == item.id);
    if (idx != -1) {
      _recurring[idx] = item;
      _storage.saveRecurring(_recurring);
      notifyListeners();
    }
  }

  void toggleRecurringActive(String id) {
    final idx = _recurring.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _recurring[idx] = _recurring[idx].copyWith(isActive: !_recurring[idx].isActive);
      _storage.saveRecurring(_recurring);
      notifyListeners();
    }
  }

  void deleteRecurring(String id) {
    _recurring.removeWhere((r) => r.id == id);
    _storage.saveRecurring(_recurring);
    notifyListeners();
  }

  /// Manually trigger and record a recurring transaction now
  void executeRecurringImmediately(String recurringId) {
    final idx = _recurring.indexWhere((r) => r.id == recurringId);
    if (idx == -1) return;

    final item = _recurring[idx];
    final now = DateTime.now();
    final tx = item.toTransactionItem(occurrenceDate: now);

    addTransaction(tx);

    final nextDate = item.calculateNextDate(item.nextOccurrence);
    _recurring[idx] = item.copyWith(nextOccurrence: nextDate);
    _storage.saveRecurring(_recurring);
    notifyListeners();
  }

  // --- CSV Import Integration (Part 31 & 78) ---
  ImportValidationResult validateCsvImport(String fileName, String csvContent) {
    final defaultSource = _sources.isNotEmpty ? _sources.first : FundSource(
      id: 'src_default',
      name: 'Uang Jajan',
      balance: 0.0,
      iconName: 'wallet',
      colorHex: '087F5B',
    );

    return ImportValidator.validateCsvContent(
      fileName: fileName,
      csvContent: csvContent,
      existingTransactions: _transactions,
      defaultSourceId: defaultSource.id,
      defaultSourceName: defaultSource.name,
    );
  }

  int executeImport(List<TransactionItem> transactionsToImport) {
    int imported = 0;
    for (final tx in transactionsToImport) {
      addTransaction(tx);
      imported++;
    }
    return imported;
  }

  // --- Computed Financial Indicators ---
  double get totalBalance => TransactionService.calculateTotalBalance(_sources);

  double get monthlyIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return TransactionService.calculateTotalIncome(_transactions, start: start, end: end);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return TransactionService.calculateTotalExpense(_transactions, start: start, end: end);
  }

  double get netCashFlow => monthlyIncome - monthlyExpense;

  void resetToSampleData() async {
    await _storage.resetToSampleData();
    loadAllData();
  }

  String exportData() => _storage.exportAllDataAsJson();

  Future<bool> restoreData(String json) async {
    final success = await _storage.restoreFromJson(json);
    if (success) {
      loadAllData();
    }
    return success;
  }
}
