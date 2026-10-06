import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/services/ocr_service.dart';

void main() {
  group('ASTRACK Phase 5 — OCR Pipeline Comprehensive Tests', () {
    test('Parse English receipt with items, subtotal, discount, VAT, and grand total', () {
      const receiptText = '''
STARBUCKS COFFEE ROASTERY
Store #4489 Central Park Mall
Date: 2026-10-02 10:15
Cashier: Sarah

1x Caffe Latte        55000
1x Blueberry Muffin   38000
--------------------------------
Subtotal:             93000
Discount Promo:        5000
VAT (10%):             8800
Grand Total:          96800
Payment: Credit Card
''';

      final result = ReceiptParser.parse(receiptText);

      expect(result.merchant, contains('STARBUCKS'));
      expect(result.total, equals(96800.0));
      expect(result.subtotal, equals(93000.0));
      expect(result.discount, equals(5000.0));
      expect(result.tax, equals(8800.0));
      expect(result.paymentMethod, contains('Kredit'));
      expect(result.items.length, equals(2));
      expect(result.confidence, greaterThanOrEqualTo(0.8));
    });

    test('Receipt without total automatically aggregates items, tax, and discount', () {
      const receiptText = '''
WARUNG KOPI LESTARI
2026-10-02

1x Nasi Goreng Spesial 25000
1x Es Teh Manis         5000
Subtotal:              30000
Pajak PB1:              3000
''';

      final result = ReceiptParser.parse(receiptText);
      expect(result.total, equals(33000.0));
    });

    test('Blurry / unreadable input throws ReceiptUnreadableException without guessing', () async {
      expect(
        () => OCRService.scanReceipt(rawText: '   \n  \n'),
        throwsA(isA<ReceiptUnreadableException>()),
      );

      expect(
        () => OCRService.scanReceipt(imagePath: ''),
        throwsA(isA<ReceiptUnreadableException>()),
      );
    });

    test('Multi-item grocery receipt parsed with correct category suggestion', () {
      const receiptText = '''
ALFAMART CIPETE RAYA
Jl. Cipete No. 12
02/10/2026 15:40

1x Susu UHT 1L        19500
2x Roti Gandum        24000
1x Air Mineral 600ml   3500
--------------------------------
Total:                47000
Tunai:                50000
Kembali:               3000
''';

      final result = ReceiptParser.parse(receiptText);
      expect(result.suggestedCategory, equals('Belanja Harian'));
      expect(result.total, equals(47000.0));
      expect(result.items.length, equals(3));
    });
  });
}
