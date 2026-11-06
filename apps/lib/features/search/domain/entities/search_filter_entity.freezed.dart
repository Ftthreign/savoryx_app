// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filter_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SearchFilterEntity {
  DateRangePreset get datePreset => throw _privateConstructorUsedError;
  DateTime? get customStartDate => throw _privateConstructorUsedError;
  DateTime? get customEndDate => throw _privateConstructorUsedError;
  BigInt? get minAmount => throw _privateConstructorUsedError;
  BigInt? get maxAmount => throw _privateConstructorUsedError;
  Set<String> get categoryIds => throw _privateConstructorUsedError;
  Set<String> get accountIds => throw _privateConstructorUsedError;
  Set<String> get transactionTypes => throw _privateConstructorUsedError;
  Set<String> get tags => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SearchFilterEntityCopyWith<SearchFilterEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchFilterEntityCopyWith<$Res> {
  factory $SearchFilterEntityCopyWith(
          SearchFilterEntity value, $Res Function(SearchFilterEntity) then) =
      _$SearchFilterEntityCopyWithImpl<$Res, SearchFilterEntity>;
  @useResult
  $Res call(
      {DateRangePreset datePreset,
      DateTime? customStartDate,
      DateTime? customEndDate,
      BigInt? minAmount,
      BigInt? maxAmount,
      Set<String> categoryIds,
      Set<String> accountIds,
      Set<String> transactionTypes,
      Set<String> tags});
}

/// @nodoc
class _$SearchFilterEntityCopyWithImpl<$Res, $Val extends SearchFilterEntity>
    implements $SearchFilterEntityCopyWith<$Res> {
  _$SearchFilterEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? datePreset = null,
    Object? customStartDate = freezed,
    Object? customEndDate = freezed,
    Object? minAmount = freezed,
    Object? maxAmount = freezed,
    Object? categoryIds = null,
    Object? accountIds = null,
    Object? transactionTypes = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      datePreset: null == datePreset
          ? _value.datePreset
          : datePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      customStartDate: freezed == customStartDate
          ? _value.customStartDate
          : customStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      customEndDate: freezed == customEndDate
          ? _value.customEndDate
          : customEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      minAmount: freezed == minAmount
          ? _value.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      maxAmount: freezed == maxAmount
          ? _value.maxAmount
          : maxAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      categoryIds: null == categoryIds
          ? _value.categoryIds
          : categoryIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      accountIds: null == accountIds
          ? _value.accountIds
          : accountIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      transactionTypes: null == transactionTypes
          ? _value.transactionTypes
          : transactionTypes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchFilterEntityImplCopyWith<$Res>
    implements $SearchFilterEntityCopyWith<$Res> {
  factory _$$SearchFilterEntityImplCopyWith(_$SearchFilterEntityImpl value,
          $Res Function(_$SearchFilterEntityImpl) then) =
      __$$SearchFilterEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateRangePreset datePreset,
      DateTime? customStartDate,
      DateTime? customEndDate,
      BigInt? minAmount,
      BigInt? maxAmount,
      Set<String> categoryIds,
      Set<String> accountIds,
      Set<String> transactionTypes,
      Set<String> tags});
}

