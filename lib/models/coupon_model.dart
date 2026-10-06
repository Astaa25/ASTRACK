import 'dart:convert';
import '../core/utils/currency_formatter.dart';

enum CouponDiscountType { percentage, fixed }

/// Representation of a promotional discount coupon in ASTRACK
class Coupon {
  final String id;
  final String code;
  final String description;
  final CouponDiscountType discountType;
  final double discountValue;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final int usageLimit;
  final int usageCount;
  final int perUserLimit;
  final double minimumPurchase;
  final List<String> applicablePlanIds;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Coupon({
    required this.id,
    required this.code,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    required this.startsAt,
    this.expiresAt,
    this.usageLimit = 100,
    this.usageCount = 0,
    this.perUserLimit = 1,
    this.minimumPurchase = 0.0,
    this.applicablePlanIds = const [],
    this.isActive = true,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Formatted discount tag (e.g. 20% OFF or Rp5.000 OFF)
  String get discountLabel {
    if (discountType == CouponDiscountType.percentage) {
      final pct = discountValue.truncateToDouble() == discountValue
          ? discountValue.toInt()
          : discountValue;
      return '$pct% OFF';
    } else {
      return '${CurrencyFormatter.format(discountValue)} OFF';
    }
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUpcoming => startsAt.isAfter(DateTime.now());
  bool get isExhausted => usageLimit > 0 && usageCount >= usageLimit;

  /// Human readable status string
  String get statusLabel {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isUpcoming) return 'Upcoming';
    if (isExhausted) return 'Exhausted';
    return 'Active';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code.toUpperCase().trim(),
        'description': description,
        'discount_type': discountType.name,
        'discount_value': discountValue,
        'starts_at': startsAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'per_user_limit': perUserLimit,
        'minimum_purchase': minimumPurchase,
        'applicable_plan_ids': applicablePlanIds,
        'is_active': isActive,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Coupon.fromJson(Map<String, dynamic> json) {
    List<String> plans = [];
    if (json['applicable_plan_ids'] != null) {
      if (json['applicable_plan_ids'] is List) {
        plans = (json['applicable_plan_ids'] as List).map((e) => e.toString()).toList();
      } else if (json['applicable_plan_ids'] is String) {
        try {
          final decoded = jsonDecode(json['applicable_plan_ids']);
          if (decoded is List) plans = decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
    }

    final rawType = (json['discount_type'] ?? json['discountType'] ?? 'percentage').toString().toLowerCase();
    final discountType = rawType == 'fixed' ? CouponDiscountType.fixed : CouponDiscountType.percentage;

    return Coupon(
      id: json['id']?.toString() ?? '',
      code: (json['code'] ?? '').toString().toUpperCase().trim(),
      description: json['description']?.toString() ?? '',
      discountType: discountType,
      discountValue: double.tryParse((json['discount_value'] ?? json['discountValue'] ?? 0).toString()) ?? 0.0,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at'].toString()).toLocal() : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'].toString()).toLocal() : null,
      usageLimit: int.tryParse((json['usage_limit'] ?? json['usageLimit'] ?? 100).toString()) ?? 100,
      usageCount: int.tryParse((json['usage_count'] ?? json['usageCount'] ?? 0).toString()) ?? 0,
      perUserLimit: int.tryParse((json['per_user_limit'] ?? json['perUserLimit'] ?? 1).toString()) ?? 1,
      minimumPurchase: double.tryParse((json['minimum_purchase'] ?? json['minimumPurchase'] ?? 0).toString()) ?? 0.0,
      applicablePlanIds: plans,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()).toLocal() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()).toLocal() : DateTime.now(),
    );
  }

  Coupon copyWith({
    String? id,
    String? code,
    String? description,
    CouponDiscountType? discountType,
    double? discountValue,
    DateTime? startsAt,
    DateTime? expiresAt,
    int? usageLimit,
    int? usageCount,
    int? perUserLimit,
    double? minimumPurchase,
    List<String>? applicablePlanIds,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      applicablePlanIds: applicablePlanIds ?? this.applicablePlanIds,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Coupon validation and discount computation result
class CouponValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Coupon? coupon;
  final double originalPrice;
  final double discountAmount;
  final double finalPrice;

  const CouponValidationResult({
    required this.isValid,
    this.errorMessage,
    this.coupon,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
  });

  factory CouponValidationResult.success({
    required Coupon coupon,
    required double originalPrice,
    required double discountAmount,
    required double finalPrice,
  }) {
    return CouponValidationResult(
      isValid: true,
      coupon: coupon,
      originalPrice: originalPrice,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
    );
  }

  factory CouponValidationResult.failure({
    required String message,
    required double originalPrice,
  }) {
    return CouponValidationResult(
      isValid: false,
      errorMessage: message,
      originalPrice: originalPrice,
      discountAmount: 0.0,
      finalPrice: originalPrice,
    );
  }
}

/// Historical audit record of plan price changes
class PlanPriceHistory {
  final String id;
  final String planId;
  final double oldPrice;
  final double newPrice;
  final String changedBy;
  final DateTime changedAt;

  PlanPriceHistory({
    required this.id,
    required this.planId,
    required this.oldPrice,
    required this.newPrice,
    required this.changedBy,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'old_price': oldPrice,
        'new_price': newPrice,
        'changed_by': changedBy,
        'changed_at': changedAt.toIso8601String(),
      };

  factory PlanPriceHistory.fromJson(Map<String, dynamic> json) => PlanPriceHistory(
        id: json['id']?.toString() ?? '',
        planId: json['plan_id']?.toString() ?? '',
        oldPrice: double.tryParse((json['old_price'] ?? 0).toString()) ?? 0.0,
        newPrice: double.tryParse((json['new_price'] ?? 0).toString()) ?? 0.0,
        changedBy: json['changed_by']?.toString() ?? 'Admin',
        changedAt: json['changed_at'] != null
            ? DateTime.parse(json['changed_at'].toString()).toLocal()
            : DateTime.now(),
      );
}
