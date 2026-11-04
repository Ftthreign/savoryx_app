import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';
import 'package:savoryx/features/search/domain/repositories/search_repository.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<SearchResultEntity>> searchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
    int offset = 0,
  }) async {
    final trimmedQuery = query.trim();

    final List<SearchResultEntity> rawResults;
    if (trimmedQuery.isNotEmpty) {
      final ftsItems = await _db.ftsSearchDao.searchWithRank(
        trimmedQuery,
        limit: limit * 2,
        offset: offset,
      );
      rawResults = ftsItems.map((item) {
        return SearchResultEntity(
          transaction: _mapToEntity(item.transaction),
          relevanceRank: item.rank,
        );
      }).toList();
    } else {
      final recentRecords = await _db.transactionDao.getRecentTransactions(
        limit: limit * 2,
        offset: offset,
      );
      rawResults = recentRecords.map((record) {
        return SearchResultEntity(
          transaction: _mapToEntity(record),
          relevanceRank: 0.0,
        );
      }).toList();
    }

    final filtered = rawResults
        .where((result) {
          return _matchesFilter(result.transaction, filter);
        })
        .take(limit)
        .toList();

    return filtered;
  }

  @override
  Stream<List<SearchResultEntity>> watchSearchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      return _db.ftsSearchDao
          .watchSearchTransactions(trimmedQuery, limit: limit * 2)
          .map((records) {
        return records
            .map((r) => SearchResultEntity(transaction: _mapToEntity(r)))
            .where((res) => _matchesFilter(res.transaction, filter))
            .take(limit)
            .toList();
      });
    }

    return _db.transactionDao
        .watchRecentTransactions(limit: limit * 2)
        .map((records) {
      return records
          .map((r) => SearchResultEntity(transaction: _mapToEntity(r)))
          .where((res) => _matchesFilter(res.transaction, filter))
          .take(limit)
          .toList();
    });
  }

  bool _matchesFilter(TransactionEntity tx, SearchFilterEntity filter) {
    if (filter.categoryIds.isNotEmpty) {
      if (tx.categoryId == null ||
          !filter.categoryIds.contains(tx.categoryId)) {
        return false;
      }
    }

    if (filter.accountIds.isNotEmpty) {
      if (!filter.accountIds.contains(tx.accountId)) {
        return false;
      }
    }

    final txAmountBigInt = BigInt.from(tx.amount);
    if (filter.minAmount != null && txAmountBigInt < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && txAmountBigInt > filter.maxAmount!) {
      return false;
    }

    final (startDate, endDate) = filter.resolveEffectiveDateRange();
    if (startDate != null && tx.transactionDate.isBefore(startDate)) {
      return false;
    }
    if (endDate != null && tx.transactionDate.isAfter(endDate)) {
      return false;
    }

    if (filter.transactionTypes.isNotEmpty) {
      if (!filter.transactionTypes.contains(tx.type.name)) {
        return false;
      }
    }

    if (filter.tags.isNotEmpty) {
      final noteLower = tx.note.toLowerCase();
      final hasMatchingTag = filter.tags.any((tag) {
        final cleanTag = tag.toLowerCase().replaceAll('#', '');
        return noteLower.contains('#$cleanTag');
      });
      if (!hasMatchingTag) {
        return false;
      }
    }

    return true;
  }

  TransactionEntity _mapToEntity(LocalTransaction tx) {
    return TransactionEntity(
      id: tx.id,
      accountId: tx.accountId,
      categoryId: tx.categoryId,
      amount:
          tx.amount.isValidInt ? tx.amount.toInt() : tx.amount.abs().toInt(),
      type: TransactionType.fromString(tx.type),
      note: tx.note ?? '',
      currency: tx.currency,
      exchangeRateToBase: tx.exchangeRateToBase,
      baseAmount: tx.baseAmount,
      transactionDate: tx.transactionTime,
      isSynced: tx.isSynced,
      createdAt: tx.createdAt,
      updatedAt: tx.updatedAt,
      deletedAt: tx.deletedAt,
    );
  }
}
