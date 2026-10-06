import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/services/financial_sync_service.dart';
import 'package:astrack/models/fund_source.dart';
import 'package:astrack/models/category.dart';
import 'package:astrack/models/transaction_item.dart';

void main() {
  group('ASTRACK Financial Cloud Sync Tests', () {
    test('Offline mode handles sync gracefully without crashing', () async {
      final syncService = FinancialSyncService();
      expect(syncService.isCloudAvailable, isFalse);

      final result = await syncService.syncAll(
        sources: [
          FundSource(id: 's1', name: 'Dompet Utama', balance: 500000),
        ],
        categories: [
          FinancialCategory(id: 'c1', name: 'Makan', iconName: 'food', colorHex: 'EF4444', type: CategoryType.expense),
        ],
        transactions: [
          TransactionItem(
            id: 't1',
            type: TransactionType.expense,
            amount: 25000,
            description: 'Makan Siang',
            categoryId: 'c1',
            categoryName: 'Makan',
            sourceId: 's1',
            sourceName: 'Dompet Utama',
            dateTime: DateTime.now(),
          ),
        ],
        budgets: [],
        savings: [],
        recurring: [],
        onRemoteMerged: (s, c, t, b, g, r) {},
      );

      expect(result.success, isFalse);
      expect(syncService.statusNotifier.value, SyncEngineStatus.offline);
      expect(result.message.contains('offline'), isTrue);
    });
  });
}
