class FundSource {
  final String id;
  final String name;
  final double balance;
  final String iconName;
  final String colorHex;
  final String description;
  final bool isDefault;
  final DateTime createdAt;

  FundSource({
    required this.id,
    required this.name,
    required this.balance,
    this.iconName = 'wallet',
    this.colorHex = '16A34A',
    this.description = '',
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FundSource copyWith({
    String? id,
    String? name,
    double? balance,
    String? iconName,
    String? colorHex,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return FundSource(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'iconName': iconName,
      'colorHex': colorHex,
      'description': description,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FundSource.fromJson(Map<String, dynamic> json) {
    return FundSource(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      iconName: json['iconName'] as String? ?? 'wallet',
      colorHex: json['colorHex'] as String? ?? '16A34A',
      description: json['description'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
