import 'package:injectable/injectable.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@lazySingleton
class CreateCategoryUseCase {
  final CategoryRepository _repository;

  const CreateCategoryUseCase(this._repository);

  Future<void> call(CategoryEntity category) {
    if (category.id.trim().isEmpty) {
      throw ArgumentError('Category ID cannot be empty');
    }
    if (category.name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }
    return _repository.createCategory(category);
  }
}
