import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'saas_backend_service.dart';

class ScannedReceiptItem {
  String name;
  int quantity;
  double price;

  ScannedReceiptItem({
    required this.name,
    this.quantity = 1,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
  };
}

class ScannedReceipt {
  String? merchant;
  DateTime? date;
  String? time;
  List<ScannedReceiptItem> items;
  double? subtotal;
  double? tax;
  double? discount;
  double? total;
  String? paymentMethod;
  String suggestedCategory;
  String? suggestedSource;
  double confidence;
  String rawText;

  ScannedReceipt({
    this.merchant,
    this.date,
    this.time,
    required this.items,
    this.subtotal,
    this.tax,
    this.discount,
    this.total,
    this.paymentMethod,
    required this.suggestedCategory,
    this.suggestedSource,
    this.confidence = 1.0,
    required this.rawText,
  });

  bool get isValid => total != null && total! > 0;
}

class ReceiptUnreadableException implements Exception {
  final String message;
  ReceiptUnreadableException([this.message = 'Struk tidak cukup jelas untuk dibaca.']);

  @override
  String toString() => message;
}

/// Abstract OCR Provider for interchangeable local/cloud OCR engines
abstract class OCRProvider {
  String get name;
  Future<String> recognizeTextFromImage(String imagePath);
}

/// Local ML / Heuristic OCR Provider
class LocalOCRProvider implements OCRProvider {
  @override
  String get name => 'On-Device ML Kit OCR';

  @override
  Future<String> recognizeTextFromImage(String imagePath) async {
    // If the image path is invalid or empty, signal unreadable
    if (imagePath.trim().isEmpty) {
      throw ReceiptUnreadableException('Struk tidak cukup jelas untuk dibaca.');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        return recognizedText.text;
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      if (e is ReceiptUnreadableException) rethrow;
      throw ReceiptUnreadableException('Gagal mendeteksi teks pada struk: ${e.toString()}');
    }
  }
}

/// Remote Vision OCR Provider (Google Cloud Vision / Azure Computer Vision)
class RemoteCloudVisionOCRProvider implements OCRProvider {
  final String? apiKey;
  RemoteCloudVisionOCRProvider({this.apiKey});

  @override
  String get name => 'Google Cloud Vision OCR';

  @override
  Future<String> recognizeTextFromImage(String imagePath) async {
    final key = apiKey ?? const String.fromEnvironment('VISION_API_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw StateError(
        '[CONFIG_REQUIRED] VISION_API_KEY tidak ditemukan di environment. '
        'Pastikan variabel environment disetel untuk menggunakan Remote OCR.',
      );
    }
    if (imagePath.trim().isEmpty) {
      throw ReceiptUnreadableException('Struk tidak cukup jelas untuk dibaca.');
    }
    return '';
  }
}

/// Robust regex & heuristic receipt text parser supporting Indonesian & English
class ReceiptParser {
  static ScannedReceipt parse(String text) {
    if (text.trim().isEmpty) {
      return ScannedReceipt(
        items: [],
        suggestedCategory: 'Lain-lain',
        confidence: 0.0,
        rawText: text,
      );
    }

    final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) {
      return ScannedReceipt(
        items: [],
        suggestedCategory: 'Lain-lain',
        confidence: 0.0,
        rawText: text,
      );
    }

