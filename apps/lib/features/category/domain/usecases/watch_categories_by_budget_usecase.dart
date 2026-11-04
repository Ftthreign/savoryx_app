import 'package:injectable/injectable.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@lazySingleton
class WatchCategoriesByBudgetUseCase {
  final CategoryRepository _repository;

  const WatchCategoriesByBudgetUseCase(this._repository);

  Stream<List<CategoryEntity>> call({required bool isWants}) =>
      _repository.watchCategoriesByBudget(isWants: isWants);
}
