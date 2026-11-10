import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/outbox_dao.dart';
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

  /// Inserts a new category record and atomically enqueues an outbox mutation.
  Future<int> insertCategory(LocalCategoriesCompanion companion) {
    return transaction<int>(() async {
      final rowId = await into(localCategories).insert(companion);
      final inserted = await getCategoryById(companion.id.value);
      if (inserted != null && !inserted.isSynced) {
        await db.outboxDao.enqueueCategoryMutation(
          category: inserted,
          operation: OutboxOperation.create,
        );
      }
      return rowId;
    });
  }

  /// Updates an existing category metadata and atomically enqueues an outbox mutation.
  Future<int> updateCategory(LocalCategoriesCompanion companion) {
    return transaction<int>(() async {
      final targetId = companion.id.value;
      final effective = companion.copyWith(isSynced: const Value(false));
      final updatedCount = await (update(localCategories)
            ..where((t) => t.id.equals(targetId)))
          .write(effective);
      if (updatedCount > 0) {
        final updated = await getCategoryById(targetId);
        if (updated != null) {
          await db.outboxDao.enqueueCategoryMutation(
            category: updated,
            operation: OutboxOperation.update,
          );
        }
      }
      return updatedCount;
    });
  }

  /// Soft deletes a category using the tombstone pattern and atomically enqueues an outbox mutation.
  Future<int> softDeleteCategory(String id) {
    return transaction<int>(() async {
      final now = DateTime.now().toUtc();
      final updatedCount =
          await (update(localCategories)..where((t) => t.id.equals(id))).write(
        LocalCategoriesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );
      if (updatedCount > 0) {
        final deleted = await getCategoryById(id);
        if (deleted != null) {
          await db.outboxDao.enqueueCategoryMutation(
            category: deleted,
            operation: OutboxOperation.delete,
          );
        }
      }
      return updatedCount;
    });
  }
}
