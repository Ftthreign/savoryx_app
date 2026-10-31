import 'package:drift/drift.dart';
import 'package:savoryx/core/database/tables/accounts_table.dart';
import 'package:savoryx/core/database/tables/categories_table.dart';

@DataClassName('LocalTransaction')
@TableIndex(
    name: 'idx_local_tx_acc_time', columns: {#accountId, #transactionTime})
class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(LocalAccounts, #id)();
  TextColumn get categoryId =>
      text().nullable().references(LocalCategories, #id)();
  Int64Column get amount => int64()();
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('IDR'))();
  Int64Column get exchangeRateToBase =>
      int64().clientDefault(() => BigInt.from(1000000))();
  Int64Column get baseAmount => int64()();
  TextColumn get type => text()();
  DateTimeColumn get transactionTime => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
