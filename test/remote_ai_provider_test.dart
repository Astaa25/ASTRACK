import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/services/ai/ai_provider.dart';
import 'package:astrack/services/ai/ai_models.dart';
import 'package:astrack/models/fund_source.dart';
import 'package:astrack/models/category.dart';
import 'package:astrack/models/transaction_item.dart';

void main() {
  group('ASTRACK Phase 5 — AI Provider & Ambiguity Detection Tests', () {
    final sources = [
      FundSource(id: 's1', name: 'Dompet Utama', balance: 500000),
      FundSource(id: 's2', name: 'Rekening Bank', balance: 2500000),
    ];
    final categories = [
      FinancialCategory(id: 'c1', name: 'Makanan & Minuman', iconName: 'food', colorHex: 'FF5722', type: CategoryType.expense),
      FinancialCategory(id: 'c2', name: 'Gaji', iconName: 'work', colorHex: '4CAF50', type: CategoryType.income),
    ];
    final context = AIContext(availableSources: sources, availableCategories: categories, existingTransactions: []);

    test('Ambiguous amount triggers medium confidence and warning prompt', () async {
      final provider = LocalRuleAIProvider();
      final response = await provider.processInput(
        rawInput: 'Tadi makan siang sekitar 35 ribu dari Dompet Utama',
        context: context,
      );

      expect(response.confidenceLevel, equals('medium'));
      expect(response.text, contains('diperkirakan sekitar'));
      expect(response.draftTransaction, isNotNull);
      expect(response.draftTransaction!.amount, equals(35000.0));
      expect(response.draftTransaction!.sourceName, equals('Dompet Utama'));
    });

    test('Missing source of funds triggers clarification question and does not guess', () async {
      final provider = LocalRuleAIProvider();
      final response = await provider.processInput(
        rawInput: 'Beli bensin motor 20 ribu',
        context: context,
      );

      expect(response.clarificationOptions, isNotNull);
      expect(response.clarificationOptions, contains('Dompet Utama'));
      expect(response.text, contains('Mau dibayar/dicatat dari sumber dana mana?'));
      expect(response.draftTransaction?.sourceId, isEmpty);
    });

    test('RemoteAIProvider falls back gracefully to LocalRuleAIProvider when key is missing or offline', () async {
      final remoteProvider = RemoteAIProvider(apiKey: '');
      final response = await remoteProvider.processInput(
        rawInput: 'Dapat bonus kerja 500 ribu ke Rekening Bank',
        context: context,
      );

      expect(response.draftTransaction, isNotNull);
      expect(response.draftTransaction!.type, equals(TransactionType.income));
      expect(response.draftTransaction!.amount, equals(500000.0));
      expect(response.draftTransaction!.sourceName, equals('Rekening Bank'));
    });
  });
}