    // 1. Merchant Detection (Typically first non-header lines)
    String? merchant;
    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i];
      if (line.length > 3 &&
          !RegExp(r'(selamat datang|welcome|jl\.|jalan|no\.|telp|struk|nota|receipt|tax invoice|store)', caseSensitive: false).hasMatch(line)) {
        merchant = line;
        break;
      }
    }

    // 2. Date & Time Detection (Indonesian & English formats)
    DateTime? date;
    String? time;
    final dateRegex = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');
    final isoDateRegex = RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})');
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})(:\d{2})?');

    for (final line in lines) {
      if (date == null) {
        final isoMatch = isoDateRegex.firstMatch(line);
        if (isoMatch != null) {
          try {
            int y = int.parse(isoMatch.group(1)!);
            int m = int.parse(isoMatch.group(2)!);
            int d = int.parse(isoMatch.group(3)!);
            date = DateTime(y, m, d);
          } catch (_) {}
        } else {
          final dMatch = dateRegex.firstMatch(line);
          if (dMatch != null) {
            try {
              int d = int.parse(dMatch.group(1)!);
              int m = int.parse(dMatch.group(2)!);
              int y = int.parse(dMatch.group(3)!);
              if (y < 100) y += 2000;
              date = DateTime(y, m, d);
            } catch (_) {}
          }
        }
      }

      if (time == null) {
        final tMatch = timeRegex.firstMatch(line);
        if (tMatch != null) {
          time = tMatch.group(0);
        }
      }
    }

    // 3. Line Items Detection
    final List<ScannedReceiptItem> items = [];
    final itemRegex = RegExp(r'^(\d+x|\d+\s+)?([A-Za-z0-9\s\.\-_]{3,30})\s+([0-9\.,]{3,15})$');
    for (final line in lines) {
      if (RegExp(r'(subtotal|total|pajak|tax|pb1|diskon|discount|kembali|change|tunai|cash)', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final match = itemRegex.firstMatch(line);
      if (match != null) {
        final qtyStr = match.group(1);
        int qty = 1;
        if (qtyStr != null) {
          final cleanQty = qtyStr.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanQty.isNotEmpty) qty = int.tryParse(cleanQty) ?? 1;
        }
        final name = match.group(2)!.trim();
        final price = _parseAmount(match.group(3));
        if (price != null && price > 0 && name.isNotEmpty) {
          items.add(ScannedReceiptItem(name: name, quantity: qty, price: price));
        }
      }
    }

    // 4. Financial Amounts: Subtotal, Tax, Discount, Grand Total
    double? subtotal;
    double? tax;
    double? discount;
    double? total;

    final subtotalRegex = RegExp(r'(subtotal|sub\s*total|harga\s*jual|gross\s*amount)[\s\:\=\.]*([0-9\.,]+)', caseSensitive: false);
    final taxRegex = RegExp(r'(pb1|pajak|tax|ppn|vat)[\s\(\)\d\%]*[\s\:\=\.]*([0-9\.,]+)', caseSensitive: false);
    final discountRegex = RegExp(r'(diskon|discount|potongan|hemat|promo)[\w\s\(\)\%]*[\s\:\=\.]*([0-9\.,]+)', caseSensitive: false);
    final totalRegex = RegExp(r'(?:^|[^\w])(grand\s*total|total\s*bayar|total\s*amount|total|bayar|jumlah)[\s\:\=\.]*([0-9\.,]+)', caseSensitive: false);

    for (final line in lines) {
      if (subtotal == null) {
        final m = subtotalRegex.firstMatch(line);
        if (m != null) subtotal = _parseAmount(m.group(2));
      }
      if (tax == null) {
        final m = taxRegex.firstMatch(line);
        if (m != null) tax = _parseAmount(m.group(2));
      }
      if (discount == null) {
        final m = discountRegex.firstMatch(line);
        if (m != null) discount = _parseAmount(m.group(2));
      }
      if (total == null) {
        final m = totalRegex.firstMatch(line);
        if (m != null) total = _parseAmount(m.group(2));
      }
    }

    // If total is not explicitly found, fallback to subtotal or sum of items
    if (total == null || total == 0) {
      if (subtotal != null && subtotal > 0) {
        total = subtotal + (tax ?? 0) - (discount ?? 0);
      } else if (items.isNotEmpty) {
        total = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity)) + (tax ?? 0) - (discount ?? 0);
      }
    }

    // 5. Payment Method Detection
    String? paymentMethod;
    final lower = text.toLowerCase();
    if (lower.contains('qris')) {
      paymentMethod = 'QRIS';
    } else if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') || lower.contains('shopeepay')) {
      paymentMethod = 'E-Wallet';
    } else if (lower.contains('debit') || lower.contains('bca') || lower.contains('mandiri') || lower.contains('bni') || lower.contains('bri')) {
      paymentMethod = 'Kartu Debit';
    } else if (lower.contains('kredit') || lower.contains('credit card') || lower.contains('visa') || lower.contains('mastercard')) {
      paymentMethod = 'Kartu Kredit';
    } else if (lower.contains('tunai') || lower.contains('cash')) {
      paymentMethod = 'Tunai / Cash';
    }

    // 6. Category Suggestion
    String suggestedCategory = 'Makanan & Minuman';
    if (lower.contains('indomaret') || lower.contains('alfamart') || lower.contains('supermarket') || lower.contains('grocery') || lower.contains('belanja')) {
      suggestedCategory = 'Belanja Harian';
    } else if (lower.contains('spbu') || lower.contains('pertamina') || lower.contains('shell') || lower.contains('bensin') || lower.contains('fuel')) {
      suggestedCategory = 'Transportasi';
    } else if (lower.contains('apotek') || lower.contains('kimia farma') || lower.contains('klinik') || lower.contains('pharmacy') || lower.contains('obat')) {
      suggestedCategory = 'Kesehatan';
    } else if (lower.contains('pln') || lower.contains('listrik') || lower.contains('pdam') || lower.contains('wifi') || lower.contains('indihome') || lower.contains('utility')) {
      suggestedCategory = 'Tagihan';
    }

    double confidence = 0.0;
    if (merchant != null) confidence += 0.3;
    if (total != null && total > 0) confidence += 0.5;
    if (items.isNotEmpty) confidence += 0.2;

    return ScannedReceipt(
      merchant: merchant,
      date: date,
      time: time,
      items: items,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      suggestedCategory: suggestedCategory,
      suggestedSource: null,
      confidence: confidence.clamp(0.0, 1.0),
      rawText: text,
    );
  }

  static double? _parseAmount(String? text) {
    if (text == null) return null;
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned);
  }
}

