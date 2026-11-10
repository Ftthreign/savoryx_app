import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';

void main() {
  group('AppDatabase Initialization & Isolate-Ready Schema Tests', () {
    late AppDatabase database;

    setUp(() {
      // Use in-memory NativeDatabase for fast, hermetic unit tests
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('schemaVersion should be 2', () {
      expect(database.schemaVersion, equals(2));
    });

    test('registers local_outbox_mutations table and indexes in sqlite_master',
        () async {
      final tables = await database
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='local_outbox_mutations'")
          .get();
      expect(tables.length, equals(1));

      final indexes = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type='index'")
          .get();
      final indexNames = indexes.map((r) => r.read<String>('name')).toSet();
      expect(indexNames, contains('idx_outbox_created_at'));
      expect(indexNames, contains('idx_outbox_entity_lookup'));
    });

    test('can open and execute pragma checks on database', () async {
      // Verify database can be initialized and queried cleanly
      final result =
          await database.customSelect('SELECT 1 AS alive').getSingle();
      expect(result.read<int>('alive'), equals(1));
    });

    test('database handles multiple queries concurrently without deadlock',
        () async {
      final futures = List.generate(
        10,
        (i) => database.customSelect('SELECT ? AS idx', variables: [
          Variable.withInt(i),
        ]).getSingle(),
      );

      final results = await Future.wait(futures);
      for (var i = 0; i < 10; i++) {
        expect(results[i].read<int>('idx'), equals(i));
      }
    });
  });
}
