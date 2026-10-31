import 'package:drift/drift.dart';

@DataClassName('LocalAccount')
class LocalAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  TextColumn get type => text()();
  Int64Column get balance => int64().clientDefault(() => BigInt.zero)();
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('IDR'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
