import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/domain/entities/search_result_entity.dart';

part 'search_state.freezed.dart';

@freezed
class SearchState with _$SearchState {
  const factory SearchState.initial() = SearchInitial;
  const factory SearchState.loading() = SearchLoading;
  const factory SearchState.loaded({
    required List<SearchResultEntity> results,
    @Default(SearchFilterEntity.empty) SearchFilterEntity filter,
    @Default('') String query,
  }) = SearchLoaded;
  const factory SearchState.empty({
    @Default('') String query,
    @Default(SearchFilterEntity.empty) SearchFilterEntity filter,
  }) = SearchEmpty;
  const factory SearchState.failure({
    required String message,
  }) = SearchFailure;
}
