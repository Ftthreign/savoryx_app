// ignore_for_file: unused_field

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:savoryx/core/database/connection/native.dart' as impl;

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());
  AppDatabase.executor(super.executor);
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration strategies for future schema increments
      },
      beforeOpen: (OpeningDetails details) async {
        // Additional hook before queries are allowed
      },
    );
  }
}
