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
class SearchFilterEntity {
  const SearchFilterEntity({
    this.datePreset = DateRangePreset.all,
    this.customStartDate,
    this.customEndDate,
    this.minAmount,
    this.maxAmount,
    this.categoryIds = const {},
    this.accountIds = const {},
    this.transactionTypes = const {},
    this.tags = const {},
  });

  final DateRangePreset datePreset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final BigInt? minAmount;
  final BigInt? maxAmount;
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final Set<String> transactionTypes;
  final Set<String> tags;

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

  SearchFilterEntity copyWith({
    DateRangePreset? datePreset,
    DateTime? customStartDate,
    DateTime? customEndDate,
    BigInt? minAmount,
    BigInt? maxAmount,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    Set<String>? transactionTypes,
    Set<String>? tags,
  }) {
    return SearchFilterEntity(
      datePreset: datePreset ?? this.datePreset,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      transactionTypes: transactionTypes ?? this.transactionTypes,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilterEntity &&
        other.datePreset == datePreset &&
        other.customStartDate == customStartDate &&
        other.customEndDate == customEndDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        _setEquals(other.categoryIds, categoryIds) &&
        _setEquals(other.accountIds, accountIds) &&
        _setEquals(other.transactionTypes, transactionTypes) &&
        _setEquals(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(
        datePreset,
        customStartDate,
        customEndDate,
        minAmount,
        maxAmount,
        Object.hashAll(categoryIds),
        Object.hashAll(accountIds),
        Object.hashAll(transactionTypes),
        Object.hashAll(tags),
      );

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
