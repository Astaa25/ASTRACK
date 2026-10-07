import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Pbkdf2Params {
  final String pin;
  final String saltHex;
  final int iterations;
  const Pbkdf2Params(this.pin, this.saltHex, this.iterations);
}

String _pbkdf2IsolateWorker(Pbkdf2Params params) {
  return SecurityService.derivePbkdf2Key(
    pin: params.pin,
    saltHex: params.saltHex,
    iterations: params.iterations,
  );
}

class SecurityService with WidgetsBindingObserver {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  static SecurityService get instance => _instance;

  SecurityService._internal();

  // Storage keys in FlutterSecureStorage
  static const String _keyPinHash = 'astrack_user_pin_hash';
  static const String _keyPinSalt = 'astrack_user_pin_salt';
  static const String _keyPinIterations = 'astrack_pin_iterations';
  static const String _keyFailedAttempts = 'astrack_pin_failed_attempts';
  static const String _keyLockoutUntil = 'astrack_pin_lockout_until';
  static const String _keyPinEnabled = 'astrack_pin_enabled';
  static const String _keyBiometricEnabled = 'astrack_biometric_enabled';

  // Legacy SharedPreferences key for plaintext pin migration
  static const String _keyLegacyPin = 'astrack_user_pin';

  // Secret Salt retained strictly for legacy SHA-256 migration
  static const String _legacyPinSalt = 'ASTRACK_SECURE_SALT_v1_98a7c2f5';

  /// Standard PBKDF2 iterations hardened to 100,000 rounds.
  /// Tuning note: On lower-end Android devices, this can be tuned to 50,000 if latency exceeds 1.5s,
  /// but must NEVER be set below 10,000 rounds.
  static const int pbkdf2Iterations = 100000;

  final ValueNotifier<bool> isLockedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> forceReloginNotifier = ValueNotifier<bool>(false);

  FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _cachedPinHash;
  String? _cachedPinSalt;
  int? _cachedPinIterations;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  int _lastDerivationLatencyMs = 0;

  bool get isPinEnabled => _pinEnabled;
  bool get isBiometricEnabled => _biometricEnabled;
  bool get hasPin => _cachedPinHash != null && _cachedPinHash!.isNotEmpty;
  String? get currentSalt => _cachedPinSalt;
  int? get currentIterations => _cachedPinIterations;
  int get failedAttempts => _failedAttempts;
  int get lastDerivationLatencyMs => _lastDerivationLatencyMs;

  @visibleForTesting
  FlutterSecureStorage get secureStorage => _secureStorage;

  @visibleForTesting
  void setSecureStorageForTesting(FlutterSecureStorage storage) {
    _secureStorage = storage;
  }

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Transparent migration from legacy unencrypted SharedPreferences to FlutterSecureStorage
      final legacyPlainPin = prefs.getString(_keyLegacyPin);
      if (legacyPlainPin != null && legacyPlainPin.isNotEmpty) {
        final salt = generateSecureSalt();
        final sw = Stopwatch()..start();
        final hashed = await compute(
          _pbkdf2IsolateWorker,
          Pbkdf2Params(legacyPlainPin, salt, pbkdf2Iterations),
        );
        sw.stop();
        _lastDerivationLatencyMs = sw.elapsedMilliseconds;

        await _secureStorage.write(key: _keyPinHash, value: hashed);
        await _secureStorage.write(key: _keyPinSalt, value: salt);
        await _secureStorage.write(key: _keyPinIterations, value: pbkdf2Iterations.toString());
        await prefs.remove(_keyLegacyPin);
      }

