import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../models/fund_source.dart';
import '../../models/category.dart';
import '../../models/transaction_item.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';
import '../../models/recurring_transaction.dart';
import '../../core/constants/sample_data.dart';

class StorageService {
  static const String _keyProfile = 'astrack_profile';
  static const String _keySources = 'astrack_sources';
  static const String _keyCategories = 'astrack_categories';
  static const String _keyTransactions = 'astrack_transactions';
  static const String _keyBudgets = 'astrack_budgets';
  static const String _keySavings = 'astrack_savings';
  static const String _keyRecurring = 'astrack_recurring';
  static const String _keyThemeMode = 'astrack_theme_mode';
  static const String _keyAccentColor = 'astrack_accent_color';
  static const String _keyTextScale = 'astrack_text_scale';
  static const String _keyUiStyle = 'astrack_ui_style';
  static const String _keyLanguage = 'astrack_language';
  static const String _keyHideBalance = 'astrack_hide_balance';
  static const String _keyRegEmail = 'astrack_reg_email';
  static const String _keyRegPass = 'astrack_reg_pass';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Theme & Preferences ---
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'light';
  Future<void> setThemeMode(String mode) async => await _prefs.setString(_keyThemeMode, mode);

  String getAccentColor() => _prefs.getString(_keyAccentColor) ?? 'emerald';
  Future<void> setAccentColor(String color) async => await _prefs.setString(_keyAccentColor, color);

  String getTextScale() => _prefs.getString(_keyTextScale) ?? 'normal';
  Future<void> setTextScale(String scale) async => await _prefs.setString(_keyTextScale, scale);

  String getUiStyle() => _prefs.getString(_keyUiStyle) ?? 'soft';
  Future<void> setUiStyle(String style) async => await _prefs.setString(_keyUiStyle, style);

  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'id';
  Future<void> setLanguage(String lang) async => await _prefs.setString(_keyLanguage, lang);

  bool getHideBalance() => _prefs.getBool(_keyHideBalance) ?? true;
  Future<void> setHideBalance(bool hide) async => await _prefs.setBool(_keyHideBalance, hide);

  // --- Auth Credentials ---
  String? getRegisteredEmail() => _prefs.getString(_keyRegEmail);
  String? getRegisteredPassword() => _prefs.getString(_keyRegPass);
  Future<void> saveRegisteredAccount(String email, String password) async {
    await _prefs.setString(_keyRegEmail, email);
    await _prefs.setString(_keyRegPass, password);
  }

  // --- Profile ---
  UserProfile loadProfile() {
    final raw = _prefs.getString(_keyProfile);
    if (raw == null) {
      return UserProfile.defaultUser();
    }
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.defaultUser();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  static List<FundSource> get defaultSources => [
    FundSource(
      id: 'src_default_cash',
      name: 'Dompet Utama',
      balance: 0.0,
      iconName: 'wallet',
      colorHex: '10B981',
      description: 'Dompet kas tunai utama',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  // --- Fund Sources ---
  List<FundSource> loadSources() {
    final raw = _prefs.getString(_keySources);
    if (raw == null) {
      final defaults = defaultSources;
      saveSources(defaults);
      return defaults;
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => FundSource.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultSources;
    }
  }

  Future<void> saveSources(List<FundSource> sources) async {
    final raw = jsonEncode(sources.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySources, raw);
  }

  // --- Categories ---
  List<FinancialCategory> loadCategories() {
    final raw = _prefs.getString(_keyCategories);
    if (raw == null) {
      final defaults = SampleData.initialCategories;
      saveCategories(defaults);
      return defaults;
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => FinancialCategory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return SampleData.initialCategories;
    }
  }

  Future<void> saveCategories(List<FinancialCategory> categories) async {
    final raw = jsonEncode(categories.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyCategories, raw);
  }

  // --- Transactions ---
  List<TransactionItem> loadTransactions() {
    final raw = _prefs.getString(_keyTransactions);
    if (raw == null) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionItem> transactions) async {
    final raw = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyTransactions, raw);
  }

  // --- Budgets ---
  List<Budget> loadBudgets() {
    final raw = _prefs.getString(_keyBudgets);
    if (raw == null) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final raw = jsonEncode(budgets.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyBudgets, raw);
  }

  // --- Savings ---
  List<SavingsGoal> loadSavings() {
    final raw = _prefs.getString(_keySavings);
    if (raw == null) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavings(List<SavingsGoal> savings) async {
    final raw = jsonEncode(savings.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySavings, raw);
  }

  // --- Recurring Transactions ---
  List<RecurringTransaction> loadRecurring() {
    final raw = _prefs.getString(_keyRecurring);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecurring(List<RecurringTransaction> recurring) async {
    final raw = jsonEncode(recurring.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyRecurring, raw);
  }

  // --- Backup & Export ---
  String exportAllDataAsJson() {
    final data = {
      'profile': loadProfile().toJson(),
      'sources': loadSources().map((e) => e.toJson()).toList(),
      'categories': loadCategories().map((e) => e.toJson()).toList(),
      'transactions': loadTransactions().map((e) => e.toJson()).toList(),
      'budgets': loadBudgets().map((e) => e.toJson()).toList(),
      'savings': loadSavings().map((e) => e.toJson()).toList(),
      'recurring': loadRecurring().map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> restoreFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data.containsKey('sources')) {
        final list = (data['sources'] as List).map((e) => FundSource.fromJson(e)).toList();
        await saveSources(list);
      }
      if (data.containsKey('transactions')) {
        final list = (data['transactions'] as List).map((e) => TransactionItem.fromJson(e)).toList();
        await saveTransactions(list);
      }
      if (data.containsKey('categories')) {
        final list = (data['categories'] as List).map((e) => FinancialCategory.fromJson(e)).toList();
        await saveCategories(list);
      }
      if (data.containsKey('budgets')) {
        final list = (data['budgets'] as List).map((e) => Budget.fromJson(e)).toList();
        await saveBudgets(list);
      }
      if (data.containsKey('savings')) {
        final list = (data['savings'] as List).map((e) => SavingsGoal.fromJson(e)).toList();
        await saveSavings(list);
      }
      if (data.containsKey('recurring')) {
        final list = (data['recurring'] as List).map((e) => RecurringTransaction.fromJson(e)).toList();
        await saveRecurring(list);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAllFinancialData() async {
    await saveSources(defaultSources);
    await saveTransactions([]);
    await saveBudgets([]);
    await saveSavings([]);
    await saveRecurring([]);
  }

  Future<void> resetToSampleData() async {
    await clearAllFinancialData();
  }
}
