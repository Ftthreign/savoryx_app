import 'package:equatable/equatable.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchLoaded extends SearchState {
  const SearchLoaded({
    required this.results,
    this.filter = SearchFilterEntity.empty,
    this.query = '',
  });

  final List<SearchResultEntity> results;
  final SearchFilterEntity filter;
  final String query;

  @override
  List<Object?> get props => [results, filter, query];
}

final class SearchEmpty extends SearchState {
  const SearchEmpty({
    this.query = '',
    this.filter = SearchFilterEntity.empty,
  });

  final String query;
  final SearchFilterEntity filter;

  @override
  List<Object?> get props => [query, filter];
}

final class SearchFailure extends SearchState {
  const SearchFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