      final legacyPrefsHash = prefs.getString(_keyPinHash);
      if (legacyPrefsHash != null && legacyPrefsHash.isNotEmpty) {
        final legacySalt = prefs.getString(_keyPinSalt);
        final legacyAttempts = prefs.getInt(_keyFailedAttempts) ?? 0;
        final legacyLockout = prefs.getInt(_keyLockoutUntil);

        await _secureStorage.write(key: _keyPinHash, value: legacyPrefsHash);
        if (legacySalt != null) {
          await _secureStorage.write(key: _keyPinSalt, value: legacySalt);
          await _secureStorage.write(key: _keyPinIterations, value: '10000'); // marked as legacy 10k
        }
        await _secureStorage.write(key: _keyFailedAttempts, value: legacyAttempts.toString());
        if (legacyLockout != null) {
          await _secureStorage.write(key: _keyLockoutUntil, value: legacyLockout.toString());
        }

        // Wipe from unencrypted SharedPreferences
        await prefs.remove(_keyPinHash);
        await prefs.remove(_keyPinSalt);
        await prefs.remove(_keyFailedAttempts);
        await prefs.remove(_keyLockoutUntil);
        await prefs.remove(_keyLegacyPin);
      }

      // 2. Load cached credentials from hardware-backed FlutterSecureStorage
      _cachedPinHash = await _secureStorage.read(key: _keyPinHash);
      _cachedPinSalt = await _secureStorage.read(key: _keyPinSalt);
      final iterStr = await _secureStorage.read(key: _keyPinIterations);
      _cachedPinIterations = iterStr != null ? int.tryParse(iterStr) : null;

      final failedStr = await _secureStorage.read(key: _keyFailedAttempts);
      _failedAttempts = failedStr != null ? (int.tryParse(failedStr) ?? 0) : 0;

      final pinEnStr = await _secureStorage.read(key: _keyPinEnabled);
      if (pinEnStr != null) {
        _pinEnabled = pinEnStr == 'true';
      } else {
        _pinEnabled = prefs.getBool(_keyPinEnabled) ?? false;
        if (_pinEnabled) {
          await _secureStorage.write(key: _keyPinEnabled, value: 'true');
        }
      }

      final bioEnStr = await _secureStorage.read(key: _keyBiometricEnabled);
      if (bioEnStr != null) {
        _biometricEnabled = bioEnStr == 'true';
      } else {
        _biometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
      }

