// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TransactionEntity {
  String get id => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;
  String? get destinationAccountId => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  TransactionType get type => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  BigInt? get exchangeRateToBase => throw _privateConstructorUsedError;
  BigInt? get baseAmount => throw _privateConstructorUsedError;
  DateTime get transactionDate => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TransactionEntityCopyWith<TransactionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionEntityCopyWith<$Res> {
  factory $TransactionEntityCopyWith(
          TransactionEntity value, $Res Function(TransactionEntity) then) =
      _$TransactionEntityCopyWithImpl<$Res, TransactionEntity>;
  @useResult
  $Res call(
      {String id,
      String accountId,
      String? destinationAccountId,
      String? categoryId,
      int amount,
      TransactionType type,
      String note,
      String currency,
      BigInt? exchangeRateToBase,
      BigInt? baseAmount,
      DateTime transactionDate,
      bool isSynced,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime? deletedAt});
}

/// @nodoc
class _$TransactionEntityCopyWithImpl<$Res, $Val extends TransactionEntity>
    implements $TransactionEntityCopyWith<$Res> {
  _$TransactionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? destinationAccountId = freezed,
    Object? categoryId = freezed,
    Object? amount = null,
    Object? type = null,
    Object? note = null,
    Object? currency = null,
    Object? exchangeRateToBase = freezed,
    Object? baseAmount = freezed,
    Object? transactionDate = null,
    Object? isSynced = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      destinationAccountId: freezed == destinationAccountId
          ? _value.destinationAccountId
          : destinationAccountId // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      exchangeRateToBase: freezed == exchangeRateToBase
          ? _value.exchangeRateToBase
          : exchangeRateToBase // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      baseAmount: freezed == baseAmount
          ? _value.baseAmount
          : baseAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      transactionDate: null == transactionDate
          ? _value.transactionDate
          : transactionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionEntityImplCopyWith<$Res>
    implements $TransactionEntityCopyWith<$Res> {
  factory _$$TransactionEntityImplCopyWith(_$TransactionEntityImpl value,
          $Res Function(_$TransactionEntityImpl) then) =
      __$$TransactionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String accountId,
      String? destinationAccountId,
      String? categoryId,
      int amount,
      TransactionType type,
      String note,
      String currency,
      BigInt? exchangeRateToBase,
      BigInt? baseAmount,
      DateTime transactionDate,
      bool isSynced,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime? deletedAt});
}

/// @nodoc
class __$$TransactionEntityImplCopyWithImpl<$Res>
    extends _$TransactionEntityCopyWithImpl<$Res, _$TransactionEntityImpl>
    implements _$$TransactionEntityImplCopyWith<$Res> {
  __$$TransactionEntityImplCopyWithImpl(_$TransactionEntityImpl _value,
      $Res Function(_$TransactionEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? destinationAccountId = freezed,
    Object? categoryId = freezed,
    Object? amount = null,
    Object? type = null,
    Object? note = null,
    Object? currency = null,
    Object? exchangeRateToBase = freezed,
    Object? baseAmount = freezed,
    Object? transactionDate = null,
    Object? isSynced = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_$TransactionEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as String,
      destinationAccountId: freezed == destinationAccountId
          ? _value.destinationAccountId
          : destinationAccountId // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      exchangeRateToBase: freezed == exchangeRateToBase
          ? _value.exchangeRateToBase
          : exchangeRateToBase // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      baseAmount: freezed == baseAmount
          ? _value.baseAmount
          : baseAmount // ignore: cast_nullable_to_non_nullable
              as BigInt?,
      transactionDate: null == transactionDate
          ? _value.transactionDate
          : transactionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$TransactionEntityImpl extends _TransactionEntity {
  const _$TransactionEntityImpl(
      {required this.id,
      required this.accountId,
      this.destinationAccountId,
      this.categoryId,
      required this.amount,
      required this.type,
      this.note = '',
      this.currency = 'IDR',
      this.exchangeRateToBase,
      this.baseAmount,
      required this.transactionDate,
      this.isSynced = false,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt})
      : super._();

  @override
  final String id;
  @override
  final String accountId;
  @override
  final String? destinationAccountId;
  @override
  final String? categoryId;
  @override
  final int amount;
  @override
  final TransactionType type;
  @override
  @JsonKey()
  final String note;
  @override
  @JsonKey()
  final String currency;
  @override
  final BigInt? exchangeRateToBase;
  @override
  final BigInt? baseAmount;
  @override
  final DateTime transactionDate;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'TransactionEntity(id: $id, accountId: $accountId, destinationAccountId: $destinationAccountId, categoryId: $categoryId, amount: $amount, type: $type, note: $note, currency: $currency, exchangeRateToBase: $exchangeRateToBase, baseAmount: $baseAmount, transactionDate: $transactionDate, isSynced: $isSynced, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.destinationAccountId, destinationAccountId) ||
                other.destinationAccountId == destinationAccountId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.exchangeRateToBase, exchangeRateToBase) ||
                other.exchangeRateToBase == exchangeRateToBase) &&
            (identical(other.baseAmount, baseAmount) ||
                other.baseAmount == baseAmount) &&
            (identical(other.transactionDate, transactionDate) ||
                other.transactionDate == transactionDate) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      accountId,
      destinationAccountId,
      categoryId,
      amount,
      type,
      note,
      currency,
      exchangeRateToBase,
      baseAmount,
      transactionDate,
      isSynced,
      createdAt,
      updatedAt,
      deletedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionEntityImplCopyWith<_$TransactionEntityImpl> get copyWith =>
      __$$TransactionEntityImplCopyWithImpl<_$TransactionEntityImpl>(
          this, _$identity);
}

abstract class _TransactionEntity extends TransactionEntity {
  const factory _TransactionEntity(
      {required final String id,
      required final String accountId,
      final String? destinationAccountId,
      final String? categoryId,
      required final int amount,
      required final TransactionType type,
      final String note,
      final String currency,
      final BigInt? exchangeRateToBase,
      final BigInt? baseAmount,
      required final DateTime transactionDate,
      final bool isSynced,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final DateTime? deletedAt}) = _$TransactionEntityImpl;
  const _TransactionEntity._() : super._();

  @override
  String get id;
  @override
  String get accountId;
  @override
  String? get destinationAccountId;
  @override
  String? get categoryId;
  @override
  int get amount;
  @override
  TransactionType get type;
  @override
  String get note;
  @override
  String get currency;
  @override
  BigInt? get exchangeRateToBase;
  @override
  BigInt? get baseAmount;
  @override
  DateTime get transactionDate;
  @override
  bool get isSynced;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  DateTime? get deletedAt;
  @override
  @JsonKey(ignore: true)
  _$$TransactionEntityImplCopyWith<_$TransactionEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
