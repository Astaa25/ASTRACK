import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/core/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRACK Security Hardening & PIN Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PIN is never stored as plaintext in SharedPreferences', () async {
      final security = SecurityService.instance;
      await security.init();

      await security.setPin('123456');

      final prefs = await SharedPreferences.getInstance();
      // Ensure legacy plaintext key does NOT exist
      expect(prefs.containsKey('astrack_user_pin'), isFalse);
      // Ensure hashed key exists and does not equal raw pin
      expect(prefs.containsKey('astrack_user_pin_hash'), isTrue);
      final storedHash = prefs.getString('astrack_user_pin_hash');
      expect(storedHash, isNotNull);
      expect(storedHash, isNot('123456'));
      expect(storedHash!.length, 64); // SHA-256 hex string length
    });

    test('Verify valid PIN succeeds and resets failed attempts', () async {
      final security = SecurityService.instance;
      await security.init();
      await security.setPin('654321');

      final isMatch = await security.verifyPin('654321');
      expect(isMatch, isTrue);
      expect(security.failedAttempts, 0);
      expect(security.isLockedOut, isFalse);
    });

    test('Consecutive wrong attempts trigger cooldown and lockout', () async {
      final security = SecurityService.instance;
      await security.init();
      await security.setPin('112233');

      // Attempt 1 wrong
      expect(await security.verifyPin('000000'), isFalse);
      expect(security.failedAttempts, 1);
      expect(security.isLockedOut, isFalse);

      // Attempt 2 wrong
      expect(await security.verifyPin('000000'), isFalse);
      expect(security.failedAttempts, 2);

      // Attempt 3 wrong -> Triggers cooldown
      expect(await security.verifyPin('000000'), isFalse);
      expect(security.failedAttempts, 3);
      expect(security.isLockedOut, isTrue);
      expect(security.remainingLockoutSeconds, greaterThan(0));

      // Cannot attempt while locked out
      expect(await security.verifyPin('112233'), isFalse);
    });

    test('Removing PIN wipes hash and reset lock state completely', () async {
      final security = SecurityService.instance;
      await security.init();
      await security.setPin('998877');

      await security.removePin();
      expect(security.hasPin, isFalse);
      expect(security.isPinEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('astrack_user_pin_hash'), isFalse);
    });
  });
}
