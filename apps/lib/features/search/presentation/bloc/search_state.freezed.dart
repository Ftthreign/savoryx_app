// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SearchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)
        loaded,
    required TResult Function(String query, SearchFilterEntity filter) empty,
    required TResult Function(String message) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult? Function(String query, SearchFilterEntity filter)? empty,
    TResult? Function(String message)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult Function(String query, SearchFilterEntity filter)? empty,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchFailure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchStateCopyWith<$Res> {
  factory $SearchStateCopyWith(
          SearchState value, $Res Function(SearchState) then) =
      _$SearchStateCopyWithImpl<$Res, SearchState>;
}

/// @nodoc
class _$SearchStateCopyWithImpl<$Res, $Val extends SearchState>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$SearchInitialImplCopyWith<$Res> {
  factory _$$SearchInitialImplCopyWith(
          _$SearchInitialImpl value, $Res Function(_$SearchInitialImpl) then) =
      __$$SearchInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SearchInitialImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchInitialImpl>
    implements _$$SearchInitialImplCopyWith<$Res> {
  __$$SearchInitialImplCopyWithImpl(
      _$SearchInitialImpl _value, $Res Function(_$SearchInitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SearchInitialImpl implements SearchInitial {
  const _$SearchInitialImpl();

  @override
  String toString() {
    return 'SearchState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SearchInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)
        loaded,
    required TResult Function(String query, SearchFilterEntity filter) empty,
    required TResult Function(String message) failure,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult? Function(String query, SearchFilterEntity filter)? empty,
    TResult? Function(String message)? failure,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult Function(String query, SearchFilterEntity filter)? empty,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchFailure value) failure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchFailure value)? failure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class SearchInitial implements SearchState {
  const factory SearchInitial() = _$SearchInitialImpl;
}

/// @nodoc
abstract class _$$SearchLoadingImplCopyWith<$Res> {
  factory _$$SearchLoadingImplCopyWith(
          _$SearchLoadingImpl value, $Res Function(_$SearchLoadingImpl) then) =
      __$$SearchLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SearchLoadingImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchLoadingImpl>
    implements _$$SearchLoadingImplCopyWith<$Res> {
  __$$SearchLoadingImplCopyWithImpl(
      _$SearchLoadingImpl _value, $Res Function(_$SearchLoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SearchLoadingImpl implements SearchLoading {
  const _$SearchLoadingImpl();

  @override
  String toString() {
    return 'SearchState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SearchLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)
        loaded,
    required TResult Function(String query, SearchFilterEntity filter) empty,
    required TResult Function(String message) failure,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult? Function(String query, SearchFilterEntity filter)? empty,
    TResult? Function(String message)? failure,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult Function(String query, SearchFilterEntity filter)? empty,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class SearchLoading implements SearchState {
  const factory SearchLoading() = _$SearchLoadingImpl;
}

/// @nodoc
abstract class _$$SearchLoadedImplCopyWith<$Res> {
  factory _$$SearchLoadedImplCopyWith(
          _$SearchLoadedImpl value, $Res Function(_$SearchLoadedImpl) then) =
      __$$SearchLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<SearchResultEntity> results,
      SearchFilterEntity filter,
      String query});

  $SearchFilterEntityCopyWith<$Res> get filter;
}

/// @nodoc
class __$$SearchLoadedImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchLoadedImpl>
    implements _$$SearchLoadedImplCopyWith<$Res> {
  __$$SearchLoadedImplCopyWithImpl(
      _$SearchLoadedImpl _value, $Res Function(_$SearchLoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? filter = null,
    Object? query = null,
  }) {
    return _then(_$SearchLoadedImpl(
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<SearchResultEntity>,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as SearchFilterEntity,
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $SearchFilterEntityCopyWith<$Res> get filter {
    return $SearchFilterEntityCopyWith<$Res>(_value.filter, (value) {
      return _then(_value.copyWith(filter: value));
    });
  }
}

/// @nodoc

class _$SearchLoadedImpl implements SearchLoaded {
  const _$SearchLoadedImpl(
      {required final List<SearchResultEntity> results,
      this.filter = SearchFilterEntity.empty,
      this.query = ''})
      : _results = results;

  final List<SearchResultEntity> _results;
  @override
  List<SearchResultEntity> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  @JsonKey()
  final SearchFilterEntity filter;
  @override
  @JsonKey()
  final String query;

  @override
  String toString() {
    return 'SearchState.loaded(results: $results, filter: $filter, query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchLoadedImpl &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_results), filter, query);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchLoadedImplCopyWith<_$SearchLoadedImpl> get copyWith =>
      __$$SearchLoadedImplCopyWithImpl<_$SearchLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)
        loaded,
    required TResult Function(String query, SearchFilterEntity filter) empty,
    required TResult Function(String message) failure,
  }) {
    return loaded(results, filter, query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult? Function(String query, SearchFilterEntity filter)? empty,
    TResult? Function(String message)? failure,
  }) {
    return loaded?.call(results, filter, query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult Function(String query, SearchFilterEntity filter)? empty,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(results, filter, query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchFailure value) failure,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchFailure value)? failure,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class SearchLoaded implements SearchState {
  const factory SearchLoaded(
      {required final List<SearchResultEntity> results,
      final SearchFilterEntity filter,
      final String query}) = _$SearchLoadedImpl;

  List<SearchResultEntity> get results;
  SearchFilterEntity get filter;
  String get query;
  @JsonKey(ignore: true)
  _$$SearchLoadedImplCopyWith<_$SearchLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchEmptyImplCopyWith<$Res> {
  factory _$$SearchEmptyImplCopyWith(
          _$SearchEmptyImpl value, $Res Function(_$SearchEmptyImpl) then) =
      __$$SearchEmptyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query, SearchFilterEntity filter});

  $SearchFilterEntityCopyWith<$Res> get filter;
}

/// @nodoc
class __$$SearchEmptyImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchEmptyImpl>
    implements _$$SearchEmptyImplCopyWith<$Res> {
  __$$SearchEmptyImplCopyWithImpl(
      _$SearchEmptyImpl _value, $Res Function(_$SearchEmptyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? filter = null,
  }) {
    return _then(_$SearchEmptyImpl(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as SearchFilterEntity,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $SearchFilterEntityCopyWith<$Res> get filter {
    return $SearchFilterEntityCopyWith<$Res>(_value.filter, (value) {
      return _then(_value.copyWith(filter: value));
    });
  }
}

/// @nodoc

class _$SearchEmptyImpl implements SearchEmpty {
  const _$SearchEmptyImpl(
      {this.query = '', this.filter = SearchFilterEntity.empty});

  @override
  @JsonKey()
  final String query;
  @override
  @JsonKey()
  final SearchFilterEntity filter;

  @override
  String toString() {
    return 'SearchState.empty(query: $query, filter: $filter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchEmptyImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.filter, filter) || other.filter == filter));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query, filter);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchEmptyImplCopyWith<_$SearchEmptyImpl> get copyWith =>
      __$$SearchEmptyImplCopyWithImpl<_$SearchEmptyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)
        loaded,
    required TResult Function(String query, SearchFilterEntity filter) empty,
    required TResult Function(String message) failure,
  }) {
    return empty(query, filter);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult? Function(String query, SearchFilterEntity filter)? empty,
    TResult? Function(String message)? failure,
  }) {
    return empty?.call(query, filter);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult Function(String query, SearchFilterEntity filter)? empty,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(query, filter);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchFailure value) failure,
  }) {
    return empty(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchFailure value)? failure,
  }) {
    return empty?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(this);
    }
    return orElse();
  }
}

abstract class SearchEmpty implements SearchState {
  const factory SearchEmpty(
      {final String query,
      final SearchFilterEntity filter}) = _$SearchEmptyImpl;

  String get query;
  SearchFilterEntity get filter;
  @JsonKey(ignore: true)
  _$$SearchEmptyImplCopyWith<_$SearchEmptyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchFailureImplCopyWith<$Res> {
  factory _$$SearchFailureImplCopyWith(
          _$SearchFailureImpl value, $Res Function(_$SearchFailureImpl) then) =
      __$$SearchFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SearchFailureImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchFailureImpl>
    implements _$$SearchFailureImplCopyWith<$Res> {
  __$$SearchFailureImplCopyWithImpl(
      _$SearchFailureImpl _value, $Res Function(_$SearchFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$SearchFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SearchFailureImpl implements SearchFailure {
  const _$SearchFailureImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'SearchState.failure(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchFailureImplCopyWith<_$SearchFailureImpl> get copyWith =>
      __$$SearchFailureImplCopyWithImpl<_$SearchFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)
        loaded,
    required TResult Function(String query, SearchFilterEntity filter) empty,
    required TResult Function(String message) failure,
  }) {
    return failure(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult? Function(String query, SearchFilterEntity filter)? empty,
    TResult? Function(String message)? failure,
  }) {
    return failure?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<SearchResultEntity> results,
            SearchFilterEntity filter, String query)?
        loaded,
    TResult Function(String query, SearchFilterEntity filter)? empty,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchInitial value) initial,
    required TResult Function(SearchLoading value) loading,
    required TResult Function(SearchLoaded value) loaded,
    required TResult Function(SearchEmpty value) empty,
    required TResult Function(SearchFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchInitial value)? initial,
    TResult? Function(SearchLoading value)? loading,
    TResult? Function(SearchLoaded value)? loaded,
    TResult? Function(SearchEmpty value)? empty,
    TResult? Function(SearchFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchInitial value)? initial,
    TResult Function(SearchLoading value)? loading,
    TResult Function(SearchLoaded value)? loaded,
    TResult Function(SearchEmpty value)? empty,
    TResult Function(SearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class SearchFailure implements SearchState {
  const factory SearchFailure({required final String message}) =
      _$SearchFailureImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$SearchFailureImplCopyWith<_$SearchFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