      final lockoutStr = await _secureStorage.read(key: _keyLockoutUntil);
      if (lockoutStr != null) {
        final lockoutMs = int.tryParse(lockoutStr);
        if (lockoutMs != null) {
          _lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutMs);
          if (DateTime.now().isAfter(_lockoutUntil!)) {
            _lockoutUntil = null;
            await _secureStorage.delete(key: _keyLockoutUntil);
          }
        }
      }

      if (_pinEnabled && hasPin) {
        isLockedNotifier.value = true;
      }
    } catch (e) {
      // Keystore corruption or decryption failure after OS backup restore
      debugPrint('SecurityService: Keystore read/decryption error encountered during init: $e');
      _cachedPinHash = null;
      _cachedPinSalt = null;
      _cachedPinIterations = null;
      _pinEnabled = false;
      _biometricEnabled = false;
      _failedAttempts = 0;
      _lockoutUntil = null;
      isLockedNotifier.value = false;
      forceReloginNotifier.value = true;
    }

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      lockApp();
    }
  }

  /// Generate a cryptographically secure random hex salt
  static String generateSecureSalt([int length = 16]) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return _bytesToHex(bytes);
  }

  /// Derive key using PBKDF2-HMAC-SHA256
  static String derivePbkdf2Key({
    required String pin,
    required String saltHex,
    int iterations = pbkdf2Iterations,
  }) {
    final passwordBytes = utf8.encode(pin);
    final saltBytes = _hexToBytes(saltHex);
    final hmac = Hmac(sha256, passwordBytes);

    // Initial block U_1 = PRF(password, salt || 0x00000001)
    final blockInput = <int>[...saltBytes, 0, 0, 0, 1];
    List<int> u = hmac.convert(blockInput).bytes;
    final result = List<int>.from(u);

    // Iterations 2 to c: U_k = PRF(password, U_{k-1}), result ^= U_k
    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < 32; j++) {
        result[j] ^= u[j];
      }
    }

    return _bytesToHex(result);
  }

  static String _hashLegacyPin(String pin) {
    final bytes = utf8.encode('$pin:$_legacyPinSalt');
    return sha256.convert(bytes).toString();
  }

  /// Timing-attack resistant constant-time string comparison
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Sets a new 6-digit PIN securely using PBKDF2 with >= 100,000 iterations in an isolate
  Future<bool> setPin(String pin) async {
    if (pin.length != 6) return false;

    final salt = generateSecureSalt();
    final sw = Stopwatch()..start();
    final hash = await compute(
      _pbkdf2IsolateWorker,
      Pbkdf2Params(pin, salt, pbkdf2Iterations),
    );
    sw.stop();
    _lastDerivationLatencyMs = sw.elapsedMilliseconds;
    debugPrint('PBKDF2 ($pbkdf2Iterations iter) execution latency: ${_lastDerivationLatencyMs}ms');

    await _secureStorage.write(key: _keyPinHash, value: hash);
    await _secureStorage.write(key: _keyPinSalt, value: salt);
    await _secureStorage.write(key: _keyPinIterations, value: pbkdf2Iterations.toString());
    await _secureStorage.write(key: _keyPinEnabled, value: 'true');
    await _secureStorage.write(key: _keyFailedAttempts, value: '0');
    await _secureStorage.delete(key: _keyLockoutUntil);

    // Ensure plaintext and unencrypted keys are wiped from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLegacyPin);
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keyPinSalt);
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);

    _cachedPinHash = hash;
    _cachedPinSalt = salt;
    _cachedPinIterations = pbkdf2Iterations;
    _pinEnabled = true;
    _failedAttempts = 0;
    _lockoutUntil = null;

    return true;
  }

  /// Verifies PIN against stored hash with automatic migration to 100,000 iterations
  Future<bool> verifyPin(String inputPin) async {
    if (isLockedOut) {
      return false;
    }

    try {
      _cachedPinHash ??= await _secureStorage.read(key: _keyPinHash);
      _cachedPinSalt ??= await _secureStorage.read(key: _keyPinSalt);
      final iterStr = await _secureStorage.read(key: _keyPinIterations);
      _cachedPinIterations ??= iterStr != null ? int.tryParse(iterStr) : null;
    } catch (e) {
      debugPrint('SecurityService: Keystore read error during verifyPin: $e');
      _cachedPinHash = null;
      return false;
    }

    if (_cachedPinHash == null) return false;

    bool isValid = false;

    if (_cachedPinSalt != null) {
      final iters = _cachedPinIterations ?? 10000;
      final sw = Stopwatch()..start();
      final calculated = await compute(
        _pbkdf2IsolateWorker,
        Pbkdf2Params(inputPin, _cachedPinSalt!, iters),
      );
      sw.stop();
      _lastDerivationLatencyMs = sw.elapsedMilliseconds;

      isValid = _constantTimeEquals(_cachedPinHash!, calculated);

      // Transparent upgrade to >= 100,000 iterations if verified with older round count
      if (isValid && iters < pbkdf2Iterations) {
        final newSalt = generateSecureSalt();
        final upSw = Stopwatch()..start();
        final newHash = await compute(
          _pbkdf2IsolateWorker,
          Pbkdf2Params(inputPin, newSalt, pbkdf2Iterations),
        );
        upSw.stop();
        _lastDerivationLatencyMs = upSw.elapsedMilliseconds;

        await _secureStorage.write(key: _keyPinHash, value: newHash);
        await _secureStorage.write(key: _keyPinSalt, value: newSalt);
        await _secureStorage.write(key: _keyPinIterations, value: pbkdf2Iterations.toString());
        _cachedPinHash = newHash;
        _cachedPinSalt = newSalt;
        _cachedPinIterations = pbkdf2Iterations;
        debugPrint('Seamlessly upgraded PIN hash from $iters to $pbkdf2Iterations PBKDF2 iterations in ${_lastDerivationLatencyMs}ms');
      }
    } else {
      // Legacy V1 SHA-256 verification + transparent upgrade
      final legacyCalculated = _hashLegacyPin(inputPin);
      isValid = _constantTimeEquals(_cachedPinHash!, legacyCalculated);
      if (isValid) {
        final newSalt = generateSecureSalt();
        final upSw = Stopwatch()..start();
        final newHash = await compute(
          _pbkdf2IsolateWorker,
          Pbkdf2Params(inputPin, newSalt, pbkdf2Iterations),
        );
        upSw.stop();
        _lastDerivationLatencyMs = upSw.elapsedMilliseconds;

        await _secureStorage.write(key: _keyPinHash, value: newHash);
        await _secureStorage.write(key: _keyPinSalt, value: newSalt);
        await _secureStorage.write(key: _keyPinIterations, value: pbkdf2Iterations.toString());
        _cachedPinHash = newHash;
        _cachedPinSalt = newSalt;
        _cachedPinIterations = pbkdf2Iterations;
      }
    }

    if (isValid) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      await _secureStorage.write(key: _keyFailedAttempts, value: '0');
      await _secureStorage.delete(key: _keyLockoutUntil);
      isLockedNotifier.value = false;
      return true;
    } else {
      _failedAttempts++;
      await _secureStorage.write(key: _keyFailedAttempts, value: _failedAttempts.toString());

      if (_failedAttempts >= 5) {
        // Lockout for 5 minutes (300 seconds)
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
        await _secureStorage.write(
          key: _keyLockoutUntil,
          value: _lockoutUntil!.millisecondsSinceEpoch.toString(),
        );
      } else if (_failedAttempts >= 3) {
        // Cooldown for 30 seconds
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        await _secureStorage.write(
          key: _keyLockoutUntil,
          value: _lockoutUntil!.millisecondsSinceEpoch.toString(),
        );
      }

      return false;
    }
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: _keyPinHash);
    await _secureStorage.delete(key: _keyPinSalt);
    await _secureStorage.delete(key: _keyPinIterations);
    await _secureStorage.delete(key: _keyFailedAttempts);
    await _secureStorage.delete(key: _keyLockoutUntil);
    await _secureStorage.delete(key: _keyPinEnabled);
    await _secureStorage.delete(key: _keyBiometricEnabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keyPinSalt);
    await prefs.remove(_keyLegacyPin);
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);
    await prefs.setBool(_keyPinEnabled, false);
    await prefs.setBool(_keyBiometricEnabled, false);

    _cachedPinHash = null;
    _cachedPinSalt = null;
    _cachedPinIterations = null;
    _pinEnabled = false;
    _biometricEnabled = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    isLockedNotifier.value = false;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: enabled.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    _biometricEnabled = enabled;
  }

  Future<void> setPinEnabled(bool enabled) async {
    await _secureStorage.write(key: _keyPinEnabled, value: enabled.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPinEnabled, enabled);
    _pinEnabled = enabled;
  }

  void lockApp() {
    if (_pinEnabled && hasPin) {
      isLockedNotifier.value = true;
    }
  }

  void unlockApp() {
    isLockedNotifier.value = false;
  }

  Future<void> resetLockout() async {
    _failedAttempts = 0;
    _lockoutUntil = null;
    await _secureStorage.write(key: _keyFailedAttempts, value: '0');
    await _secureStorage.delete(key: _keyLockoutUntil);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);
  }

  /// Gracefully signs out user and cleans up state when Keystore desynchronization or corruption occurs
  Future<void> triggerSafeSignOut() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('SecurityService: Failed to deleteAll on secure storage: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPinEnabled, false);
      await prefs.setBool(_keyBiometricEnabled, false);
      await prefs.remove(_keyLegacyPin);
      await prefs.remove(_keyPinHash);
      await prefs.remove(_keyPinSalt);
    } catch (_) {}

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('SecurityService: Supabase signOut ignored during keystore fallback: $e');
    }

    _cachedPinHash = null;
    _cachedPinSalt = null;
    _cachedPinIterations = null;
    _pinEnabled = false;
    _biometricEnabled = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    isLockedNotifier.value = false;
    forceReloginNotifier.value = false;
  }

  @visibleForTesting
  void clearCooldownForTesting() {
    _lockoutUntil = null;
  }
}
