import 'package:equatable/equatable.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SearchFilterApplied extends SearchEvent {
  const SearchFilterApplied(this.filter);

  final SearchFilterEntity filter;

  @override
  List<Object?> get props => [filter];
}

final class SearchCleared extends SearchEvent {
  const SearchCleared();
}
