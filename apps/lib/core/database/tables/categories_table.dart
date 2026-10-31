import 'package:drift/drift.dart';

@DataClassName('LocalCategory')
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  TextColumn get icon => text().withLength(min: 1, max: 64)();
  TextColumn get color => text().withLength(min: 7, max: 7)();
  BoolColumn get isWants => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
