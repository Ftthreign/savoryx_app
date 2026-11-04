import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';
import 'package:savoryx/features/search/domain/repositories/search_repository.dart';
import 'package:savoryx/features/search/domain/usecases/search_transactions_usecase.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

class MockSearchRepository implements SearchRepository {
  String? lastQuery;
  SearchFilterEntity? lastFilter;
  int? lastLimit;
  int? lastOffset;

  final List<SearchResultEntity> mockResults = [
    SearchResultEntity(
      transaction: TransactionEntity(
        id: 'tx-1',
        accountId: 'acc-1',
        amount: 25000,
        type: TransactionType.expense,
        note: 'Bakso Malang #kuliner',
        transactionDate: DateTime.utc(2026, 11, 4),
        createdAt: DateTime.utc(2026, 11, 4),
        updatedAt: DateTime.utc(2026, 11, 4),
      ),
      relevanceRank: -2.3,
    ),
  ];

  @override
  Future<List<SearchResultEntity>> searchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
    int offset = 0,
  }) async {
    lastQuery = query;
    lastFilter = filter;
    lastLimit = limit;
    lastOffset = offset;
    return mockResults;
  }

  @override
  Stream<List<SearchResultEntity>> watchSearchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
  }) {
    return Stream.value(mockResults);
  }
}

void main() {
  group('SearchTransactionsUseCase (Task #35 Clean Architecture Use Cases)', () {
    late MockSearchRepository mockRepository;
    late SearchTransactionsUseCase useCase;

    setUp(() {
      mockRepository = MockSearchRepository();
      useCase = SearchTransactionsUseCase(mockRepository);
    });

    test('delegates query and filters to SearchRepository accurately', () async {
      const filter = SearchFilterEntity(categoryIds: {'cat-dining'});
      final results = await useCase(
        query: 'bakso',
        filter: filter,
        limit: 25,
        offset: 10,
      );

      expect(results, equals(mockRepository.mockResults));
      expect(mockRepository.lastQuery, equals('bakso'));
      expect(mockRepository.lastFilter, equals(filter));
      expect(mockRepository.lastLimit, equals(25));
      expect(mockRepository.lastOffset, equals(10));
    });

    test('watch delegates query to reactive stream in repository', () async {
      final stream = useCase.watch(query: 'bakso');
      await expectLater(stream, emits(mockRepository.mockResults));
    });
  });
}
