import '../../models/fund_source.dart';
import '../../models/category.dart';
import '../../models/transaction_item.dart';
import '../../models/budget.dart';
import '../../models/savings_goal.dart';

class SampleData {
  static List<FundSource> get initialSources => [
    FundSource(
      id: 'src_uang_jajan',
      name: 'Uang Jajan',
      balance: 455000.0, // After Coffee (15k) and Fuel (30k)
      iconName: 'wallet',
      colorHex: '16A34A',
      description: 'Pengeluaran harian dan makan',
      isDefault: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    FundSource(
      id: 'src_tabungan',
      name: 'Tabungan',
      balance: 2200000.0, // 2M initial + 200k transfer
      iconName: 'piggy_bank',
      colorHex: '0D9488',
      description: 'Tabungan masa depan & darurat',
      isDefault: false,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    FundSource(
      id: 'src_bca',
      name: 'Bank BCA',
      balance: 3500000.0,
      iconName: 'credit_card',
      colorHex: '3B82F6',
      description: 'Rekening utama payroll & transfer',
      isDefault: false,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    FundSource(
      id: 'src_gopay',
      name: 'E-Wallet GoPay',
      balance: 350000.0,
      iconName: 'smartphone',
      colorHex: '06B6D4',
      description: 'Dompet digital untuk ojol & jajan',
      isDefault: false,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  static List<FinancialCategory> get initialCategories => [
    FinancialCategory(id: 'cat_food', name: 'Food & Beverage', iconName: 'utensils', colorHex: 'EF4444', type: CategoryType.expense),
    FinancialCategory(id: 'cat_coffee', name: 'Coffee', iconName: 'coffee', colorHex: 'F59E0B', type: CategoryType.expense),
    FinancialCategory(id: 'cat_transport', name: 'Transportation', iconName: 'car', colorHex: '3B82F6', type: CategoryType.expense),
    FinancialCategory(id: 'cat_shopping', name: 'Shopping', iconName: 'shopping_bag', colorHex: 'EC4899', type: CategoryType.expense),
    FinancialCategory(id: 'cat_bills', name: 'Bills & Utilities', iconName: 'receipt', colorHex: '8B5CF6', type: CategoryType.expense),
    FinancialCategory(id: 'cat_entertainment', name: 'Entertainment', iconName: 'film', colorHex: '6366F1', type: CategoryType.expense),
    FinancialCategory(id: 'cat_salary', name: 'Salary & Freelance', iconName: 'briefcase', colorHex: '16A34A', type: CategoryType.income),
    FinancialCategory(id: 'cat_gift', name: 'Uang dari Orang Tua', iconName: 'gift', colorHex: '10B981', type: CategoryType.income),
    FinancialCategory(id: 'cat_other', name: 'Others', iconName: 'more_horizontal', colorHex: '64748B', type: CategoryType.expense),
  ];

  static List<TransactionItem> get initialTransactions {
    final now = DateTime.now();
    return [
      TransactionItem(
        id: 'tx_01',
        type: TransactionType.expense,
        amount: 15000.0,
        description: 'Coffee',
        categoryId: 'cat_coffee',
        categoryName: 'Coffee',
        sourceId: 'src_uang_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(now.year, now.month, now.day, 8, 30),
        notes: 'Kopi susu gula aren pagi',
      ),
      TransactionItem(
        id: 'tx_02',
        type: TransactionType.expense,
        amount: 30000.0,
        description: 'Fuel',
        categoryId: 'cat_transport',
        categoryName: 'Transportation',
        sourceId: 'src_uang_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(now.year, now.month, now.day, 10, 15),
        notes: 'Bensin Pertamax motor',
      ),
      TransactionItem(
        id: 'tx_03',
        type: TransactionType.transfer,
        amount: 200000.0,
        description: 'Transfer ke Tabungan',
        categoryId: 'cat_other',
        categoryName: 'Transfer',
        sourceId: 'src_uang_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: now.subtract(const Duration(days: 1, hours: 2)),
        notes: 'Menyisihkan uang saku untuk tabungan',
      ),
      TransactionItem(
        id: 'tx_04',
        type: TransactionType.expense,
        amount: 25000.0,
        description: 'Makan Siang Nasi Padang',
        categoryId: 'cat_food',
        categoryName: 'Food & Beverage',
        sourceId: 'src_uang_jajan',
        sourceName: 'Uang Jajan',
        dateTime: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      TransactionItem(
        id: 'tx_05',
        type: TransactionType.income,
        amount: 1500000.0,
        description: 'Freelance Project Mobile App',
        categoryId: 'cat_salary',
        categoryName: 'Salary & Freelance',
        sourceId: 'src_bca',
        sourceName: 'Bank BCA',
        dateTime: now.subtract(const Duration(days: 3)),
        notes: 'Pembayaran termin 1 klien',
      ),
      TransactionItem(
        id: 'tx_06',
        type: TransactionType.income,
        amount: 500000.0,
        description: 'Menerima Uang dari Orang Tua',
        categoryId: 'cat_gift',
        categoryName: 'Uang dari Orang Tua',
        sourceId: 'src_uang_jajan',
        sourceName: 'Uang Jajan',
        dateTime: now.subtract(const Duration(days: 5)),
        notes: 'Kiriman bulanan',
      ),
    ];
  }

  static List<Budget> get initialBudgets {
    final now = DateTime.now();
    return [
      Budget(
        id: 'bgt_01',
        categoryId: 'cat_food',
        categoryName: 'Food & Beverage',
        limitAmount: 600000.0,
        spentAmount: 430000.0,
        month: now.month,
        year: now.year,
      ),
      Budget(
        id: 'bgt_02',
        categoryId: 'cat_transport',
        categoryName: 'Transportation',
        limitAmount: 300000.0,
        spentAmount: 180000.0,
        month: now.month,
        year: now.year,
      ),
      Budget(
        id: 'bgt_03',
        categoryId: 'cat_coffee',
        categoryName: 'Coffee',
        limitAmount: 200000.0,
        spentAmount: 145000.0,
        month: now.month,
        year: now.year,
      ),
    ];
  }

  static List<SavingsGoal> get initialSavingsGoals => [
    SavingsGoal(
      id: 'svg_01',
      name: 'Emergency Fund',
      targetAmount: 3000000.0,
      currentAmount: 1200000.0,
      sourceId: 'src_tabungan',
      sourceName: 'Tabungan',
      deadline: DateTime.now().add(const Duration(days: 120)),
      iconName: 'shield',
      colorHex: '0D9488',
    ),
    SavingsGoal(
      id: 'svg_02',
      name: 'New Laptop Fund',
      targetAmount: 12000000.0,
      currentAmount: 4500000.0,
      sourceId: 'src_bca',
      sourceName: 'Bank BCA',
      deadline: DateTime.now().add(const Duration(days: 240)),
      iconName: 'laptop',
      colorHex: '3B82F6',
    ),
  ];
}