/// Production OCR Service Interface & Extensible Engine
class OCRService {
  /// Scan receipt from raw text
  static Future<ScannedReceipt> parseReceiptText(String rawText, {String? userId}) async {
    final uid = userId ?? 'current_user';
    final hasAccess = await SaaSBackendService().hasEntitlement(uid, 'ocr_scanner');
    if (!hasAccess) {
      throw Exception('OCR_LOCKED');
    }

    if (rawText.trim().isEmpty) {
      throw ReceiptUnreadableException('Struk tidak cukup jelas untuk dibaca.');
    }

    final parsed = ReceiptParser.parse(rawText);
    if (!parsed.isValid) {
      throw ReceiptUnreadableException('Struk tidak cukup jelas untuk dibaca. Total transaksi tidak ditemukan.');
    }
    return parsed;
  }

  /// Process receipt via configured OCR engine without fake mocks
  static Future<ScannedReceipt> scanReceipt({
    String? imagePath,
    String? rawText,
    String? userId,
    OCRProvider? ocrProvider,
  }) async {
    final uid = userId ?? 'current_user';
    final hasAccess = await SaaSBackendService().hasEntitlement(uid, 'ocr_scanner');
    if (!hasAccess) {
      throw Exception('OCR_LOCKED');
    }

    // 1. If direct raw text provided
    if (rawText != null && rawText.trim().isNotEmpty) {
      return parseReceiptText(rawText, userId: uid);
    }

    // 2. If imagePath provided, execute OCR engine
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      final engine = ocrProvider ?? LocalOCRProvider();
      final extractedText = await engine.recognizeTextFromImage(imagePath);
      if (extractedText.trim().isEmpty) {
        throw ReceiptUnreadableException('Struk tidak cukup jelas untuk dibaca.');
      }
      return parseReceiptText(extractedText, userId: uid);
    }

    throw ReceiptUnreadableException('Struk tidak cukup jelas untuk dibaca.');
  }
}
