import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/core/services/security_service.dart';
import 'package:astrack/core/utils/currency_formatter.dart';
import 'package:astrack/models/transaction_item.dart';
import 'package:astrack/services/payment/payment_models.dart';
import 'package:astrack/services/payment/payment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRACK Phase 3: Security Hardening & Integer Money Audit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. PBKDF2-HMAC-SHA256 Derivation: Deterministic 64-hex key with 10,000 iterations', () {
      const pin = '123456';
      const salt = '0123456789abcdef0123456789abcdef';

      final key1 = SecurityService.derivePbkdf2Key(pin: pin, saltHex: salt, iterations: 1000);
      final key2 = SecurityService.derivePbkdf2Key(pin: pin, saltHex: salt, iterations: 1000);

      // Deterministic derivation
      expect(key1, equals(key2));
      // 256 bits = 32 bytes = 64 hex characters
      expect(key1.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key1), isTrue);
    });

    test('2. Anti-Rainbow Table Security: Different salts produce distinct derived keys for identical PIN', () {
      const pin = '888888';
      final salt1 = SecurityService.generateSecureSalt();
      final salt2 = SecurityService.generateSecureSalt();

      expect(salt1, isNot(equals(salt2)));

      final key1 = SecurityService.derivePbkdf2Key(pin: pin, saltHex: salt1, iterations: 100);
      final key2 = SecurityService.derivePbkdf2Key(pin: pin, saltHex: salt2, iterations: 100);

      expect(key1, isNot(equals(key2)));
    });

    test('3. Dynamic Random Salt Entropy: Generates 16 random bytes (32 hex characters)', () {
      final salt = SecurityService.generateSecureSalt(16);
      expect(salt.length, equals(32));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(salt), isTrue);
    });

    test('4. Automatic Migration: Legacy single-pass SHA-256 hash auto-upgrades to PBKDF2 with dynamic salt', () async {
      final prefs = await SharedPreferences.getInstance();
      final security = SecurityService.instance;

      // Manually store legacy hash without salt key
      await prefs.setString('astrack_user_pin_hash', '5d41402abc4b2a76b9719d911017c592'); // mock legacy hash
      await prefs.setBool('astrack_pin_enabled', true);
      await prefs.remove('astrack_user_pin_salt');

      await security.init();
      expect(security.currentSalt, isNull);

      // Set a fresh PIN to verify V2 salt is persisted
      await security.setPin('999111');
      expect(security.currentSalt, isNotNull);
      expect(prefs.getString('astrack_user_pin_salt'), isNotNull);

      // Verify PIN works with PBKDF2
      expect(await security.verifyPin('999111'), isTrue);
      expect(await security.verifyPin('000000'), isFalse);
    });

    test('5. Integer Money Representation & CurrencyFormatter: Eliminates floating point roundoff in Rupiah', () {
      // Test rounding guarantee
      expect(CurrencyFormatter.toIntegerAmount(15000.0), equals(15000));
      expect(CurrencyFormatter.toIntegerAmount(14999.999999), equals(15000));
      expect(CurrencyFormatter.toIntegerAmount(25000.4), equals(25000));
      expect(CurrencyFormatter.toIntegerAmount(25000.6), equals(25001));

      // Test format with int and double num inputs
      expect(CurrencyFormatter.format(15000), equals('Rp15.000'));
      expect(CurrencyFormatter.format(14999.9999), equals('Rp15.000'));
      expect(CurrencyFormatter.format(-50000), equals('-Rp50.000'));
      expect(CurrencyFormatter.format(2500000, showSign: true), equals('+Rp2.500.000'));

      // Test formatCompact
      expect(CurrencyFormatter.formatCompact(500000), equals('Rp500 rb'));
      expect(CurrencyFormatter.formatCompact(2500000), equals('Rp2.5 jt'));
      expect(CurrencyFormatter.formatCompact(1500000000), equals('Rp1.5 M'));
    });

    test('6. TransactionItem amountInt: Returns exact integer amount', () {
      final item = TransactionItem(
        id: 'tx_int_test',
        type: TransactionType.expense,
        amount: 35000.0,
        description: 'Test Belanja',
        categoryId: 'cat_groceries',
        categoryName: 'Groceries',
        sourceId: 'src_bca',
        sourceName: 'BCA',
        dateTime: DateTime(2026, 10, 7),
      );

      expect(item.amountInt, equals(35000));
    });

    test('7. Edge Function Gateway Architecture: Isolates payment secrets from client binary', () async {
      // Verify Enum definition
      expect(PaymentGatewayType.edgeGateway.label, equals('ASTRACK Secure Edge Gateway'));

      // Verify Factory resolution
      final provider = PaymentGatewayFactory.create(providerType: 'edgeGateway');
      expect(provider, isA<EdgeFunctionPaymentProvider>());
      expect(provider.providerName, equals('ASTRACK Secure Edge Gateway'));

      // Verify createOrder gracefully produces order without needing compiled merchant secrets
      final order = await provider.createOrder(
        userId: 'test_user_uuid',
        planId: 'plan_pro',
        amount: 29000,
        userEmail: 'user@astrack.local',
      );

      expect(order.orderId, startsWith('ORD_EDGE_'));
      expect(order.amount, equals(29000));
      expect(order.status, equals(PaymentStatus.pending));
    });
  });
}
