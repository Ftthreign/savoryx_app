import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/repositories/category_repository.dart';
import 'package:savoryx/features/category/domain/usecases/create_category_usecase.dart';
import 'package:savoryx/features/category/domain/usecases/delete_category_usecase.dart';
import 'package:savoryx/features/category/domain/usecases/get_categories_usecase.dart';
import 'package:savoryx/features/category/domain/usecases/get_category_by_id_usecase.dart';
import 'package:savoryx/features/category/domain/usecases/update_category_usecase.dart';
import 'package:savoryx/features/category/domain/usecases/watch_categories_by_budget_usecase.dart';
import 'package:savoryx/features/category/domain/usecases/watch_categories_usecase.dart';

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryEntity> _categories = [];

  @override
  Future<List<CategoryEntity>> getActiveCategories() async {
    return _categories.where((c) => c.deletedAt == null).toList();
  }

  @override
  Stream<List<CategoryEntity>> watchActiveCategories() {
    return Stream.value(_categories.where((c) => c.deletedAt == null).toList());
  }

  @override
  Stream<List<CategoryEntity>> watchCategoriesByBudget({required bool isWants}) {
    return Stream.value(_categories
        .where((c) => c.deletedAt == null && c.isWants == isWants)
        .toList());
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    return _categories.cast<CategoryEntity?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
  }

  @override
  Future<void> createCategory(CategoryEntity category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(deletedAt: DateTime.now().toUtc());
    }
  }
}

void main() {
  group('Category Domain Use Cases & SRP Tests', () {
    late FakeCategoryRepository fakeRepo;
    late GetCategoriesUseCase getCategoriesUseCase;
    late WatchCategoriesUseCase watchCategoriesUseCase;
    late WatchCategoriesByBudgetUseCase watchCategoriesByBudgetUseCase;
    late GetCategoryByIdUseCase getCategoryByIdUseCase;
    late CreateCategoryUseCase createCategoryUseCase;
    late UpdateCategoryUseCase updateCategoryUseCase;
    late DeleteCategoryUseCase deleteCategoryUseCase;

    final now = DateTime.parse('2026-11-01T10:00:00Z');
    final needCategory = CategoryEntity(
      id: 'cat-001',
      name: 'Groceries',
      icon: 'shopping_cart',
      color: '#8DB355',
      isWants: false,
      createdAt: now,
      updatedAt: now,
    );

    final wantCategory = CategoryEntity(
      id: 'cat-002',
      name: 'Coffee & Cafe',
      icon: 'local_cafe',
      color: '#D90000',
      isWants: true,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      fakeRepo = FakeCategoryRepository();
      getCategoriesUseCase = GetCategoriesUseCase(fakeRepo);
      watchCategoriesUseCase = WatchCategoriesUseCase(fakeRepo);
      watchCategoriesByBudgetUseCase = WatchCategoriesByBudgetUseCase(fakeRepo);
      getCategoryByIdUseCase = GetCategoryByIdUseCase(fakeRepo);
      createCategoryUseCase = CreateCategoryUseCase(fakeRepo);
      updateCategoryUseCase = UpdateCategoryUseCase(fakeRepo);
      deleteCategoryUseCase = DeleteCategoryUseCase(fakeRepo);
    });

    test('CreateCategoryUseCase and GetCategoriesUseCase happy path', () async {
      await createCategoryUseCase(needCategory);
      await createCategoryUseCase(wantCategory);

      final allActive = await getCategoriesUseCase();
      expect(allActive.length, equals(2));
      expect(allActive.map((c) => c.name), containsAll(['Groceries', 'Coffee & Cafe']));
    });

    test('CreateCategoryUseCase throws ArgumentError on empty id or name', () async {
      expect(
        () => createCategoryUseCase(needCategory.copyWith(id: '')),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => createCategoryUseCase(needCategory.copyWith(name: '  ')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('WatchCategoriesUseCase emits all active categories reactively', () async {
      await createCategoryUseCase(needCategory);
      await createCategoryUseCase(wantCategory);

      final activeStream = await watchCategoriesUseCase().first;
      expect(activeStream.length, equals(2));
      expect(activeStream.map((c) => c.id), containsAll(['cat-001', 'cat-002']));
    });

    test('WatchCategoriesByBudgetUseCase filters Needs vs Wants reactively', () async {
      await createCategoryUseCase(needCategory);
      await createCategoryUseCase(wantCategory);

      final needs = await watchCategoriesByBudgetUseCase(isWants: false).first;
      expect(needs.length, equals(1));
      expect(needs.first.name, equals('Groceries'));
      expect(needs.first.isWants, isFalse);

      final wants = await watchCategoriesByBudgetUseCase(isWants: true).first;
      expect(wants.length, equals(1));
      expect(wants.first.name, equals('Coffee & Cafe'));
      expect(wants.first.isWants, isTrue);
    });

    test('GetCategoryByIdUseCase retrieves target or null', () async {
      await createCategoryUseCase(needCategory);

      final found = await getCategoryByIdUseCase('cat-001');
      expect(found, isNotNull);
      expect(found!.id, equals('cat-001'));

      final missing = await getCategoryByIdUseCase('cat-999');
      expect(missing, isNull);

      expect(() => getCategoryByIdUseCase(''), throwsA(isA<ArgumentError>()));
    });

    test('UpdateCategoryUseCase modifies category properties', () async {
      await createCategoryUseCase(needCategory);

      final updated = needCategory.copyWith(name: 'Organic Groceries');
      await updateCategoryUseCase(updated);

      final retrieved = await getCategoryByIdUseCase('cat-001');
      expect(retrieved!.name, equals('Organic Groceries'));
    });

    test('DeleteCategoryUseCase soft-deletes category from active list', () async {
      await createCategoryUseCase(needCategory);
      expect((await getCategoriesUseCase()).length, equals(1));

      await deleteCategoryUseCase('cat-001');

      final active = await getCategoriesUseCase();
      expect(active, isEmpty);

      final retrieved = await getCategoryByIdUseCase('cat-001');
      expect(retrieved?.isDeleted, isTrue);
    });
  });
}
