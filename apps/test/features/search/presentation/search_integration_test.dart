import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';
import 'package:savoryx/features/search/domain/repositories/search_repository.dart';
import 'package:savoryx/features/search/domain/usecases/search_transactions_usecase.dart';
import 'package:savoryx/features/search/presentation/bloc/search_bloc.dart';
import 'package:savoryx/features/search/presentation/bloc/search_event.dart';
import 'package:savoryx/features/search/presentation/bloc/search_state.dart';
import 'package:savoryx/features/search/presentation/widgets/search_result_tile.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

class MockSearchRepository implements SearchRepository {
  List<SearchResultEntity> mockResults = [];

  @override
  Future<List<SearchResultEntity>> searchTransactions({
    required String query,
    SearchFilterEntity filter = SearchFilterEntity.empty,
    int limit = 50,
    int offset = 0,
  }) async {
    return mockResults.where((r) {
      final matchesQuery = query.isEmpty ||
          r.transaction.note.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = filter.categoryIds.isEmpty ||
          (r.transaction.categoryId != null &&
              filter.categoryIds.contains(r.transaction.categoryId));
      return matchesQuery && matchesCategory;
    }).toList();
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
  group('Sprint 3 Frontend Integration Tests (Task #36 [Flutter])', () {
    late MockSearchRepository mockRepo;
    late SearchTransactionsUseCase searchUseCase;

    final usdTransaction = TransactionEntity(
      id: 'tx-usd-1',
      accountId: 'acc-usd',
      categoryId: 'cat-sub',
      amount: 15, // $15 USD
      currency: 'USD',
      exchangeRateToBase: BigInt.from(16250000000), // Scaled 10^6 (16,250 IDR/USD)
      baseAmount: BigInt.from(243750), // Rp 243,750
      type: TransactionType.expense,
      note: 'Figma Pro Team Subscription #software',
      transactionDate: DateTime.utc(2026, 11, 4, 10, 30),
      createdAt: DateTime.utc(2026, 11, 4, 10, 30),
      updatedAt: DateTime.utc(2026, 11, 4, 10, 30),
    );

    final idrTransaction = TransactionEntity(
      id: 'tx-idr-1',
      accountId: 'acc-gopay',
      categoryId: 'cat-food',
      amount: 38000,
      currency: 'IDR',
      type: TransactionType.expense,
      note: 'Kopi Kenangan Senopati #coffee',
      transactionDate: DateTime.utc(2026, 11, 4, 9, 0),
      createdAt: DateTime.utc(2026, 11, 4, 9, 0),
      updatedAt: DateTime.utc(2026, 11, 4, 9, 0),
    );

    setUp(() {
      mockRepo = MockSearchRepository();
      mockRepo.mockResults = [
        SearchResultEntity(
          transaction: usdTransaction,
          relevanceRank: -2.4,
          matchedSnippet: 'Figma Pro Team Subscription',
        ),
        SearchResultEntity(
          transaction: idrTransaction,
          relevanceRank: -1.2,
          matchedSnippet: 'Kopi Kenangan Senopati',
        ),
      ];
      searchUseCase = SearchTransactionsUseCase(mockRepo);
    });

    testWidgets('SearchResultTile renders dual-currency foreign transaction accurately',
        (tester) async {
      final searchResult = SearchResultEntity(
        transaction: usdTransaction,
        relevanceRank: -2.4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile.fromEntity(
              result: searchResult,
              highlightQuery: 'Figma',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Native currency amount formatted with $ prefix
      expect(find.text(r'-$15'), findsOneWidget);

      // Base currency equivalent display: ≈ Rp 243.750
      expect(find.textContaining('243.750'), findsOneWidget);

      // Note display with highlighted keyword
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Figma Pro Team Subscription'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('SearchBloc integration with debouncing and keyword filtering',
        (tester) async {
      final searchBloc = SearchBloc(searchTransactionsUseCase: searchUseCase);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SearchBloc>.value(
            value: searchBloc,
            child: Scaffold(
              body: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const Text('Initial State'),
                    loading: () => const CircularProgressIndicator(),
                    loaded: (results, _, __) => ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (ctx, i) =>
                          Text(results[i].transaction.note),
                    ),
                    empty: (_, __) => const Text('No Results Found'),
                    failure: (message) => Text('Error: $message'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Initial State'), findsOneWidget);

      // Trigger search query
      searchBloc.add(const SearchQueryChanged('Figma'));

      // Before debounce time elapses
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Initial State'), findsOneWidget);

      // Settle past the 150ms debounce threshold
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump();

      // Loaded state with filtered Figma transaction
      expect(find.textContaining('Figma Pro Team Subscription'), findsOneWidget);
      expect(find.textContaining('Kopi Kenangan'), findsNothing);

      await searchBloc.close();
    });

    testWidgets('Compound search filter isolates transactions by category and query',
        (tester) async {
      final searchBloc = SearchBloc(searchTransactionsUseCase: searchUseCase);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SearchBloc>.value(
            value: searchBloc,
            child: Scaffold(
              body: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoaded) {
                    return Text('Count: ${state.results.length}');
                  }
                  return const Text('Not Loaded');
                },
              ),
            ),
          ),
        ),
      );

      // Apply filter for cat-food
      searchBloc.add(const SearchFilterApplied(
        SearchFilterEntity(categoryIds: {'cat-food'}),
      ));

      await tester.pump();
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);

      await searchBloc.close();
    });
  });
}
