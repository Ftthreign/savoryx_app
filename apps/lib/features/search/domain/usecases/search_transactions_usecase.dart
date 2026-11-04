import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';
import 'package:savoryx/features/search/domain/repositories/search_repository.dart';

/// Single-responsibility business use case: search ledger transactions via FTS5 with compound filters.
class SearchTransactionsUseCase {
  const SearchTransactionsUseCase(this._searchRepository);

  final SearchRepository _searchRepository;

  Future<List<SearchResultEntity>> call({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
    int offset = 0,
  }) {
    return _searchRepository.searchTransactions(
      query: query,
      filter: filter,
      limit: limit,
      offset: offset,
    );
  }

  Stream<List<SearchResultEntity>> watch({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
  }) {
    return _searchRepository.watchSearchTransactions(
      query: query,
      filter: filter,
      limit: limit,
    );
  }
}
