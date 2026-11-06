import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_filter_entity.freezed.dart';

enum DateRangePreset {
  all,
  today,
  last7Days,
  thisMonth,
  custom;

  String get displayName {
    switch (this) {
      case DateRangePreset.all:
        return 'Semua';
      case DateRangePreset.today:
        return 'Hari Ini';
      case DateRangePreset.last7Days:
        return '7 Hari';
      case DateRangePreset.thisMonth:
        return 'Bulan Ini';
      case DateRangePreset.custom:
        return 'Kustom';
    }
  }
}

/// Immutable multi-criteria compound search filter specification.
@freezed
class SearchFilterEntity with _$SearchFilterEntity {
  const SearchFilterEntity._();

  const factory SearchFilterEntity({
    @Default(DateRangePreset.all) DateRangePreset datePreset,
    DateTime? customStartDate,
    DateTime? customEndDate,
    BigInt? minAmount,
    BigInt? maxAmount,
    @Default({}) Set<String> categoryIds,
    @Default({}) Set<String> accountIds,
    @Default({}) Set<String> transactionTypes,
    @Default({}) Set<String> tags,
  }) = _SearchFilterEntity;

  static const SearchFilterEntity empty = SearchFilterEntity();

  /// Whether any filter condition is active.
  bool get hasActiveFilter =>
      datePreset != DateRangePreset.all ||
      customStartDate != null ||
      customEndDate != null ||
      minAmount != null ||
      maxAmount != null ||
      categoryIds.isNotEmpty ||
      accountIds.isNotEmpty ||
      transactionTypes.isNotEmpty ||
      tags.isNotEmpty;

  /// Alias for [hasActiveFilter].
  bool get isActive => hasActiveFilter;

  /// Resolves the effective [DateTime] boundary based on preset or custom date range.
  (DateTime?, DateTime?) resolveEffectiveDateRange() {
    final now = DateTime.now().toUtc();
    switch (datePreset) {
      case DateRangePreset.all:
        return (null, null);
      case DateRangePreset.today:
        final start = DateTime.utc(now.year, now.month, now.day);
        final end = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case DateRangePreset.last7Days:
        final start = DateTime.utc(now.year, now.month, now.day).subtract(const Duration(days: 7));
        return (start, now);
      case DateRangePreset.thisMonth:
        final start = DateTime.utc(now.year, now.month, 1);
        final end = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return (start, end);
      case DateRangePreset.custom:
        return (customStartDate, customEndDate);
    }
  }
}
