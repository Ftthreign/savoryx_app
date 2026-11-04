import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/category/data/repositories/category_repository_impl.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';

void main() {
  group('CategoryRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late CategoryRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = CategoryRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('getActiveCategories returns seeded categories', () async {
      final categories = await repository.getActiveCategories();
      // AppDatabase seeds 8 initial default categories (4 Needs, 4 Wants)
      expect(categories.length, equals(8));
    });

    test('createCategory, getCategoryById, and watchActiveCategories', () async {
      final now = DateTime.now().toUtc();
      final newCat = CategoryEntity(
        id: 'cat-custom-01',
        name: 'Books & Learning',
        icon: 'menu_book',
        color: '#8DB355',
        isWants: false,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createCategory(newCat);

      final retrieved = await repository.getCategoryById('cat-custom-01');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Books & Learning'));
      expect(retrieved.icon, equals('menu_book'));
      expect(retrieved.color, equals('#8DB355'));
      expect(retrieved.isWants, isFalse);

      final streamCats = await repository.watchActiveCategories().first;
      expect(streamCats.any((c) => c.id == 'cat-custom-01'), isTrue);
    });

    test('watchCategoriesByBudget separates Needs and Wants', () async {
      final needs = await repository.watchCategoriesByBudget(isWants: false).first;
      final wants = await repository.watchCategoriesByBudget(isWants: true).first;

      expect(needs.every((c) => !c.isWants), isTrue);
      expect(wants.every((c) => c.isWants), isTrue);
      expect(needs.length + wants.length, equals(8));
    });

    test('updateCategory modifies category attributes', () async {
      final now = DateTime.now().toUtc();
      final cat = CategoryEntity(
        id: 'cat-mod-01',
        name: 'Gym Subscription',
        icon: 'fitness_center',
        color: '#D90000',
        isWants: true,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createCategory(cat);
      await repository.updateCategory(cat.copyWith(name: 'Health & Fitness'));

      final retrieved = await repository.getCategoryById('cat-mod-01');
      expect(retrieved!.name, equals('Health & Fitness'));
    });

    test('deleteCategory soft-deletes category from active list', () async {
      final now = DateTime.now().toUtc();
      final cat = CategoryEntity(
        id: 'cat-del-01',
        name: 'Temporary Event',
        icon: 'celebration',
        color: '#FFEA93',
        isWants: true,
        createdAt: now,
        updatedAt: now,
      );

      await repository.createCategory(cat);
      await repository.deleteCategory('cat-del-01');

      final active = await repository.getActiveCategories();
      expect(active.any((c) => c.id == 'cat-del-01'), isFalse);

      final directlyFetched = await repository.getCategoryById('cat-del-01');
      expect(directlyFetched?.isDeleted, isTrue);
    });
  });
}
