import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<CategoryEntity>> getActiveCategories() async {
    final rows = await _db.categoryDao.getAllActiveCategories();
    return rows.map(_mapToEntity).toList(growable: false);
  }

  @override
  Stream<List<CategoryEntity>> watchActiveCategories() {
    return _db.categoryDao
        .watchAllActiveCategories()
        .map((rows) => rows.map(_mapToEntity).toList(growable: false));
  }

  @override
  Stream<List<CategoryEntity>> watchCategoriesByBudget(
      {required bool isWants}) {
    return _db.categoryDao
        .watchCategoriesByBudget(isWants: isWants)
        .map((rows) => rows.map(_mapToEntity).toList(growable: false));
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    final row = await _db.categoryDao.getCategoryById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> createCategory(CategoryEntity category) async {
    await _db.categoryDao.insertCategory(
      LocalCategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        isWants: Value(category.isWants),
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        deletedAt: Value(category.deletedAt),
        isSynced: const Value(false),
      ),
    );
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await _db.categoryDao.updateCategory(
      LocalCategoriesCompanion(
        id: Value(category.id),
        name: Value(category.name),
        icon: Value(category.icon),
        color: Value(category.color),
        isWants: Value(category.isWants),
        updatedAt: Value(DateTime.now().toUtc()),
        deletedAt: Value(category.deletedAt),
        isSynced: const Value(false),
      ),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.categoryDao.softDeleteCategory(id);
  }

  CategoryEntity _mapToEntity(LocalCategory row) {
    return CategoryEntity(
      id: row.id,
      name: row.name,
      icon: row.icon,
      color: row.color,
      isWants: row.isWants,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
