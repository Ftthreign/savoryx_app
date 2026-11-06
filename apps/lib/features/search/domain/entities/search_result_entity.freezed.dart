// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SearchResultEntity {
  TransactionEntity get transaction => throw _privateConstructorUsedError;
  double get relevanceRank => throw _privateConstructorUsedError;
  String? get matchedSnippet => throw _privateConstructorUsedError;
  List<String> get matchedFields => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SearchResultEntityCopyWith<SearchResultEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultEntityCopyWith<$Res> {
  factory $SearchResultEntityCopyWith(
          SearchResultEntity value, $Res Function(SearchResultEntity) then) =
      _$SearchResultEntityCopyWithImpl<$Res, SearchResultEntity>;
  @useResult
  $Res call(
      {TransactionEntity transaction,
      double relevanceRank,
      String? matchedSnippet,
      List<String> matchedFields});

  $TransactionEntityCopyWith<$Res> get transaction;
}

/// @nodoc
class _$SearchResultEntityCopyWithImpl<$Res, $Val extends SearchResultEntity>
    implements $SearchResultEntityCopyWith<$Res> {
  _$SearchResultEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transaction = null,
    Object? relevanceRank = null,
    Object? matchedSnippet = freezed,
    Object? matchedFields = null,
  }) {
    return _then(_value.copyWith(
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as TransactionEntity,
      relevanceRank: null == relevanceRank
          ? _value.relevanceRank
          : relevanceRank // ignore: cast_nullable_to_non_nullable
              as double,
      matchedSnippet: freezed == matchedSnippet
          ? _value.matchedSnippet
          : matchedSnippet // ignore: cast_nullable_to_non_nullable
              as String?,
      matchedFields: null == matchedFields
          ? _value.matchedFields
          : matchedFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TransactionEntityCopyWith<$Res> get transaction {
    return $TransactionEntityCopyWith<$Res>(_value.transaction, (value) {
      return _then(_value.copyWith(transaction: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SearchResultEntityImplCopyWith<$Res>
    implements $SearchResultEntityCopyWith<$Res> {
  factory _$$SearchResultEntityImplCopyWith(_$SearchResultEntityImpl value,
          $Res Function(_$SearchResultEntityImpl) then) =
      __$$SearchResultEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TransactionEntity transaction,
      double relevanceRank,
      String? matchedSnippet,
      List<String> matchedFields});

  @override
  $TransactionEntityCopyWith<$Res> get transaction;
}

/// @nodoc
class __$$SearchResultEntityImplCopyWithImpl<$Res>
    extends _$SearchResultEntityCopyWithImpl<$Res, _$SearchResultEntityImpl>
    implements _$$SearchResultEntityImplCopyWith<$Res> {
  __$$SearchResultEntityImplCopyWithImpl(_$SearchResultEntityImpl _value,
      $Res Function(_$SearchResultEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transaction = null,
    Object? relevanceRank = null,
    Object? matchedSnippet = freezed,
    Object? matchedFields = null,
  }) {
    return _then(_$SearchResultEntityImpl(
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as TransactionEntity,
      relevanceRank: null == relevanceRank
          ? _value.relevanceRank
          : relevanceRank // ignore: cast_nullable_to_non_nullable
              as double,
      matchedSnippet: freezed == matchedSnippet
          ? _value.matchedSnippet
          : matchedSnippet // ignore: cast_nullable_to_non_nullable
              as String?,
      matchedFields: null == matchedFields
          ? _value._matchedFields
          : matchedFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$SearchResultEntityImpl implements _SearchResultEntity {
  const _$SearchResultEntityImpl(
      {required this.transaction,
      this.relevanceRank = 0.0,
      this.matchedSnippet,
      final List<String> matchedFields = const []})
      : _matchedFields = matchedFields;

  @override
  final TransactionEntity transaction;
  @override
  @JsonKey()
  final double relevanceRank;
  @override
  final String? matchedSnippet;
  final List<String> _matchedFields;
  @override
  @JsonKey()
  List<String> get matchedFields {
    if (_matchedFields is EqualUnmodifiableListView) return _matchedFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matchedFields);
  }

  @override
  String toString() {
    return 'SearchResultEntity(transaction: $transaction, relevanceRank: $relevanceRank, matchedSnippet: $matchedSnippet, matchedFields: $matchedFields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResultEntityImpl &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.relevanceRank, relevanceRank) ||
                other.relevanceRank == relevanceRank) &&
            (identical(other.matchedSnippet, matchedSnippet) ||
                other.matchedSnippet == matchedSnippet) &&
            const DeepCollectionEquality()
                .equals(other._matchedFields, _matchedFields));
  }

  @override
  int get hashCode => Object.hash(runtimeType, transaction, relevanceRank,
      matchedSnippet, const DeepCollectionEquality().hash(_matchedFields));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResultEntityImplCopyWith<_$SearchResultEntityImpl> get copyWith =>
      __$$SearchResultEntityImplCopyWithImpl<_$SearchResultEntityImpl>(
          this, _$identity);
}

abstract class _SearchResultEntity implements SearchResultEntity {
  const factory _SearchResultEntity(
      {required final TransactionEntity transaction,
      final double relevanceRank,
      final String? matchedSnippet,
      final List<String> matchedFields}) = _$SearchResultEntityImpl;

  @override
  TransactionEntity get transaction;
  @override
  double get relevanceRank;
  @override
  String? get matchedSnippet;
  @override
  List<String> get matchedFields;
  @override
  @JsonKey(ignore: true)
  _$$SearchResultEntityImplCopyWith<_$SearchResultEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
