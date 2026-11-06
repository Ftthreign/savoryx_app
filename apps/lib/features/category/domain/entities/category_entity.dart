import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_entity.freezed.dart';

/// Pure Dart domain entity for transaction categorization.
/// Distinguishes between Wants (lifestyle/discretionary) and Needs (survival/obligatory).
@freezed
class CategoryEntity with _$CategoryEntity {
  const CategoryEntity._();

  const factory CategoryEntity({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isWants,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _CategoryEntity;

  bool get isDeleted => deletedAt != null;
}
