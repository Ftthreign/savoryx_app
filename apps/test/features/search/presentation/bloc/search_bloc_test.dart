import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';
import 'package:savoryx/features/search/domain/repositories/search_repository.dart';
import 'package:savoryx/features/search/domain/usecases/search_transactions_usecase.dart';
import 'package:savoryx/features/search/presentation/bloc/search_bloc.dart';
import 'package:savoryx/features/search/presentation/bloc/search_event.dart';
import 'package:savoryx/features/search/presentation/bloc/search_state.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

class FakeSearchRepository implements SearchRepository {
  List<SearchResultEntity> resultsToReturn = [];
  bool shouldThrow = false;

  @override
  Future<List<SearchResultEntity>> searchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
    int offset = 0,
  }) async {
    if (shouldThrow) {
      throw Exception('FTS5 search engine error');
    }
    return resultsToReturn;
  }

  @override
  Stream<List<SearchResultEntity>> watchSearchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
  }) {
    return Stream.value(resultsToReturn);
  }
}

void main() {
  group('SearchBloc (Task #35 Multi-Currency & Search BLoC Domain Clean Architecture)', () {
    late FakeSearchRepository fakeRepository;
    late SearchTransactionsUseCase searchUseCase;

    final dummyTransaction = TransactionEntity(
      id: 'tx-001',
      accountId: 'acc-1',
      amount: 50000,
      type: TransactionType.expense,
      note: 'Kopi Kenangan #harian',
      transactionDate: DateTime.utc(2026, 11, 4),
      createdAt: DateTime.utc(2026, 11, 4),
      updatedAt: DateTime.utc(2026, 11, 4),
    );

    final dummyResult = SearchResultEntity(
      transaction: dummyTransaction,
      relevanceRank: -1.5,
    );

    setUp(() {
      fakeRepository = FakeSearchRepository();
      searchUseCase = SearchTransactionsUseCase(fakeRepository);
    });

    test('initial state is SearchInitial', () {
      final bloc = SearchBloc(searchTransactionsUseCase: searchUseCase);
      expect(bloc.state, equals(const SearchInitial()));
      bloc.close();
    });

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] when query returns matches after debounce',
      build: () {
        fakeRepository.resultsToReturn = [dummyResult];
        return SearchBloc(searchTransactionsUseCase: searchUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('kopi')),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const SearchLoading(),
        SearchLoaded(
          results: [dummyResult],
          query: 'kopi',
          filter: SearchFilterEntity.empty,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchEmpty] when query returns no matches',
      build: () {
        fakeRepository.resultsToReturn = [];
        return SearchBloc(searchTransactionsUseCase: searchUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('notfound')),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const SearchLoading(),
        const SearchEmpty(
          query: 'notfound',
          filter: SearchFilterEntity.empty,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] when compound filter is applied',
      build: () {
        fakeRepository.resultsToReturn = [dummyResult];
        return SearchBloc(searchTransactionsUseCase: searchUseCase);
      },
      act: (bloc) {
        bloc.add(const SearchFilterApplied(
          SearchFilterEntity(categoryIds: {'cat-food'}),
        ));
      },
      expect: () => [
        const SearchLoading(),
        SearchLoaded(
          results: [dummyResult],
          query: '',
          filter: const SearchFilterEntity(categoryIds: {'cat-food'}),
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits SearchInitial when SearchCleared event is received',
      build: () {
        return SearchBloc(searchTransactionsUseCase: searchUseCase);
      },
      seed: () => SearchLoaded(
        results: [dummyResult],
        query: 'kopi',
      ),
      act: (bloc) => bloc.add(const SearchCleared()),
      expect: () => [
        const SearchInitial(),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchFailure] when repository throws error',
      build: () {
        fakeRepository.shouldThrow = true;
        return SearchBloc(searchTransactionsUseCase: searchUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged('crash')),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const SearchLoading(),
        isA<SearchFailure>().having(
          (s) => s.message,
          'message',
          contains('FTS5 search engine error'),
        ),
      ],
    );
  });
}
