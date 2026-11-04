import 'package:drift/drift.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/tables/accounts_table.dart';
import 'package:savoryx/core/database/tables/categories_table.dart';
import 'package:savoryx/core/database/tables/transactions_table.dart';

part 'fts_search_dao.g.dart';

class FtsSearchResultItem {
  const FtsSearchResultItem({
    required this.transaction,
    required this.rank,
  });

  final LocalTransaction transaction;
  final double rank;
}

@DriftAccessor(tables: [LocalTransactions, LocalAccounts, LocalCategories])
class FtsSearchDao extends DatabaseAccessor<AppDatabase>
    with _$FtsSearchDaoMixin {
  FtsSearchDao(super.db);

  static String sanitizeQuery(String rawQuery) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return '';

    // Split on whitespace and non-alphanumeric characters (except underscore)
    final tokens = trimmed
        .split(RegExp(r'[^\w]+'))
        .where((token) => token.isNotEmpty)
        .map((token) => token.replaceAll('"', ''))
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return '';

    // Wrap each token in double quotes followed by asterisk for prefix search
    return tokens.map((token) => '"$token"*').join(' ');
  }

  Future<List<LocalTransaction>> searchTransactions(
    String rawQuery, {
    int limit = 50,
    int offset = 0,
  }) async {
    final sanitized = sanitizeQuery(rawQuery);
    if (sanitized.isEmpty) {
      return const [];
    }

    final rows = await customSelect(
      '''
      SELECT t.*, bm25(transactions_fts) AS rank
      FROM transactions_fts f
      JOIN local_transactions t ON t.id = f.id
      WHERE transactions_fts MATCH ?
        AND t.deleted_at IS NULL
      ORDER BY rank ASC
      LIMIT ? OFFSET ?
      ''',
      variables: [
        Variable.withString(sanitized),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
      readsFrom: {localTransactions},
    ).get();

    return rows.map((row) => localTransactions.map(row.data)).toList();
  }

  /// Returns transactions along with their raw BM25 relevance score.
  Future<List<FtsSearchResultItem>> searchWithRank(
    String rawQuery, {
    int limit = 50,
    int offset = 0,
  }) async {
    final sanitized = sanitizeQuery(rawQuery);
    if (sanitized.isEmpty) {
      return const [];
    }

    final rows = await customSelect(
      '''
      SELECT t.*, bm25(transactions_fts) AS rank
      FROM transactions_fts f
      JOIN local_transactions t ON t.id = f.id
      WHERE transactions_fts MATCH ?
        AND t.deleted_at IS NULL
      ORDER BY rank ASC
      LIMIT ? OFFSET ?
      ''',
      variables: [
        Variable.withString(sanitized),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
      readsFrom: {localTransactions},
    ).get();

    return rows.map((row) {
      final transaction = localTransactions.map(row.data);
      final rank = row.read<double>('rank');
      return FtsSearchResultItem(transaction: transaction, rank: rank);
    }).toList();
  }

  /// Reactive stream for instant search UI updates.
  Stream<List<LocalTransaction>> watchSearchTransactions(
    String rawQuery, {
    int limit = 50,
  }) {
    final sanitized = sanitizeQuery(rawQuery);
    if (sanitized.isEmpty) {
      return Stream.value(const []);
    }

    return customSelect(
      '''
      SELECT t.*, bm25(transactions_fts) AS rank
      FROM transactions_fts f
      JOIN local_transactions t ON t.id = f.id
      WHERE transactions_fts MATCH ?
        AND t.deleted_at IS NULL
      ORDER BY rank ASC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(sanitized),
        Variable.withInt(limit),
      ],
      readsFrom: {localTransactions},
    ).watch().map((rows) {
      return rows.map((row) => localTransactions.map(row.data)).toList();
    });
  }
}
