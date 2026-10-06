import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_models.dart';
import 'payment_service.dart';

class PaymentGatewayConfigService {
  static final PaymentGatewayConfigService _instance = PaymentGatewayConfigService._internal();
  factory PaymentGatewayConfigService() => _instance;
  PaymentGatewayConfigService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  PaymentGatewayConfig _inMemoryConfig = PaymentGatewayConfig(
    paymentMode: PaymentMode.hybrid,
    activeProvider: PaymentGatewayType.sandbox,
    isSandbox: true,
    webhookSecret: 'astrack_webhook_secret_default',
  );

  void resetInMemoryState() {
    _inMemoryConfig = PaymentGatewayConfig(
      paymentMode: PaymentMode.hybrid,
      activeProvider: PaymentGatewayType.sandbox,
      isSandbox: true,
      webhookSecret: 'astrack_webhook_secret_default',
    );
  }

  /// Fetches current server-authoritative configuration
  Future<PaymentGatewayConfig> getConfig() async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.rpc('get_payment_gateway_config');
        if (res != null) {
          final config = PaymentGatewayConfig.fromJson(Map<String, dynamic>.from(res));
          _inMemoryConfig = config;
          return config;
        }
      } catch (_) {}
    }
    return _inMemoryConfig;
  }

  /// Admin updates configuration server-side
  Future<PaymentGatewayConfig> updateConfig({
    required PaymentMode paymentMode,
    required PaymentGatewayType activeProvider,
    required bool isSandbox,
    String? webhookSecret,
    required String adminId,
  }) async {
    if (!adminId.toLowerCase().contains('admin')) {
      throw StateError('Unauthorized: Hanya Administrator yang berwenang mengubah konfigurasi gateway.');
    }

    final client = _supabase;
    if (client != null) {
      try {
        final res = await client.rpc('admin_update_payment_gateway_config', params: {
          'p_payment_mode': paymentMode.name,
          'p_active_provider': activeProvider.name,
          'p_is_sandbox': isSandbox,
          if (webhookSecret != null) 'p_webhook_secret': webhookSecret,
          'p_admin_id': adminId,
        });
        if (res != null && res['success'] == true) {
          final updated = PaymentGatewayConfig.fromJson(Map<String, dynamic>.from(res));
          _inMemoryConfig = updated;
          return updated;
        }
      } catch (_) {}
    }

    _inMemoryConfig = _inMemoryConfig.copyWith(
      paymentMode: paymentMode,
      activeProvider: activeProvider,
      isSandbox: isSandbox,
      webhookSecret: webhookSecret,
      updatedAt: DateTime.now(),
    );
    return _inMemoryConfig;
  }

  /// Resolves the current active PaymentProvider based on authoritative configuration
  Future<PaymentProvider> resolveActiveProvider() async {
    final cfg = await getConfig();
    if (cfg.paymentMode == PaymentMode.manualQris) {
      return ManualQrisPaymentProvider();
    }
    return PaymentGatewayFactory.create(providerType: cfg.activeProvider.name);
  }
}
