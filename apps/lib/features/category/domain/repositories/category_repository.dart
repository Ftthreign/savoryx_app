import 'package:savoryx/features/category/domain/entities/category_entity.dart';

abstract interface class CategoryRepository {
  Future<List<CategoryEntity>> getActiveCategories();

  Stream<List<CategoryEntity>> watchActiveCategories();

  Stream<List<CategoryEntity>> watchCategoriesByBudget({required bool isWants});

  Future<CategoryEntity?> getCategoryById(String id);

  Future<void> createCategory(CategoryEntity category);

  Future<void> updateCategory(CategoryEntity category);

  Future<void> deleteCategory(String id);
}
