enum CategoryType { expense, income }

class FinancialCategory {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final CategoryType type;
  final bool isArchived;
  final bool isDefault;
  final DateTime createdAt;

  FinancialCategory({
    required this.id,
    required this.name,
    this.iconName = 'category',
    this.colorHex = '16A34A',
    this.type = CategoryType.expense,
    this.isArchived = false,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FinancialCategory copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    CategoryType? type,
    bool? isArchived,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return FinancialCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      isArchived: isArchived ?? this.isArchived,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'type': type.name,
      'isArchived': isArchived,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FinancialCategory.fromJson(Map<String, dynamic> json) {
    return FinancialCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String? ?? 'category',
      colorHex: json['colorHex'] as String? ?? '16A34A',
      type: json['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      isArchived: json['isArchived'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

