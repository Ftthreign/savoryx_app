import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/category/data/models/category_model.dart';

void main() {
  group('CategoryModel & CategoryEntity Tests', () {
    final now = DateTime.utc(2026, 10, 30, 12, 0, 0);

    final tCategoryModel = CategoryModel(
      id: '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb',
      name: 'Coffee & Cafes',
      icon: 'local_cafe',
      color: '#D90000',
      isWants: true,
      createdAt: now,
      updatedAt: now,
    );

    test('CategoryEntity copyWith and value equality works properly', () {
      final updated =
          tCategoryModel.copyWith(name: 'Groceries', isWants: false);
      expect(updated.name, 'Groceries');
      expect(updated.isWants, isFalse);
      expect(updated.color, '#D90000');

      final identicalCopy = tCategoryModel.copyWith();
      expect(identicalCopy, equals(tCategoryModel));
      expect(identicalCopy.hashCode, equals(tCategoryModel.hashCode));
    });

    test('CategoryModel.fromJson deserializes contract JSON accurately', () {
      final jsonMap = <String, dynamic>{
        'id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb',
        'name': 'Coffee & Cafes',
        'icon': 'local_cafe',
        'color': '#D90000',
        'is_wants': true,
        'created_at': '2026-10-30T12:00:00.000Z',
        'updated_at': '2026-10-30T12:00:00.000Z',
        'deleted_at': null,
      };

      final result = CategoryModel.fromJson(jsonMap);
      expect(result.id, '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb');
      expect(result.name, 'Coffee & Cafes');
      expect(result.icon, 'local_cafe');
      expect(result.color, '#D90000');
      expect(result.isWants, isTrue);
      expect(result.createdAt, now);
      expect(result.deletedAt, isNull);
    });

    test('CategoryModel.toJson outputs contract-compliant JSON payload', () {
      final json = tCategoryModel.toJson();

      expect(json['id'], '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb');
      expect(json['name'], 'Coffee & Cafes');
      expect(json['icon'], 'local_cafe');
      expect(json['color'], '#D90000');
      expect(json['is_wants'], isTrue);
      expect(json['created_at'], '2026-10-30T12:00:00.000Z');
      expect(json['updated_at'], '2026-10-30T12:00:00.000Z');
      expect(json.containsKey('deleted_at'), isFalse);
    });
  });
}
