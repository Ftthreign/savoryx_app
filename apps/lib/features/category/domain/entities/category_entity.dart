/// Pure Dart domain entity for transaction categorization.
/// Distinguishes between Wants (lifestyle/discretionary) and Needs (survival/obligatory).
class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isWants = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isWants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isWants,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isWants: isWants ?? this.isWants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryEntity &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.color == color &&
        other.isWants == isWants &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        icon,
        color,
        isWants,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
