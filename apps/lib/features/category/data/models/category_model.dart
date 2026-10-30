import 'package:savoryx/features/category/domain/entities/category_entity.dart';

/// Data Transfer Object (DTO) for Category entity.
/// Handles type-safe JSON serialization/deserialization matching Go backend contracts.
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
    super.isWants = false,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON into CategoryModel.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final String rawCreatedAt = json['created_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();
    final String rawUpdatedAt = json['updated_at'] as String? ?? rawCreatedAt;
    final String? rawDeletedAt = json['deleted_at'] as String?;

    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#D90000',
      isWants: json['is_wants'] as bool? ?? false,
      createdAt: DateTime.parse(rawCreatedAt),
      updatedAt: DateTime.parse(rawUpdatedAt),
      deletedAt: rawDeletedAt != null ? DateTime.parse(rawDeletedAt) : null,
    );
  }

  /// Factory to convert pure domain CategoryEntity to CategoryModel.
  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      isWants: entity.isWants,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Serializes CategoryModel to JSON matching Go PostgreSQL schema.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_wants': isWants,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toUtc().toIso8601String(),
    };
  }

  @override
  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isWants,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CategoryModel(
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
}
