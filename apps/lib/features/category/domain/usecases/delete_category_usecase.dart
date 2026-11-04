import 'package:injectable/injectable.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@lazySingleton
class DeleteCategoryUseCase {
  final CategoryRepository _repository;

  const DeleteCategoryUseCase(this._repository);

  Future<void> call(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Category ID cannot be empty');
    }
    return _repository.deleteCategory(id);
  }
}
