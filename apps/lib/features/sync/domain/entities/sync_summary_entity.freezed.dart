// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_summary_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SyncSummaryEntity {
  int get pushedMutationsCount => throw _privateConstructorUsedError;
  int get pulledAccountsCount => throw _privateConstructorUsedError;
  int get pulledCategoriesCount => throw _privateConstructorUsedError;
  int get pulledTransactionsCount => throw _privateConstructorUsedError;
  DateTime get syncedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SyncSummaryEntityCopyWith<SyncSummaryEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncSummaryEntityCopyWith<$Res> {
  factory $SyncSummaryEntityCopyWith(
          SyncSummaryEntity value, $Res Function(SyncSummaryEntity) then) =
      _$SyncSummaryEntityCopyWithImpl<$Res, SyncSummaryEntity>;
  @useResult
  $Res call(
      {int pushedMutationsCount,
      int pulledAccountsCount,
      int pulledCategoriesCount,
      int pulledTransactionsCount,
      DateTime syncedAt});
}

/// @nodoc
class _$SyncSummaryEntityCopyWithImpl<$Res, $Val extends SyncSummaryEntity>
    implements $SyncSummaryEntityCopyWith<$Res> {
  _$SyncSummaryEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pushedMutationsCount = null,
    Object? pulledAccountsCount = null,
    Object? pulledCategoriesCount = null,
    Object? pulledTransactionsCount = null,
    Object? syncedAt = null,
  }) {
    return _then(_value.copyWith(
      pushedMutationsCount: null == pushedMutationsCount
          ? _value.pushedMutationsCount
          : pushedMutationsCount // ignore: cast_nullable_to_non_nullable
              as int,
      pulledAccountsCount: null == pulledAccountsCount
          ? _value.pulledAccountsCount
          : pulledAccountsCount // ignore: cast_nullable_to_non_nullable
              as int,
      pulledCategoriesCount: null == pulledCategoriesCount
          ? _value.pulledCategoriesCount
          : pulledCategoriesCount // ignore: cast_nullable_to_non_nullable
              as int,
      pulledTransactionsCount: null == pulledTransactionsCount
          ? _value.pulledTransactionsCount
          : pulledTransactionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      syncedAt: null == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncSummaryEntityImplCopyWith<$Res>
    implements $SyncSummaryEntityCopyWith<$Res> {
  factory _$$SyncSummaryEntityImplCopyWith(_$SyncSummaryEntityImpl value,
          $Res Function(_$SyncSummaryEntityImpl) then) =
      __$$SyncSummaryEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int pushedMutationsCount,
      int pulledAccountsCount,
      int pulledCategoriesCount,
      int pulledTransactionsCount,
      DateTime syncedAt});
}

/// @nodoc
class __$$SyncSummaryEntityImplCopyWithImpl<$Res>
    extends _$SyncSummaryEntityCopyWithImpl<$Res, _$SyncSummaryEntityImpl>
    implements _$$SyncSummaryEntityImplCopyWith<$Res> {
  __$$SyncSummaryEntityImplCopyWithImpl(_$SyncSummaryEntityImpl _value,
      $Res Function(_$SyncSummaryEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pushedMutationsCount = null,
    Object? pulledAccountsCount = null,
    Object? pulledCategoriesCount = null,
    Object? pulledTransactionsCount = null,
    Object? syncedAt = null,
  }) {
    return _then(_$SyncSummaryEntityImpl(
      pushedMutationsCount: null == pushedMutationsCount
          ? _value.pushedMutationsCount
          : pushedMutationsCount // ignore: cast_nullable_to_non_nullable
              as int,
      pulledAccountsCount: null == pulledAccountsCount
          ? _value.pulledAccountsCount
          : pulledAccountsCount // ignore: cast_nullable_to_non_nullable
              as int,
      pulledCategoriesCount: null == pulledCategoriesCount
          ? _value.pulledCategoriesCount
          : pulledCategoriesCount // ignore: cast_nullable_to_non_nullable
              as int,
      pulledTransactionsCount: null == pulledTransactionsCount
          ? _value.pulledTransactionsCount
          : pulledTransactionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      syncedAt: null == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$SyncSummaryEntityImpl implements _SyncSummaryEntity {
  const _$SyncSummaryEntityImpl(
      {required this.pushedMutationsCount,
      required this.pulledAccountsCount,
      required this.pulledCategoriesCount,
      required this.pulledTransactionsCount,
      required this.syncedAt});

  @override
  final int pushedMutationsCount;
  @override
  final int pulledAccountsCount;
  @override
  final int pulledCategoriesCount;
  @override
  final int pulledTransactionsCount;
  @override
  final DateTime syncedAt;

  @override
  String toString() {
    return 'SyncSummaryEntity(pushedMutationsCount: $pushedMutationsCount, pulledAccountsCount: $pulledAccountsCount, pulledCategoriesCount: $pulledCategoriesCount, pulledTransactionsCount: $pulledTransactionsCount, syncedAt: $syncedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncSummaryEntityImpl &&
            (identical(other.pushedMutationsCount, pushedMutationsCount) ||
                other.pushedMutationsCount == pushedMutationsCount) &&
            (identical(other.pulledAccountsCount, pulledAccountsCount) ||
                other.pulledAccountsCount == pulledAccountsCount) &&
            (identical(other.pulledCategoriesCount, pulledCategoriesCount) ||
                other.pulledCategoriesCount == pulledCategoriesCount) &&
            (identical(
                    other.pulledTransactionsCount, pulledTransactionsCount) ||
                other.pulledTransactionsCount == pulledTransactionsCount) &&
            (identical(other.syncedAt, syncedAt) ||
                other.syncedAt == syncedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      pushedMutationsCount,
      pulledAccountsCount,
      pulledCategoriesCount,
      pulledTransactionsCount,
      syncedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncSummaryEntityImplCopyWith<_$SyncSummaryEntityImpl> get copyWith =>
      __$$SyncSummaryEntityImplCopyWithImpl<_$SyncSummaryEntityImpl>(
          this, _$identity);
}

abstract class _SyncSummaryEntity implements SyncSummaryEntity {
  const factory _SyncSummaryEntity(
      {required final int pushedMutationsCount,
      required final int pulledAccountsCount,
      required final int pulledCategoriesCount,
      required final int pulledTransactionsCount,
      required final DateTime syncedAt}) = _$SyncSummaryEntityImpl;

  @override
  int get pushedMutationsCount;
  @override
  int get pulledAccountsCount;
  @override
  int get pulledCategoriesCount;
  @override
  int get pulledTransactionsCount;
  @override
  DateTime get syncedAt;
  @override
  @JsonKey(ignore: true)
  _$$SyncSummaryEntityImplCopyWith<_$SyncSummaryEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