/// @nodoc
class __$$SearchFilterEntityImplCopyWithImpl<$Res>
    extends _$SearchFilterEntityCopyWithImpl<$Res, _$SearchFilterEntityImpl>
    implements _$$SearchFilterEntityImplCopyWith<$Res> {
  __$$SearchFilterEntityImplCopyWithImpl(_$SearchFilterEntityImpl _value,
      $Res Function(_$SearchFilterEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? datePreset = null,
    Object? customStartDate = freezed,
    Object? customEndDate = freezed,
    Object? minAmount = freezed,
    Object? maxAmount = freezed,
    Object? categoryIds = null,
    Object? accountIds = null,
    Object? transactionTypes = null,
    Object? tags = null,
  }) {
    return _then(_$SearchFilterEntityImpl(
      datePreset: null == datePreset
          ? _value.datePreset
          : datePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      customStartDate: freezed == customStartDate
          ? _value.customStartDate
          : customStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      customEndDate: freezed == customEndDate
          ? _value.customEndDate
          : customEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      minAmount: freezed == minAmount
          ? _value.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      maxAmount: freezed == maxAmount
          ? _value.maxAmount
          : maxAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      categoryIds: null == categoryIds
          ? _value._categoryIds
          : categoryIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      accountIds: null == accountIds
          ? _value._accountIds
          : accountIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      transactionTypes: null == transactionTypes
          ? _value._transactionTypes
          : transactionTypes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$SearchFilterEntityImpl extends _SearchFilterEntity {
  const _$SearchFilterEntityImpl(
      {this.datePreset = DateRangePreset.all,
      this.customStartDate,
      this.customEndDate,
      this.minAmount,
      this.maxAmount,
      final Set<String> categoryIds = const {},
      final Set<String> accountIds = const {},
      final Set<String> transactionTypes = const {},
      final Set<String> tags = const {}})
      : _categoryIds = categoryIds,
        _accountIds = accountIds,
        _transactionTypes = transactionTypes,
        _tags = tags,
        super._();

  @override
  @JsonKey()
  final DateRangePreset datePreset;
  @override
  final DateTime? customStartDate;
  @override
  final DateTime? customEndDate;
  @override
  final BigInt? minAmount;
  @override
  final BigInt? maxAmount;
  final Set<String> _categoryIds;
  @override
  @JsonKey()
  Set<String> get categoryIds {
    if (_categoryIds is EqualUnmodifiableSetView) return _categoryIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_categoryIds);
  }

  final Set<String> _accountIds;
  @override
  @JsonKey()
  Set<String> get accountIds {
    if (_accountIds is EqualUnmodifiableSetView) return _accountIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_accountIds);
  }

  final Set<String> _transactionTypes;
  @override
  @JsonKey()
  Set<String> get transactionTypes {
    if (_transactionTypes is EqualUnmodifiableSetView) return _transactionTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_transactionTypes);
  }

  final Set<String> _tags;
  @override
  @JsonKey()
  Set<String> get tags {
    if (_tags is EqualUnmodifiableSetView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_tags);
  }

  @override
  String toString() {
    return 'SearchFilterEntity(datePreset: $datePreset, customStartDate: $customStartDate, customEndDate: $customEndDate, minAmount: $minAmount, maxAmount: $maxAmount, categoryIds: $categoryIds, accountIds: $accountIds, transactionTypes: $transactionTypes, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchFilterEntityImpl &&
            (identical(other.datePreset, datePreset) ||
                other.datePreset == datePreset) &&
            (identical(other.customStartDate, customStartDate) ||
                other.customStartDate == customStartDate) &&
            (identical(other.customEndDate, customEndDate) ||
                other.customEndDate == customEndDate) &&
            (identical(other.minAmount, minAmount) ||
                other.minAmount == minAmount) &&
            (identical(other.maxAmount, maxAmount) ||
                other.maxAmount == maxAmount) &&
            const DeepCollectionEquality()
                .equals(other._categoryIds, _categoryIds) &&
            const DeepCollectionEquality()
                .equals(other._accountIds, _accountIds) &&
            const DeepCollectionEquality()
                .equals(other._transactionTypes, _transactionTypes) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      datePreset,
      customStartDate,
      customEndDate,
      minAmount,
      maxAmount,
      const DeepCollectionEquality().hash(_categoryIds),
      const DeepCollectionEquality().hash(_accountIds),
      const DeepCollectionEquality().hash(_transactionTypes),
      const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchFilterEntityImplCopyWith<_$SearchFilterEntityImpl> get copyWith =>
      __$$SearchFilterEntityImplCopyWithImpl<_$SearchFilterEntityImpl>(
          this, _$identity);
}

abstract class _SearchFilterEntity extends SearchFilterEntity {
  const factory _SearchFilterEntity(
      {final DateRangePreset datePreset,
      final DateTime? customStartDate,
      final DateTime? customEndDate,
      final BigInt? minAmount,
      final BigInt? maxAmount,
      final Set<String> categoryIds,
      final Set<String> accountIds,
      final Set<String> transactionTypes,
      final Set<String> tags}) = _$SearchFilterEntityImpl;
  const _SearchFilterEntity._() : super._();

  @override
  DateRangePreset get datePreset;
  @override
  DateTime? get customStartDate;
  @override
  DateTime? get customEndDate;
  @override
  BigInt? get minAmount;
  @override
  BigInt? get maxAmount;
  @override
  Set<String> get categoryIds;
  @override
  Set<String> get accountIds;
  @override
  Set<String> get transactionTypes;
  @override
  Set<String> get tags;
  @override
  @JsonKey(ignore: true)
  _$$SearchFilterEntityImplCopyWith<_$SearchFilterEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
