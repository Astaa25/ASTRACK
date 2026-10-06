import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

enum AstraNotificationType {
  dailyReminder,
  budgetWarning,
  budgetExceeded,
  recurringDue,
  savingsProgress,
  subscriptionExpiry,
  paymentSuccess,
  paymentFailed,
  aiQuotaWarning,
  syncFailed,
  monthlyReport,
  unusualSpending,
}

class AstraNotificationItem {
  final String id;
  final AstraNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AstraNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AstraNotificationItem.fromJson(Map<String, dynamic> json) =>
      AstraNotificationItem(
        id: json['id'] as String,
        type: AstraNotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AstraNotificationType.budgetWarning,
        ),
        title: json['title'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

/// Model for Remote Push Device Token (FCM / APNs)
class DeviceToken {
  final String userId;
  final String deviceId;
  final String token;
  final String platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceToken({
    required this.userId,
    required this.deviceId,
    required this.token,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'device_id': deviceId,
    'token': token,
    'platform': platform,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory DeviceToken.fromJson(Map<String, dynamic> json) => DeviceToken(
    userId: json['user_id'] as String,
    deviceId: json['device_id'] as String,
    token: json['token'] as String,
    platform: json['platform'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Remote Push Notification Service Abstraction (Firebase Cloud Messaging / APNs)
class RemoteNotificationService {
  static final RemoteNotificationService _instance = RemoteNotificationService._internal();
  factory RemoteNotificationService() => _instance;
  RemoteNotificationService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Register or update device push token on Supabase backend
  Future<bool> registerDeviceToken({
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      await client.from('user_device_tokens').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,device_id');
      return true;
    } catch (e) {
      debugPrint('[RemoteNotificationService] Failed to register token: $e');
      return false;
    }
  }

  /// Revoke device push token on logout
  Future<bool> revokeDeviceToken({
    required String userId,
    required String deviceId,
  }) async {
    final client = _supabase;
    if (client == null) return false;

    try {
      await client
          .from('user_device_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
      return true;
    } catch (e) {
      debugPrint('[RemoteNotificationService] Failed to revoke token: $e');
      return false;
    }
  }

  /// Dispatches incoming remote push notification to local UI notification list
  void handleIncomingRemoteMessage(Map<String, dynamic> payload) {
    final title = payload['title'] as String? ?? 'ASTRACK Notification';
    final body = payload['body'] as String? ?? '';
    final typeStr = payload['type'] as String? ?? 'dailyReminder';

    final type = AstraNotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AstraNotificationType.dailyReminder,
    );

    NotificationService().addNotification(
      type: type,
      title: title,
      message: body,
    );
  }
}

/// Main Notification Engine & Local Notification Scheduler
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _keyNotifications = 'astrack_notifications_list';

  final List<AstraNotificationItem> _notifications = [];
  final Set<String> _triggeredWarnings = {};

  // Notification Preferences
  bool dailyReminderEnabled = true;
  bool budgetWarningEnabled = true;
  bool savingsProgressEnabled = true;
  bool recurringAlertEnabled = true;
  bool subscriptionExpiryEnabled = true;
  bool aiQuotaWarningEnabled = true;

  List<AstraNotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyNotifications);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _notifications.clear();
        _notifications.addAll(list.map((e) => AstraNotificationItem.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_notifications.take(50).map((e) => e.toJson()).toList());
      await prefs.setString(_keyNotifications, raw);
    } catch (_) {}
  }

  /// Check budget usage and trigger warning at 70%, 90%, 100%
  void checkBudgetWarning({
    required Budget budget,
    required double spentAmount,
  }) {
    if (!budgetWarningEnabled || budget.limitAmount <= 0) return;

    final percent = (spentAmount / budget.limitAmount) * 100;
    String? title;
    String? message;
    AstraNotificationType type = AstraNotificationType.budgetWarning;
    String warningKey = '${budget.id}_';

    if (percent >= 100) {
      warningKey += '100';
      if (!_triggeredWarnings.contains(warningKey)) {
        _triggeredWarnings.add(warningKey);
        type = AstraNotificationType.budgetExceeded;
        title = 'Anggaran Terlampaui! 🚨';
        message = 'Pengeluaran untuk ${budget.categoryName} telah mencapai ${percent.toStringAsFixed(0)}% dari batas limit.';
      }
    } else if (percent >= 90) {
      warningKey += '90';
      if (!_triggeredWarnings.contains(warningKey)) {
        _triggeredWarnings.add(warningKey);
        title = 'Peringatan Anggaran Kritis! ⚠️';
        message = 'Pengeluaran untuk ${budget.categoryName} sudah ${percent.toStringAsFixed(0)}% dari batas limit.';
      }
    } else if (percent >= 70) {
      warningKey += '70';
      if (!_triggeredWarnings.contains(warningKey)) {
        _triggeredWarnings.add(warningKey);
        title = 'Waspada Anggaran 💡';
        message = 'Pengeluaran untuk ${budget.categoryName} telah mencapai ${percent.toStringAsFixed(0)}% dari batas limit.';
      }
    }

    if (title != null && message != null) {
      addNotification(
        type: type,
        title: title,
        message: message,
      );
    }
  }

  /// Notify savings milestone (25%, 50%, 75%, 100%)
  void notifySavingsProgress(SavingsGoal goal) {
    if (!savingsProgressEnabled || goal.targetAmount <= 0) return;
    final percent = (goal.currentAmount / goal.targetAmount) * 100;
    if (percent >= 100 && !_triggeredWarnings.contains('${goal.id}_100')) {
      _triggeredWarnings.add('${goal.id}_100');
      addNotification(
        type: AstraNotificationType.savingsProgress,
        title: 'Target Tercapai! 🎉',
        message: 'Selamat! Target tabungan "${goal.name}" telah tercapai 100%.',
      );
    } else if (percent >= 75 && !_triggeredWarnings.contains('${goal.id}_75')) {
      _triggeredWarnings.add('${goal.id}_75');
      addNotification(
        type: AstraNotificationType.savingsProgress,
        title: 'Hampir Sampai! 🚀 (75%)',
        message: 'Target tabungan "${goal.name}" sudah mencapai 75%. Sedikit lagi!',
      );
    } else if (percent >= 50 && !_triggeredWarnings.contains('${goal.id}_50')) {
      _triggeredWarnings.add('${goal.id}_50');
      addNotification(
        type: AstraNotificationType.savingsProgress,
        title: 'Tabungan Setengah Jalan! 🎯 (50%)',
        message: 'Target tabungan "${goal.name}" sudah mencapai 50%. Terus konsisten!',
      );
    } else if (percent >= 25 && !_triggeredWarnings.contains('${goal.id}_25')) {
      _triggeredWarnings.add('${goal.id}_25');
      addNotification(
        type: AstraNotificationType.savingsProgress,
        title: 'Langkah Awal Mantap! 🌟 (25%)',
        message: 'Target tabungan "${goal.name}" sudah mencapai 25%. Awal yang luar biasa!',
      );
    }
  }

  void notifySubscriptionExpiry(int daysRemaining) {
    if (!subscriptionExpiryEnabled) return;
    addNotification(
      type: AstraNotificationType.subscriptionExpiry,
      title: 'Masa Aktif Pro Segera Berakhir ⏳',
      message: 'Langganan ASTRACK Pro Anda tersisa $daysRemaining hari. Perpanjang sekarang agar akses fitur AI dan OCR tetap aktif.',
    );
  }

  void notifyPaymentSuccess({required String planId, required double amount}) {
    addNotification(
      type: AstraNotificationType.paymentSuccess,
      title: 'Pembayaran Dikonfirmasi! 🎉',
      message: 'Paket langganan $planId telah aktif. Terima kasih atas dukungan Anda!',
    );
  }

  void notifyPaymentFailed({required String orderId, String? reason}) {
    addNotification(
      type: AstraNotificationType.paymentFailed,
      title: 'Pembayaran Gagal ❌',
      message: reason ?? 'Transaksi $orderId belum berhasil diselesaikan. Silakan coba kembali.',
    );
  }

  void notifyAiQuotaWarning(int remaining) {
    if (!aiQuotaWarningEnabled) return;
    addNotification(
      type: AstraNotificationType.aiQuotaWarning,
      title: 'Kuota AI Menipis 🤖',
      message: 'Sisa kuota AI Anda bulan ini tinggal $remaining permintaan. Tingkatkan paket untuk akses tanpa batas.',
    );
  }

  void notifySyncFailed(String errorMsg) {
    addNotification(
      type: AstraNotificationType.syncFailed,
      title: 'Sinkronisasi Gagal ☁️',
      message: 'Data finansial belum terunggah ke cloud: $errorMsg',
    );
  }

  void notifyDailyReminder() {
    if (!dailyReminderEnabled) return;
    addNotification(
      type: AstraNotificationType.dailyReminder,
      title: 'Catat Pengeluaran Hari Ini ✍️',
      message: 'Jangan lupa luangkan 1 menit untuk mencatat transaksi dan menjaga kesehatan finansialmu.',
    );
  }

  void addNotification({
    required AstraNotificationType type,
    required String title,
    required String message,
  }) {
    final item = AstraNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, item);
    _persistNotifications();
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _persistNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _persistNotifications();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _triggeredWarnings.clear();
    _persistNotifications();
    notifyListeners();
  }
}
