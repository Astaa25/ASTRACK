import 'package:flutter_test/flutter_test.dart';
import 'package:astrack/services/ocr_service.dart';

void main() {
  group('ASTRACK OCR Receipt Parser Tests', () {
    test('Parse valid Indonesian cafe receipt with line items and taxes', () {
      const sampleReceipt = '''
KOPI KENANGAN MANTAN
Mall Grand Indonesia Lt. 3
Telp: 021-998877

02/10/2026 15:45
Kasir: Siti

1x Kopi Kenangan Mantan (L)  24.000
1x Toast Cokelat Keju        18.000
-----------------------------------
Subtotal:                    42.000
PB1 (10%):                    4.200
Total:                       46.200
Pembayaran: QRIS
TERIMA KASIH
''';

      final receipt = ReceiptParser.parse(sampleReceipt);

      expect(receipt.isValid, isTrue);
      expect(receipt.merchant, 'KOPI KENANGAN MANTAN');
      expect(receipt.total, 46200.0);
      expect(receipt.subtotal, 42000.0);
      expect(receipt.tax, 4200.0);
      expect(receipt.paymentMethod, 'QRIS');
      expect(receipt.suggestedCategory, 'Makanan & Minuman');
      expect(receipt.confidence, greaterThanOrEqualTo(0.8));
    });

    test('Parse minimarket grocery receipt', () {
      const minimarketReceipt = '''
INDOMARET POINT
Jl. Gatot Subroto No. 12

01/10/2026 10:15
Beras Premium 5kg            72.000
Minyak Goreng 2L             34.000
Gula Pasir 1kg               17.500
Total:                      123.500
Bayar Tunai:                150.000
Kembali:                     26.500
''';

      final receipt = ReceiptParser.parse(minimarketReceipt);

      expect(receipt.isValid, isTrue);
      expect(receipt.merchant, 'INDOMARET POINT');
      expect(receipt.total, 123500.0);
      expect(receipt.paymentMethod, 'Tunai / Cash');
      expect(receipt.suggestedCategory, 'Belanja Harian');
    });

    test('Return null and confidence 0 for unreadable/empty text without hallucinations', () {
      const blurryOrEmpty = '''
Selamat datang
Silakan datang kembali
Terima kasih
''';

      final receipt = ReceiptParser.parse(blurryOrEmpty);

      expect(receipt.isValid, isFalse);
      expect(receipt.total, isNull);
      expect(receipt.items, isEmpty);
      expect(receipt.confidence, lessThan(0.5));
    });
  });
}
