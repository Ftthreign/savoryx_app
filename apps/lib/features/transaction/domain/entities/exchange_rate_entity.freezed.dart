// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange_rate_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExchangeRateEntity {
  String get baseCurrency => throw _privateConstructorUsedError;
  String get targetCurrency => throw _privateConstructorUsedError;
  BigInt get rateScaled => throw _privateConstructorUsedError;
  DateTime get effectiveDate => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ExchangeRateEntityCopyWith<ExchangeRateEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExchangeRateEntityCopyWith<$Res> {
  factory $ExchangeRateEntityCopyWith(
          ExchangeRateEntity value, $Res Function(ExchangeRateEntity) then) =
      _$ExchangeRateEntityCopyWithImpl<$Res, ExchangeRateEntity>;
  @useResult
  $Res call(
      {String baseCurrency,
      String targetCurrency,
      BigInt rateScaled,
      DateTime effectiveDate,
      DateTime updatedAt});
}

/// @nodoc
class _$ExchangeRateEntityCopyWithImpl<$Res, $Val extends ExchangeRateEntity>
    implements $ExchangeRateEntityCopyWith<$Res> {
  _$ExchangeRateEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseCurrency = null,
    Object? targetCurrency = null,
    Object? rateScaled = null,
    Object? effectiveDate = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      baseCurrency: null == baseCurrency
          ? _value.baseCurrency
          : baseCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      targetCurrency: null == targetCurrency
          ? _value.targetCurrency
          : targetCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      rateScaled: null == rateScaled
          ? _value.rateScaled
          : rateScaled // ignore: cast_nullable_to_non_nullable
              as BigInt,
      effectiveDate: null == effectiveDate
          ? _value.effectiveDate
          : effectiveDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExchangeRateEntityImplCopyWith<$Res>
    implements $ExchangeRateEntityCopyWith<$Res> {
  factory _$$ExchangeRateEntityImplCopyWith(_$ExchangeRateEntityImpl value,
          $Res Function(_$ExchangeRateEntityImpl) then) =
      __$$ExchangeRateEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String baseCurrency,
      String targetCurrency,
      BigInt rateScaled,
      DateTime effectiveDate,
      DateTime updatedAt});
}

/// @nodoc
class __$$ExchangeRateEntityImplCopyWithImpl<$Res>
    extends _$ExchangeRateEntityCopyWithImpl<$Res, _$ExchangeRateEntityImpl>
    implements _$$ExchangeRateEntityImplCopyWith<$Res> {
  __$$ExchangeRateEntityImplCopyWithImpl(_$ExchangeRateEntityImpl _value,
      $Res Function(_$ExchangeRateEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseCurrency = null,
    Object? targetCurrency = null,
    Object? rateScaled = null,
    Object? effectiveDate = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ExchangeRateEntityImpl(
      baseCurrency: null == baseCurrency
          ? _value.baseCurrency
          : baseCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      targetCurrency: null == targetCurrency
          ? _value.targetCurrency
          : targetCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      rateScaled: null == rateScaled
          ? _value.rateScaled
          : rateScaled // ignore: cast_nullable_to_non_nullable
              as BigInt,
      effectiveDate: null == effectiveDate
          ? _value.effectiveDate
          : effectiveDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$ExchangeRateEntityImpl extends _ExchangeRateEntity {
  const _$ExchangeRateEntityImpl(
      {required this.baseCurrency,
      required this.targetCurrency,
      required this.rateScaled,
      required this.effectiveDate,
      required this.updatedAt})
      : super._();

  @override
  final String baseCurrency;
  @override
  final String targetCurrency;
  @override
  final BigInt rateScaled;
  @override
  final DateTime effectiveDate;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ExchangeRateEntity(baseCurrency: $baseCurrency, targetCurrency: $targetCurrency, rateScaled: $rateScaled, effectiveDate: $effectiveDate, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExchangeRateEntityImpl &&
            (identical(other.baseCurrency, baseCurrency) ||
                other.baseCurrency == baseCurrency) &&
            (identical(other.targetCurrency, targetCurrency) ||
                other.targetCurrency == targetCurrency) &&
            (identical(other.rateScaled, rateScaled) ||
                other.rateScaled == rateScaled) &&
            (identical(other.effectiveDate, effectiveDate) ||
                other.effectiveDate == effectiveDate) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, baseCurrency, targetCurrency,
      rateScaled, effectiveDate, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExchangeRateEntityImplCopyWith<_$ExchangeRateEntityImpl> get copyWith =>
      __$$ExchangeRateEntityImplCopyWithImpl<_$ExchangeRateEntityImpl>(
          this, _$identity);
}

abstract class _ExchangeRateEntity extends ExchangeRateEntity {
  const factory _ExchangeRateEntity(
      {required final String baseCurrency,
      required final String targetCurrency,
      required final BigInt rateScaled,
      required final DateTime effectiveDate,
      required final DateTime updatedAt}) = _$ExchangeRateEntityImpl;
  const _ExchangeRateEntity._() : super._();

  @override
  String get baseCurrency;
  @override
  String get targetCurrency;
  @override
  BigInt get rateScaled;
  @override
  DateTime get effectiveDate;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ExchangeRateEntityImplCopyWith<_$ExchangeRateEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
