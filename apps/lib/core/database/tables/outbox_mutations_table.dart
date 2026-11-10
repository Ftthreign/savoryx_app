import 'package:drift/drift.dart';

/// Persistent SQLite outbox queue storing offline mutations until pushed to the server.
@DataClassName('LocalOutboxMutation')
@TableIndex(name: 'idx_outbox_created_at', columns: {#createdAt})
@TableIndex(
  name: 'idx_outbox_entity_lookup',
  columns: {#entityType, #entityId},
)
class LocalOutboxMutations extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
