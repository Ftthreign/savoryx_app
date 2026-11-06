import 'package:injectable/injectable.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@lazySingleton
class GetCategoryByIdUseCase {
  final CategoryRepository _repository;

  const GetCategoryByIdUseCase(this._repository);

  Future<CategoryEntity?> call(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Category ID cannot be empty');
    }
    return _repository.getCategoryById(id);
  }
}
