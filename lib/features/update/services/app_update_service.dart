import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static const String keyLastUpdateCheck = 'astrack_last_update_check';
  static const String keySnoozeBuild = 'astrack_update_snooze_build';
  static const String keySnoozeUntil = 'astrack_update_snooze_until';

  // 6 hours throttle for automatic background/resume checks
  static const int throttleDurationMs = 6 * 60 * 60 * 1000;
  // 3 days snooze duration when user taps "Nanti"
  static const int snoozeDurationMs = 3 * 24 * 60 * 60 * 1000;

  // Domain whitelist for update downloads (Telegram official channels)
  static const Set<String> _allowedHosts = {'t.me', 'telegram.me'};

  SupabaseClient? _customClient;
  void setMockClient(SupabaseClient? client) => _customClient = client;

  SupabaseClient? get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Verifies if a given download URL is secure and matches whitelisted domains
  bool isSafeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (uri.scheme.toLowerCase() != 'https') return false;
    final host = uri.host.toLowerCase();
    return _allowedHosts.contains(host);
  }

  /// Checks for available application updates
  /// [force]: true when user manually checks in About screen, bypassing throttle & snooze
  /// [mockCurrentBuild]: optional override for unit tests
  Future<(UpdateStatus, AppUpdateInfo?)> check({
    bool force = false,
    int? mockCurrentBuild,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!force) {
        final lastCheck = prefs.getInt(keyLastUpdateCheck) ?? 0;
        if (now - lastCheck < throttleDurationMs) {
          // Throttled: recently checked within 6 hours
          return (UpdateStatus.unknown, null);
        }
      }

      int currentBuild = mockCurrentBuild ?? 0;
      if (mockCurrentBuild == null) {
        try {
          final pkg = await PackageInfo.fromPlatform();
          currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
        } catch (_) {
          currentBuild = 0;
        }
      }

      final client = _client;
      if (client == null) {
        return (UpdateStatus.unknown, null); // fail-open offline
      }

      final dynamic response = await client
          .rpc('get_latest_app_version', params: {'p_platform': 'android'});

      // Update last check timestamp
      await prefs.setInt(keyLastUpdateCheck, now);

      if (response is! List || response.isEmpty) {
        return (UpdateStatus.unknown, null);
      }

      final rawData = Map<String, dynamic>.from(response.first as Map);
      final info = AppUpdateInfo.fromJson(rawData);

      // Strict URL verification: https and whitelisted domain only
      if (!isSafeUrl(info.downloadUrl)) {
        return (UpdateStatus.unknown, null);
      }

      // 1. Force update takes absolute precedence
      if (currentBuild < info.minSupportedBuild) {
        return (UpdateStatus.forced, info);
      }

      // 2. Optional update
      if (currentBuild < info.buildNumber) {
        if (!force) {
          final snoozedBuild = prefs.getInt(keySnoozeBuild);
          final snoozedUntil = prefs.getInt(keySnoozeUntil) ?? 0;
          if (snoozedBuild == info.buildNumber && now < snoozedUntil) {
            // User previously snoozed this specific build version within 3 days
            return (UpdateStatus.upToDate, info);
          }
        }
        return (UpdateStatus.optional, info);
      }

      // 3. Up to date
      return (UpdateStatus.upToDate, info);
    } catch (_) {
      // Offline or network error: fail-open principle (offline-first uninterrupted)
      return (UpdateStatus.unknown, null);
    }
  }

  /// Snoozes optional update prompts for a specific build for 3 days
  Future<void> snooze(int buildNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final snoozeUntil = DateTime.now().millisecondsSinceEpoch + snoozeDurationMs;
    await prefs.setInt(keySnoozeBuild, buildNumber);
    await prefs.setInt(keySnoozeUntil, snoozeUntil);
  }

  /// Launches external download URL in browser or Telegram app
  Future<bool> openDownload(AppUpdateInfo info) async {
    final uri = Uri.parse(info.downloadUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Helper to get current installed package info safely
  Future<(String, int)> getInstalledVersionInfo() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final buildNum = int.tryParse(pkg.buildNumber) ?? 1;
      return (pkg.version, buildNum);
    } catch (_) {
      return ('2.0.0', 2);
    }
  }
}
