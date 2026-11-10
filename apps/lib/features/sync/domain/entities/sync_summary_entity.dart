import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_summary_entity.freezed.dart';

/// Immutable summary metadata of a completed two-way delta sync cycle.
@freezed
class SyncSummaryEntity with _$SyncSummaryEntity {
  const factory SyncSummaryEntity({
    required int pushedMutationsCount,
    required int pulledAccountsCount,
    required int pulledCategoriesCount,
    required int pulledTransactionsCount,
    required DateTime syncedAt,
  }) = _SyncSummaryEntity;
}
