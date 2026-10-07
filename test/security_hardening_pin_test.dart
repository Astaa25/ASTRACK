import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astrack/core/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRACK Security Hardening & PIN Tests (FlutterSecureStorage & PBKDF2 100k)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('PIN hash and salt are stored in FlutterSecureStorage, never in plaintext SharedPreferences', () async {
      final security = SecurityService.instance;
      await security.init();

      await security.setPin('123456');

      final prefs = await SharedPreferences.getInstance();
      // Ensure legacy plaintext and hash keys do NOT exist in unencrypted SharedPreferences
      expect(prefs.containsKey('astrack_user_pin'), isFalse);
      expect(prefs.containsKey('astrack_user_pin_hash'), isFalse);
      expect(prefs.containsKey('astrack_user_pin_salt'), isFalse);

      // Verify stored in FlutterSecureStorage
      final secureHash = await security.secureStorage.read(key: 'astrack_user_pin_hash');
      final secureSalt = await security.secureStorage.read(key: 'astrack_user_pin_salt');
      final secureIters = await security.secureStorage.read(key: 'astrack_pin_iterations');

      expect(secureHash, isNotNull);
      expect(secureHash, isNot('123456'));
      expect(secureHash!.length, 64); // SHA-256 64-hex chars
      expect(secureSalt, isNotNull);
      expect(secureSalt!.length, 32); // 16 bytes = 32 hex chars
      expect(secureIters, '100000');
      expect(security.currentIterations, equals(100000));
      expect(security.lastDerivationLatencyMs, greaterThanOrEqualTo(0));
    });

    test('Verify valid PIN succeeds with isolate execution and resets failed attempts', () async {
      final security = SecurityService.instance;
      await security.init();
      await security.setPin('654321');

      final isMatch = await security.verifyPin('654321');
      expect(isMatch, isTrue);
      expect(security.failedAttempts, 0);
      expect(security.isLockedOut, isFalse);
      expect(security.lastDerivationLatencyMs, greaterThanOrEqualTo(0));
    });

    test('Consecutive wrong attempts trigger cooldown and lockout in secure storage', () async {
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

      // Stored in secure storage
      final failedInStorage = await security.secureStorage.read(key: 'astrack_pin_failed_attempts');
      expect(failedInStorage, '3');

      // Cannot attempt while locked out
      expect(await security.verifyPin('112233'), isFalse);
    });

    test('Removing PIN wipes hash, salt, and lockout state from secure storage completely', () async {
      final security = SecurityService.instance;
      await security.init();
      await security.setPin('998877');

      await security.removePin();
      expect(security.hasPin, isFalse);
      expect(security.isPinEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('astrack_user_pin_hash'), isFalse);

      final secureHash = await security.secureStorage.read(key: 'astrack_user_pin_hash');
      final secureSalt = await security.secureStorage.read(key: 'astrack_user_pin_salt');
      expect(secureHash, isNull);
      expect(secureSalt, isNull);
    });

    test('Keystore decryption failure (post-restore corruption) is caught safely and falls back to unconfigured PIN', () async {
      final security = SecurityService.instance;
      security.setSecureStorageForTesting(const _CorruptedKeystoreSecureStorage());

      // init() catches Keystore corruption without throwing
      await security.init();

      expect(security.hasPin, isFalse);
      expect(security.isPinEnabled, isFalse);
      expect(security.forceReloginNotifier.value, isTrue);

      // verifyPin also catches Keystore read errors gracefully
      final verifyResult = await security.verifyPin('123456');
      expect(verifyResult, isFalse);

      // Trigger safe sign-out cleans state and resets forceReloginNotifier
      await security.triggerSafeSignOut();
      expect(security.forceReloginNotifier.value, isFalse);

      // Reset back to standard mock storage
      security.setSecureStorageForTesting(const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ));
    });
  });
}

class _CorruptedKeystoreSecureStorage implements FlutterSecureStorage {
  const _CorruptedKeystoreSecureStorage();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) {
      return Future<String?>.error(
        Exception('AndroidKeyStore decryption failure: key corrupted or lost after restore'),
      );
    }
    if (invocation.memberName == #write) {
      return Future<void>.error(
        Exception('AndroidKeyStore encryption failure: Keystore unavailable'),
      );
    }
    if (invocation.memberName == #deleteAll) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}
