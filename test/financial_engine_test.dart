import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/models/fund_source.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/models/budget.dart';
import 'package:astrack/services/transaction_service.dart';

void main() {
  group('ASTRACK Financial Engine Specification Tests', () {
    test('Part 76 §226: End-to-end Financial Scenario', () {
      // 1. Initial State: Uang Jajan (0) and Tabungan (0)
      List<FundSource> sources = [
        FundSource(id: 'src_jajan', name: 'Uang Jajan', balance: 0.0),
        FundSource(id: 'src_tabungan', name: 'Tabungan', balance: 0.0),
      ];
      List<TransactionItem> transactions = [];
      List<Budget> budgets = [
        Budget(id: 'b_food', categoryId: 'cat_food', categoryName: 'Food', limitAmount: 500000, spentAmount: 0, month: 9, year: 2026),
      ];

      // 2. Add Income Rp1.000.000 to Uang Jajan
      final incTx = TransactionItem(
        id: 'tx_inc_1',
        type: TransactionType.income,
        amount: 1000000.0,
        description: 'Uang Masuk',
        categoryId: 'cat_income',
        categoryName: 'Income',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(2026, 9, 27, 10, 0),
      );
      var res = TransactionService.addTransaction(
        transaction: incTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 1000000.0);

      // 3. Expense Rp20.000
      final expTx = TransactionItem(
        id: 'tx_exp_1',
        type: TransactionType.expense,
        amount: 20000.0,
        description: 'Makan Ayam',
        categoryId: 'cat_food',
        categoryName: 'Food',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        dateTime: DateTime(2026, 9, 27, 12, 0),
      );
      res = TransactionService.addTransaction(
        transaction: expTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 980000.0);
      expect(budgets.firstWhere((b) => b.id == 'b_food').spentAmount, 20000.0);

      // 4. Transfer Rp100.000 to Tabungan (Transfer does not increase net worth)
      final trfTx = TransactionItem(
        id: 'tx_trf_1',
        type: TransactionType.transfer,
        amount: 100000.0,
        description: 'Transfer ke Tabungan',
        categoryId: 'cat_transfer',
        categoryName: 'Transfer',
        sourceId: 'src_jajan',
        sourceName: 'Uang Jajan',
        targetSourceId: 'src_tabungan',
        targetSourceName: 'Tabungan',
        dateTime: DateTime(2026, 9, 27, 14, 0),
      );
      res = TransactionService.addTransaction(
        transaction: trfTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 880000.0);
      expect(sources.firstWhere((s) => s.id == 'src_tabungan').balance, 100000.0);
      expect(TransactionService.calculateTotalBalance(sources), 980000.0); // Net worth unchanged by transfer

      // 5. Edit expense to Rp25.000
      final updatedExpTx = expTx.copyWith(amount: 25000.0);
      res = TransactionService.editTransaction(
        updatedTransaction: updatedExpTx,
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 875000.0);
      expect(budgets.firstWhere((b) => b.id == 'b_food').spentAmount, 25000.0);

      // 6. Delete expense
      res = TransactionService.deleteTransaction(
        transactionId: 'tx_exp_1',
        currentSources: sources,
        currentTransactions: transactions,
        currentBudgets: budgets,
      );
      sources = res.updatedSources;
      transactions = res.updatedTransactions;
      budgets = res.updatedBudgets;

      // Final expected state per Part 76 §226:
      // Uang Jajan = Rp900.000
      // Tabungan = Rp100.000
      expect(sources.firstWhere((s) => s.id == 'src_jajan').balance, 900000.0);
      expect(sources.firstWhere((s) => s.id == 'src_tabungan').balance, 100000.0);
      expect(budgets.firstWhere((b) => b.id == 'b_food').spentAmount, 0.0);
    });
  });
}
