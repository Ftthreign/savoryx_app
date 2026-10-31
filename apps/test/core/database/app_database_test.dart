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

    test('schemaVersion should be 1', () {
      expect(database.schemaVersion, equals(1));
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
