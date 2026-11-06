import 'package:injectable/injectable.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@lazySingleton
class WatchCategoriesUseCase {
  final CategoryRepository _repository;

  const WatchCategoriesUseCase(this._repository);

  Stream<List<CategoryEntity>> call() => _repository.watchActiveCategories();
}
