import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';

abstract interface class SearchRepository {
  Future<List<SearchResultEntity>> searchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
    int offset = 0,
  });

  Stream<List<SearchResultEntity>> watchSearchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
  });
}
