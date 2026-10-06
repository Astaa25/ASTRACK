import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService with WidgetsBindingObserver {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  static SecurityService get instance => _instance;

  SecurityService._internal();

  // Storage keys (Plaintext PIN removed permanently)
  static const String _keyPinHash = 'astrack_user_pin_hash';
  static const String _keyPinSalt = 'astrack_user_pin_salt';
  static const String _keyLegacyPin = 'astrack_user_pin'; // for migration only
  static const String _keyPinEnabled = 'astrack_pin_enabled';
  static const String _keyBiometricEnabled = 'astrack_biometric_enabled';
  static const String _keyFailedAttempts = 'astrack_pin_failed_attempts';
  static const String _keyLockoutUntil = 'astrack_pin_lockout_until';

  // Secret Salt retained strictly for legacy migration
  static const String _legacyPinSalt = 'ASTRACK_SECURE_SALT_v1_98a7c2f5';
  static const int pbkdf2Iterations = 10000;

  final ValueNotifier<bool> isLockedNotifier = ValueNotifier<bool>(false);

  String? _cachedPinHash;
  String? _cachedPinSalt;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get isPinEnabled => _pinEnabled;
  bool get isBiometricEnabled => _biometricEnabled;
  bool get hasPin => _cachedPinHash != null && _cachedPinHash!.isNotEmpty;
  String? get currentSalt => _cachedPinSalt;
  int get failedAttempts => _failedAttempts;

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
    final prefs = await SharedPreferences.getInstance();

    // Secure Migration: Clean up plaintext PIN if it exists
    final legacyPin = prefs.getString(_keyLegacyPin);
    if (legacyPin != null && legacyPin.isNotEmpty) {
      final salt = generateSecureSalt();
      final hashed = derivePbkdf2Key(pin: legacyPin, saltHex: salt);
      await prefs.setString(_keyPinHash, hashed);
      await prefs.setString(_keyPinSalt, salt);
      await prefs.remove(_keyLegacyPin); // Wipe plaintext
    }

    _cachedPinHash = prefs.getString(_keyPinHash);
    _cachedPinSalt = prefs.getString(_keyPinSalt);
    _pinEnabled = prefs.getBool(_keyPinEnabled) ?? false;
    _biometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    _failedAttempts = prefs.getInt(_keyFailedAttempts) ?? 0;

    final lockoutMs = prefs.getInt(_keyLockoutUntil);
    if (lockoutMs != null) {
      _lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutMs);
      if (DateTime.now().isAfter(_lockoutUntil!)) {
        _lockoutUntil = null;
        await prefs.remove(_keyLockoutUntil);
      }
    }

    if (_pinEnabled && hasPin) {
      isLockedNotifier.value = true;
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

  /// Derive key using PBKDF2-HMAC-SHA256 with 10,000 iterations
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

  Future<bool> setPin(String pin) async {
    if (pin.length != 6) return false;
    final prefs = await SharedPreferences.getInstance();

    final salt = generateSecureSalt();
    final hash = derivePbkdf2Key(pin: pin, saltHex: salt);

    await prefs.setString(_keyPinHash, hash);
    await prefs.setString(_keyPinSalt, salt);
    await prefs.setBool(_keyPinEnabled, true);
    await prefs.remove(_keyLegacyPin); // Ensure plaintext is wiped

    _cachedPinHash = hash;
    _cachedPinSalt = salt;
    _pinEnabled = true;
    _failedAttempts = 0;
    await prefs.setInt(_keyFailedAttempts, 0);

    return true;
  }

  Future<bool> verifyPin(String inputPin) async {
    if (isLockedOut) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedPinHash ??= prefs.getString(_keyPinHash);
    _cachedPinSalt ??= prefs.getString(_keyPinSalt);

    if (_cachedPinHash == null) return false;

    bool isValid = false;

    if (_cachedPinSalt != null) {
      // V2 PBKDF2 Verification
      final calculated = derivePbkdf2Key(pin: inputPin, saltHex: _cachedPinSalt!);
      isValid = _constantTimeEquals(_cachedPinHash!, calculated);
    } else {
      // Legacy V1 SHA-256 verification + transparent upgrade
      final legacyCalculated = _hashLegacyPin(inputPin);
      isValid = _constantTimeEquals(_cachedPinHash!, legacyCalculated);
      if (isValid) {
        final newSalt = generateSecureSalt();
        final newHash = derivePbkdf2Key(pin: inputPin, saltHex: newSalt);
        await prefs.setString(_keyPinHash, newHash);
        await prefs.setString(_keyPinSalt, newSalt);
        _cachedPinHash = newHash;
        _cachedPinSalt = newSalt;
      }
    }

    if (isValid) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      await prefs.setInt(_keyFailedAttempts, 0);
      await prefs.remove(_keyLockoutUntil);
      isLockedNotifier.value = false;
      return true;
    } else {
      _failedAttempts++;
      await prefs.setInt(_keyFailedAttempts, _failedAttempts);

      if (_failedAttempts >= 5) {
        // Lockout for 5 minutes (300 seconds)
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
        await prefs.setInt(_keyLockoutUntil, _lockoutUntil!.millisecondsSinceEpoch);
      } else if (_failedAttempts >= 3) {
        // Cooldown for 30 seconds
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        await prefs.setInt(_keyLockoutUntil, _lockoutUntil!.millisecondsSinceEpoch);
      }

      return false;
    }
  }

  Future<void> removePin() async {
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
    _pinEnabled = false;
    _biometricEnabled = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    isLockedNotifier.value = false;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    _biometricEnabled = enabled;
  }

  Future<void> setPinEnabled(bool enabled) async {
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
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts = 0;
    _lockoutUntil = null;
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);
  }

  @visibleForTesting
  void clearCooldownForTesting() {
    _lockoutUntil = null;
  }
}
