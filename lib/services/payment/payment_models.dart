enum PaymentStatus {
  pending,
  claimed,
  paid,
  failed,
  expired,
  refunded,
  rejected;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.claimed:
        return 'Menunggu Verifikasi';
      case PaymentStatus.paid:
        return 'Berhasil';
      case PaymentStatus.failed:
        return 'Gagal';
      case PaymentStatus.expired:
        return 'Kedaluwarsa';
      case PaymentStatus.refunded:
        return 'Dikembalikan';
      case PaymentStatus.rejected:
        return 'Ditolak';
    }
  }
}

class PaymentOrder {
  final String orderId;
  final String userId;
  final String planId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? paymentUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  // Manual QRIS & Dynamic Pricing Fields
  final double? baseAmount;
  final double? discountAmount;
  final int? uniqueCode;
  final String? couponCode;
  final String paymentMethod; // 'manual_qris', 'sandbox', 'gateway'
  final String? qrisPayload;
  final String? proofUrl;
  final String? proofNotes;
  final String? rejectionReason;
  final DateTime? claimedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  PaymentOrder({
    required this.orderId,
    required this.userId,
    required this.planId,
    required this.amount,
    this.currency = 'IDR',
    this.status = PaymentStatus.pending,
    this.paymentUrl,
    required this.createdAt,
    required this.expiresAt,
    this.baseAmount,
    this.discountAmount,
    this.uniqueCode,
    this.couponCode,
    this.paymentMethod = 'manual_qris',
    this.qrisPayload,
    this.proofUrl,
    this.proofNotes,
    this.rejectionReason,
    this.claimedAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  PaymentOrder copyWith({
    String? orderId,
    String? userId,
    String? planId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? paymentUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    double? baseAmount,
    double? discountAmount,
    int? uniqueCode,
    String? couponCode,
    String? paymentMethod,
    String? qrisPayload,
    String? proofUrl,
    String? proofNotes,
    String? rejectionReason,
    DateTime? claimedAt,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return PaymentOrder(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      baseAmount: baseAmount ?? this.baseAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      couponCode: couponCode ?? this.couponCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      qrisPayload: qrisPayload ?? this.qrisPayload,
      proofUrl: proofUrl ?? this.proofUrl,
      proofNotes: proofNotes ?? this.proofNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      claimedAt: claimedAt ?? this.claimedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'userId': userId,
    'planId': planId,
    'amount': amount,
    'currency': currency,
    'status': status.name,
    'paymentUrl': paymentUrl,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'baseAmount': baseAmount,
    'discountAmount': discountAmount,
    'uniqueCode': uniqueCode,
    'couponCode': couponCode,
    'paymentMethod': paymentMethod,
    'qrisPayload': qrisPayload,
    'proofUrl': proofUrl,
    'proofNotes': proofNotes,
    'rejectionReason': rejectionReason,
    'claimedAt': claimedAt?.toIso8601String(),
    'verifiedAt': verifiedAt?.toIso8601String(),
    'verifiedBy': verifiedBy,
  };

  factory PaymentOrder.fromJson(Map<String, dynamic> json) => PaymentOrder(
    orderId: (json['orderId'] ?? json['order_id']) as String,
    userId: (json['userId'] ?? json['user_id']) as String,
    planId: (json['planId'] ?? json['plan_id']) as String,
    amount: ((json['amount'] ?? json['final_amount']) as num).toDouble(),
    currency: (json['currency'] as String?) ?? 'IDR',
    status: PaymentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => PaymentStatus.pending,
    ),
    paymentUrl: (json['paymentUrl'] ?? json['payment_url']) as String?,
    createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
    expiresAt: DateTime.parse((json['expiresAt'] ?? json['expires_at']) as String),
    baseAmount: (json['baseAmount'] ?? json['base_amount']) != null
        ? ((json['baseAmount'] ?? json['base_amount']) as num).toDouble()
        : null,
    discountAmount: (json['discountAmount'] ?? json['discount_amount']) != null
        ? ((json['discountAmount'] ?? json['discount_amount']) as num).toDouble()
        : null,
    uniqueCode: (json['uniqueCode'] ?? json['unique_code']) as int?,
    couponCode: (json['couponCode'] ?? json['coupon_code']) as String?,
    paymentMethod: (json['paymentMethod'] ?? json['payment_method'] as String?) ?? 'manual_qris',
    qrisPayload: (json['qrisPayload'] ?? json['qris_payload']) as String?,
    proofUrl: (json['proofUrl'] ?? json['proof_url']) as String?,
    proofNotes: (json['proofNotes'] ?? json['proof_notes']) as String?,
    rejectionReason: (json['rejectionReason'] ?? json['rejection_reason']) as String?,
    claimedAt: (json['claimedAt'] ?? json['claimed_at']) != null
        ? DateTime.parse((json['claimedAt'] ?? json['claimed_at']) as String)
        : null,
    verifiedAt: (json['verifiedAt'] ?? json['verified_at']) != null
        ? DateTime.parse((json['verifiedAt'] ?? json['verified_at']) as String)
        : null,
    verifiedBy: (json['verifiedBy'] ?? json['verified_by']) as String?,
  );
}

class PaymentProof {
  final String id;
  final String orderId;
  final String userId;
  final String proofUrl;
  final String? notes;
  final DateTime uploadedAt;

  PaymentProof({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.proofUrl,
    this.notes,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'userId': userId,
    'proofUrl': proofUrl,
    'notes': notes,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory PaymentProof.fromJson(Map<String, dynamic> json) => PaymentProof(
    id: (json['id'] ?? '') as String,
    orderId: (json['orderId'] ?? json['order_id']) as String,
    userId: (json['userId'] ?? json['user_id']) as String,
    proofUrl: (json['proofUrl'] ?? json['proof_url']) as String,
    notes: (json['notes']) as String?,
    uploadedAt: DateTime.parse((json['uploadedAt'] ?? json['uploaded_at']) as String),
  );
}

class PaymentEvent {
  final String id;
  final String orderId;
  final String eventType;
  final String? actorId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  PaymentEvent({
    required this.id,
    required this.orderId,
    required this.eventType,
    this.actorId,
    this.payload = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'eventType': eventType,
    'actorId': actorId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PaymentEvent.fromJson(Map<String, dynamic> json) => PaymentEvent(
    id: (json['id'] ?? '') as String,
    orderId: (json['orderId'] ?? json['order_id']) as String,
    eventType: (json['eventType'] ?? json['event_type']) as String,
    actorId: (json['actorId'] ?? json['actor_id']) as String?,
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
  );
}

class PaymentWebhookPayload {
  final String orderId;
  final String eventType;
  final String signature;
  final DateTime timestamp;
  final Map<String, dynamic> rawData;
  final String provider;
  final String eventId;
  final double? grossAmount;

  PaymentWebhookPayload({
    required this.orderId,
    required this.eventType,
    required this.signature,
    required this.timestamp,
    required this.rawData,
    this.provider = 'sandbox',
    String? eventId,
    this.grossAmount,
  }) : eventId = eventId ?? 'evt_${orderId}_${timestamp.millisecondsSinceEpoch}';
}

enum PaymentMode {
  manualQris,
  gateway,
  hybrid;

  String get label {
    switch (this) {
      case PaymentMode.manualQris:
        return 'Manual QRIS Saja';
      case PaymentMode.gateway:
        return 'Payment Gateway Otomatis Saja';
      case PaymentMode.hybrid:
        return 'Hybrid (QRIS & Gateway)';
    }
  }
}

enum PaymentGatewayType {
  sandbox,
  midtrans,
  xendit,
  stripe,
  edgeGateway;

  String get label {
    switch (this) {
      case PaymentGatewayType.sandbox:
        return 'Sandbox Mock';
      case PaymentGatewayType.midtrans:
        return 'Midtrans Snap';
      case PaymentGatewayType.xendit:
        return 'Xendit Invoice';
      case PaymentGatewayType.stripe:
        return 'Stripe Checkout';
      case PaymentGatewayType.edgeGateway:
        return 'ASTRACK Secure Edge Gateway';
    }
  }
}

class PaymentGatewayConfig {
  final PaymentMode paymentMode;
  final PaymentGatewayType activeProvider;
  final bool isSandbox;
  final String webhookSecret;
  final DateTime updatedAt;

  PaymentGatewayConfig({
    this.paymentMode = PaymentMode.hybrid,
    this.activeProvider = PaymentGatewayType.sandbox,
    this.isSandbox = true,
    this.webhookSecret = 'astrack_webhook_secret_default',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isManualQrisEnabled =>
      paymentMode == PaymentMode.manualQris || paymentMode == PaymentMode.hybrid;

  bool get isGatewayEnabled =>
      paymentMode == PaymentMode.gateway || paymentMode == PaymentMode.hybrid;

  PaymentGatewayConfig copyWith({
    PaymentMode? paymentMode,
    PaymentGatewayType? activeProvider,
    bool? isSandbox,
    String? webhookSecret,
    DateTime? updatedAt,
  }) {
    return PaymentGatewayConfig(
      paymentMode: paymentMode ?? this.paymentMode,
      activeProvider: activeProvider ?? this.activeProvider,
      isSandbox: isSandbox ?? this.isSandbox,
      webhookSecret: webhookSecret ?? this.webhookSecret,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_mode': paymentMode.name,
    'active_provider': activeProvider.name,
    'is_sandbox': isSandbox,
    'webhook_secret': webhookSecret,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PaymentGatewayConfig.fromJson(Map<String, dynamic> json) => PaymentGatewayConfig(
    paymentMode: PaymentMode.values.firstWhere(
      (e) => e.name == (json['payment_mode'] ?? json['paymentMode']),
      orElse: () => PaymentMode.hybrid,
    ),
    activeProvider: PaymentGatewayType.values.firstWhere(
      (e) => e.name == (json['active_provider'] ?? json['activeProvider']),
      orElse: () => PaymentGatewayType.sandbox,
    ),
    isSandbox: (json['is_sandbox'] ?? json['isSandbox'] ?? true) as bool,
    webhookSecret: (json['webhook_secret'] ?? json['webhookSecret'] ?? 'astrack_webhook_secret_default') as String,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );
}

class WebhookProcessingResult {
  final bool success;
  final String orderId;
  final PaymentStatus? status;
  final String message;
  final bool isDuplicate;
  final bool subscriptionActivated;

  WebhookProcessingResult({
    required this.success,
    required this.orderId,
    this.status,
    required this.message,
    this.isDuplicate = false,
    this.subscriptionActivated = false,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'orderId': orderId,
    'status': status?.name,
    'message': message,
    'isDuplicate': isDuplicate,
    'subscriptionActivated': subscriptionActivated,
  };
}

