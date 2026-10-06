import 'dart:convert';

enum SubscriptionStatus { trialing, active, pastDue, canceled, expired, paused }
enum LicenseStatus { pending, active, suspended, expired, revoked, canceled }
enum PolicyStatus { draft, published, archived }
enum PlanType { free, trial, regular, promotional, enterprise, custom, lifetime }
enum DurationType { months, days, custom_date, lifetime }

class Plan {
  final String id;
  final String slug;
  final String name;
  final String description;
  final PlanType type;
  final double monthlyPrice;
  final int maxDevices;
  final int maxAiRequests;
  final int durationMonths;
  final List<String> features;
  final bool isActive;
  final bool isRecommended;

  Plan({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    required this.type,
    required this.monthlyPrice,
    required this.maxDevices,
    required this.maxAiRequests,
    this.durationMonths = 1,
    this.features = const [],
    this.isActive = true,
    this.isRecommended = false,
  });

  /// Formatted duration string for display (e.g. / bulan, / tahun, Lifetime)
  String get durationLabel {
    if (durationMonths >= 120 || type == PlanType.lifetime) {
      return 'Lifetime';
    } else if (durationMonths == 12) {
      return '/ tahun';
    } else if (durationMonths == 6) {
      return '/ 6 bulan';
    } else if (durationMonths == 3) {
      return '/ 3 bulan';
    } else if (durationMonths == 1) {
      return '/ bulan';
    } else {
      return '/ $durationMonths bulan';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'description': description,
    'type': type.name,
    'monthlyPrice': monthlyPrice,
    'maxDevices': maxDevices,
    'maxAiRequests': maxAiRequests,
    'durationMonths': durationMonths,
    'features': features,
    'isActive': isActive,
    'isRecommended': isRecommended,
  };

  factory Plan.fromJson(Map<String, dynamic> json) {
    List<String> parsedFeatures = [];
    if (json['features'] != null) {
      if (json['features'] is List) {
        parsedFeatures = (json['features'] as List).map((e) => e.toString()).toList();
      } else if (json['features'] is String) {
        try {
          final decoded = jsonDecode(json['features']);
          if (decoded is List) {
            parsedFeatures = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          parsedFeatures = (json['features'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
    }

    final rawPrice = json['monthlyPrice'] ?? json['monthly_price'] ?? 0;
    final price = double.tryParse(rawPrice.toString()) ?? 0.0;
    final rawDuration = json['durationMonths'] ?? json['duration_months'] ?? 1;
    final duration = int.tryParse(rawDuration.toString()) ?? 1;

    final planId = json['id']?.toString() ?? '';
    final isRec = json['isRecommended'] ?? json['is_recommended'] ?? (planId == 'plan_pro');

    return Plan(
      id: planId,
      slug: json['slug']?.toString() ?? planId,
      name: json['name']?.toString() ?? 'Plan',
      description: json['description']?.toString() ?? '',
      type: PlanType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['type']?.toString().toLowerCase() ?? 'regular'),
        orElse: () => PlanType.regular,
      ),
      monthlyPrice: price,
      maxDevices: int.tryParse((json['maxDevices'] ?? json['max_devices'] ?? 1).toString()) ?? 1,
      maxAiRequests: int.tryParse((json['maxAiRequests'] ?? json['max_ai_requests'] ?? 100).toString()) ?? 100,
      durationMonths: duration,
      features: parsedFeatures,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isRecommended: isRec is bool ? isRec : (isRec.toString().toLowerCase() == 'true'),
    );
  }

  Plan copyWith({
    String? id,
    String? slug,
    String? name,
    String? description,
    PlanType? type,
    double? monthlyPrice,
    int? maxDevices,
    int? maxAiRequests,
    int? durationMonths,
    List<String>? features,
    bool? isActive,
    bool? isRecommended,
  }) {
    return Plan(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      maxDevices: maxDevices ?? this.maxDevices,
      maxAiRequests: maxAiRequests ?? this.maxAiRequests,
      durationMonths: durationMonths ?? this.durationMonths,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}

class Subscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime currentPeriodEnd;
  final double paidAmount;
  final String? orderId;

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.currentPeriodEnd,
    this.paidAmount = 0.0,
    this.orderId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'planId': planId,
    'status': status.name,
    'currentPeriodEnd': currentPeriodEnd.toIso8601String(),
    'paidAmount': paidAmount,
    'orderId': orderId,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final rawPaid = json['paidAmount'] ?? json['paid_amount'] ?? 0;
    final paid = double.tryParse(rawPaid.toString()) ?? 0.0;
    final expStr = json['currentPeriodEnd'] ?? json['expires_at'] ?? DateTime.now().toIso8601String();

    return Subscription(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      planId: json['planId'] ?? json['plan_id'] ?? '',
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status']?.toString().toLowerCase() ?? 'active'),
        orElse: () => SubscriptionStatus.active,
      ),
      currentPeriodEnd: DateTime.parse(expStr.toString()).toLocal(),
      paidAmount: paid,
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
    );
  }
}

class License {
  final String id;
  final String licenseKey;
  final String userId;
  final LicenseStatus status;
  final DateTime issuedAt;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DurationType durationType;
  final int durationValue;

  License({
    required this.id, required this.licenseKey, required this.userId, 
    required this.status, required this.issuedAt, this.activatedAt, 
    this.expiresAt, this.durationType = DurationType.lifetime, this.durationValue = 0
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'licenseKey': licenseKey, 'userId': userId, 'status': status.name,
    'issuedAt': issuedAt.toIso8601String(),
    'activatedAt': activatedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'durationType': durationType.name,
    'durationValue': durationValue
  };

  factory License.fromJson(Map<String, dynamic> json) => License(
    id: json['id'], licenseKey: json['licenseKey'], userId: json['userId'], 
    status: LicenseStatus.values.firstWhere((e) => e.name == json['status']),
    issuedAt: json['issuedAt'] != null ? DateTime.parse(json['issuedAt']) : DateTime.now(),
    activatedAt: json['activatedAt'] != null ? DateTime.parse(json['activatedAt']) : null,
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    durationType: DurationType.values.firstWhere((e) => e.name == json['durationType'], orElse: () => DurationType.lifetime),
    durationValue: json['durationValue'] ?? 0
  );
}
