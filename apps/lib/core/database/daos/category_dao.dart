import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [LocalCategories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Emits a continuous, reactive stream of all active categories ordered by name.
  Stream<List<LocalCategory>> watchAllActiveCategories() {
    return (select(localCategories)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Emits a filtered reactive stream based on the Needs vs Wants budget classification.
  Stream<List<LocalCategory>> watchCategoriesByBudget({required bool isWants}) {
    return (select(localCategories)
          ..where((t) => t.deletedAt.isNull() & t.isWants.equals(isWants))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Retrieves all active categories as a one-time snapshot.
  Future<List<LocalCategory>> getAllActiveCategories() {
    return (select(localCategories)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Finds a category by its unique UUID string.
  Future<LocalCategory?> getCategoryById(String id) {
    return (select(localCategories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new category record.
  Future<int> insertCategory(LocalCategoriesCompanion companion) {
    return into(localCategories).insert(companion);
  }

  /// Updates an existing category metadata.
  Future<int> updateCategory(LocalCategoriesCompanion companion) {
    return (update(localCategories)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
  }

  /// Soft deletes a category using the tombstone pattern.
  Future<int> softDeleteCategory(String id) {
    final now = DateTime.now().toUtc();
    return (update(localCategories)..where((t) => t.id.equals(id))).write(
      LocalCategoriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ),
    );
  }
}
