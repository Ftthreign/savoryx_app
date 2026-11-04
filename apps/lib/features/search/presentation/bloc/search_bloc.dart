import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/usecases/search_transactions_usecase.dart';
import 'package:savoryx/features/search/presentation/bloc/search_event.dart';
import 'package:savoryx/features/search/presentation/bloc/search_state.dart';

/// BLoC managing full-text and compound search state transitions with reactive debouncing.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchTransactionsUseCase searchTransactionsUseCase})
      : _searchTransactionsUseCase = searchTransactionsUseCase,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchFilterApplied>(_onFilterApplied);
    on<SearchCleared>(_onCleared);
  }

  final SearchTransactionsUseCase _searchTransactionsUseCase;
  Timer? _debounceTimer;
  String _currentQuery = '';
  SearchFilterEntity _currentFilter = SearchFilterEntity.empty;

  static const Duration debounceDuration = Duration(milliseconds: 150);

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentQuery = event.query;
    final completer = Completer<void>();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      completer.complete();
    });

    await completer.future;

    if (emit.isDone) return;
    await _executeSearch(emit);
  }

  Future<void> _onFilterApplied(
    SearchFilterApplied event,
    Emitter<SearchState> emit,
  ) async {
    _currentFilter = event.filter;
    await _executeSearch(emit);
  }

  void _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _currentFilter = SearchFilterEntity.empty;
    emit(const SearchInitial());
  }

  Future<void> _executeSearch(Emitter<SearchState> emit) async {
    final query = _currentQuery.trim();
    if (query.isEmpty && !_currentFilter.isActive) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());

    try {
      final results = await _searchTransactionsUseCase(
        query: query,
        filter: _currentFilter,
      );

      if (results.isEmpty) {
        emit(SearchEmpty(query: query, filter: _currentFilter));
      } else {
        emit(SearchLoaded(
          results: results,
          query: query,
          filter: _currentFilter,
        ));
      }
    } catch (e) {
      emit(SearchFailure(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
