import 'package:injectable/injectable.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@lazySingleton
class GetCategoriesUseCase {
  final CategoryRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Future<List<CategoryEntity>> call() => _repository.getActiveCategories();
}
