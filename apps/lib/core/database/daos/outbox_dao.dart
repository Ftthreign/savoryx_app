import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/tables/outbox_mutations_table.dart';
import 'package:uuid/uuid.dart';

part 'outbox_dao.g.dart';

/// Supported entity types stored in [LocalOutboxMutations].
abstract final class OutboxEntityType {
  static const String account = 'ACCOUNT';
  static const String category = 'CATEGORY';
  static const String transaction = 'TRANSACTION';
}

/// Supported mutation operations stored in [LocalOutboxMutations].
abstract final class OutboxOperation {
  static const String create = 'CREATE';
  static const String update = 'UPDATE';
  static const String delete = 'DELETE';
}

/// Manages the local outbox mutation queue for deterministic offline-first sync.
@DriftAccessor(tables: [LocalOutboxMutations])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  static const Uuid _uuid = Uuid();

  /// Enqueues an offline mutation, coalescing pending records for the same entity.
  Future<void> enqueueMutation(LocalOutboxMutationsCompanion entry) {
    return transaction(() async {
      final entityType = entry.entityType.value;
      final entityId = entry.entityId.value;
      final incomingOp = entry.operation.value;

      final existing = await (select(localOutboxMutations)
            ..where(
              (t) =>
                  t.entityType.equals(entityType) &
                  t.entityId.equals(entityId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

      if (existing == null) {
        await into(localOutboxMutations).insert(entry);
        return;
      }

      // Preserve CREATE when an unsent newly-created entity is updated before first push.
      final coalescedOperation = existing.operation == OutboxOperation.create &&
              incomingOp == OutboxOperation.update
          ? OutboxOperation.create
          : incomingOp;

      await (update(localOutboxMutations)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        LocalOutboxMutationsCompanion(
          operation: Value(coalescedOperation),
          payloadJson: entry.payloadJson,
          createdAt: entry.createdAt,
          retryCount: const Value(0),
          lastError: const Value(null),
        ),
      );
    });
  }

  /// Convenience helper to enqueue a [LocalAccount] snapshot into the outbox.
  Future<void> enqueueAccountMutation({
    required LocalAccount account,
    required String operation,
  }) {
    final payload = jsonEncode(<String, Object?>{
      'id': account.id,
      'name': account.name,
      'type': account.type,
      'currency': account.currency,
      'balance_minor': account.balance.toString(),
      'created_at': account.createdAt.toUtc().toIso8601String(),
      'updated_at': account.updatedAt.toUtc().toIso8601String(),
      'deleted_at': account.deletedAt?.toUtc().toIso8601String(),
    });
    return enqueueMutation(
      LocalOutboxMutationsCompanion.insert(
        id: _uuid.v7(),
        entityType: OutboxEntityType.account,
        entityId: account.id,
        operation: operation,
        payloadJson: payload,
        createdAt: account.updatedAt.toUtc(),
      ),
    );
  }

  /// Convenience helper to enqueue a [LocalCategory] snapshot into the outbox.
  Future<void> enqueueCategoryMutation({
    required LocalCategory category,
    required String operation,
  }) {
    final payload = jsonEncode(<String, Object?>{
      'id': category.id,
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'is_wants': category.isWants,
      'created_at': category.createdAt.toUtc().toIso8601String(),
      'updated_at': category.updatedAt.toUtc().toIso8601String(),
      'deleted_at': category.deletedAt?.toUtc().toIso8601String(),
    });
    return enqueueMutation(
      LocalOutboxMutationsCompanion.insert(
        id: _uuid.v7(),
        entityType: OutboxEntityType.category,
        entityId: category.id,
        operation: operation,
        payloadJson: payload,
        createdAt: category.updatedAt.toUtc(),
      ),
    );
  }

  /// Convenience helper to enqueue a [LocalTransaction] snapshot into the outbox.
  Future<void> enqueueTransactionMutation({
    required LocalTransaction transactionRecord,
    required String operation,
  }) {
    final payload = jsonEncode(<String, Object?>{
      'id': transactionRecord.id,
      'account_id': transactionRecord.accountId,
      'category_id': transactionRecord.categoryId,
      'type': transactionRecord.type,
      'amount_minor': transactionRecord.amount.toString(),
      'currency': transactionRecord.currency,
      'exchange_rate_to_base': transactionRecord.exchangeRateToBase.toString(),
      'base_amount_minor': transactionRecord.baseAmount.toString(),
      'transaction_date':
          transactionRecord.transactionTime.toUtc().toIso8601String(),
      'note': transactionRecord.note,
      'created_at': transactionRecord.createdAt.toUtc().toIso8601String(),
      'updated_at': transactionRecord.updatedAt.toUtc().toIso8601String(),
      'deleted_at': transactionRecord.deletedAt?.toUtc().toIso8601String(),
    });
    return enqueueMutation(
      LocalOutboxMutationsCompanion.insert(
        id: _uuid.v7(),
        entityType: OutboxEntityType.transaction,
        entityId: transactionRecord.id,
        operation: operation,
        payloadJson: payload,
        createdAt: transactionRecord.updatedAt.toUtc(),
      ),
    );
  }

  /// Retrieves pending outbox mutations in chronological order (FIFO).
  Future<List<LocalOutboxMutation>> getPendingMutations({int limit = 50}) {
    return (select(localOutboxMutations)
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  /// Emits a live stream of total unsynced outbox items for UI indicators.
  Stream<int> watchPendingCount() {
    final countExpr = localOutboxMutations.id.count();
    final query = selectOnly(localOutboxMutations)..addColumns([countExpr]);
    return query.watchSingle().map((row) => row.read(countExpr) ?? 0);
  }

  /// Removes acknowledged mutations from the outbox queue in a batch.
  Future<int> deleteMutations(List<String> ids) {
    if (ids.isEmpty) {
      return Future<int>.value(0);
    }
    return (delete(localOutboxMutations)..where((t) => t.id.isIn(ids))).go();
  }

  /// Atomically increments [retryCount] and stores the latest sync [error] message.
  Future<void> incrementRetry(String id, String error) async {
    await (update(localOutboxMutations)..where((t) => t.id.equals(id))).write(
      LocalOutboxMutationsCompanion.custom(
        retryCount: localOutboxMutations.retryCount + const Constant(1),
        lastError: Variable<String>(error),
      ),
    );
  }
}
