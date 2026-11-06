// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'currency_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CurrencyState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)
        loaded,
    required TResult Function(String message) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult? Function(String message)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CurrencyInitial value) initial,
    required TResult Function(CurrencyLoading value) loading,
    required TResult Function(CurrencyLoaded value) loaded,
    required TResult Function(CurrencyFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CurrencyInitial value)? initial,
    TResult? Function(CurrencyLoading value)? loading,
    TResult? Function(CurrencyLoaded value)? loaded,
    TResult? Function(CurrencyFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CurrencyInitial value)? initial,
    TResult Function(CurrencyLoading value)? loading,
    TResult Function(CurrencyLoaded value)? loaded,
    TResult Function(CurrencyFailure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurrencyStateCopyWith<$Res> {
  factory $CurrencyStateCopyWith(
          CurrencyState value, $Res Function(CurrencyState) then) =
      _$CurrencyStateCopyWithImpl<$Res, CurrencyState>;
}

/// @nodoc
class _$CurrencyStateCopyWithImpl<$Res, $Val extends CurrencyState>
    implements $CurrencyStateCopyWith<$Res> {
  _$CurrencyStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$CurrencyInitialImplCopyWith<$Res> {
  factory _$$CurrencyInitialImplCopyWith(_$CurrencyInitialImpl value,
          $Res Function(_$CurrencyInitialImpl) then) =
      __$$CurrencyInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CurrencyInitialImplCopyWithImpl<$Res>
    extends _$CurrencyStateCopyWithImpl<$Res, _$CurrencyInitialImpl>
    implements _$$CurrencyInitialImplCopyWith<$Res> {
  __$$CurrencyInitialImplCopyWithImpl(
      _$CurrencyInitialImpl _value, $Res Function(_$CurrencyInitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$CurrencyInitialImpl implements CurrencyInitial {
  const _$CurrencyInitialImpl();

  @override
  String toString() {
    return 'CurrencyState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$CurrencyInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)
        loaded,
    required TResult Function(String message) failure,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult? Function(String message)? failure,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
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
    required TResult Function(CurrencyInitial value) initial,
    required TResult Function(CurrencyLoading value) loading,
    required TResult Function(CurrencyLoaded value) loaded,
    required TResult Function(CurrencyFailure value) failure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CurrencyInitial value)? initial,
    TResult? Function(CurrencyLoading value)? loading,
    TResult? Function(CurrencyLoaded value)? loaded,
    TResult? Function(CurrencyFailure value)? failure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CurrencyInitial value)? initial,
    TResult Function(CurrencyLoading value)? loading,
    TResult Function(CurrencyLoaded value)? loaded,
    TResult Function(CurrencyFailure value)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class CurrencyInitial implements CurrencyState {
  const factory CurrencyInitial() = _$CurrencyInitialImpl;
}

/// @nodoc
abstract class _$$CurrencyLoadingImplCopyWith<$Res> {
  factory _$$CurrencyLoadingImplCopyWith(_$CurrencyLoadingImpl value,
          $Res Function(_$CurrencyLoadingImpl) then) =
      __$$CurrencyLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CurrencyLoadingImplCopyWithImpl<$Res>
    extends _$CurrencyStateCopyWithImpl<$Res, _$CurrencyLoadingImpl>
    implements _$$CurrencyLoadingImplCopyWith<$Res> {
  __$$CurrencyLoadingImplCopyWithImpl(
      _$CurrencyLoadingImpl _value, $Res Function(_$CurrencyLoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$CurrencyLoadingImpl implements CurrencyLoading {
  const _$CurrencyLoadingImpl();

  @override
  String toString() {
    return 'CurrencyState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$CurrencyLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)
        loaded,
    required TResult Function(String message) failure,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult? Function(String message)? failure,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
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
    required TResult Function(CurrencyInitial value) initial,
    required TResult Function(CurrencyLoading value) loading,
    required TResult Function(CurrencyLoaded value) loaded,
    required TResult Function(CurrencyFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CurrencyInitial value)? initial,
    TResult? Function(CurrencyLoading value)? loading,
    TResult? Function(CurrencyLoaded value)? loaded,
    TResult? Function(CurrencyFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CurrencyInitial value)? initial,
    TResult Function(CurrencyLoading value)? loading,
    TResult Function(CurrencyLoaded value)? loaded,
    TResult Function(CurrencyFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class CurrencyLoading implements CurrencyState {
  const factory CurrencyLoading() = _$CurrencyLoadingImpl;
}

/// @nodoc
abstract class _$$CurrencyLoadedImplCopyWith<$Res> {
  factory _$$CurrencyLoadedImplCopyWith(_$CurrencyLoadedImpl value,
          $Res Function(_$CurrencyLoadedImpl) then) =
      __$$CurrencyLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String baseCurrency,
      String selectedCurrency,
      Map<String, BigInt> rates,
      List<ExchangeRateEntity> rateEntities});
}

/// @nodoc
class __$$CurrencyLoadedImplCopyWithImpl<$Res>
    extends _$CurrencyStateCopyWithImpl<$Res, _$CurrencyLoadedImpl>
    implements _$$CurrencyLoadedImplCopyWith<$Res> {
  __$$CurrencyLoadedImplCopyWithImpl(
      _$CurrencyLoadedImpl _value, $Res Function(_$CurrencyLoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseCurrency = null,
    Object? selectedCurrency = null,
    Object? rates = null,
    Object? rateEntities = null,
  }) {
    return _then(_$CurrencyLoadedImpl(
      baseCurrency: null == baseCurrency
          ? _value.baseCurrency
          : baseCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      selectedCurrency: null == selectedCurrency
          ? _value.selectedCurrency
          : selectedCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      rates: null == rates
          ? _value._rates
          : rates // ignore: cast_nullable_to_non_nullable
              as Map<String, BigInt>,
      rateEntities: null == rateEntities
          ? _value._rateEntities
          : rateEntities // ignore: cast_nullable_to_non_nullable
              as List<ExchangeRateEntity>,
    ));
  }
}

/// @nodoc

class _$CurrencyLoadedImpl implements CurrencyLoaded {
  const _$CurrencyLoadedImpl(
      {required this.baseCurrency,
      required this.selectedCurrency,
      required final Map<String, BigInt> rates,
      final List<ExchangeRateEntity> rateEntities = const []})
      : _rates = rates,
        _rateEntities = rateEntities;

  @override
  final String baseCurrency;
  @override
  final String selectedCurrency;
  final Map<String, BigInt> _rates;
  @override
  Map<String, BigInt> get rates {
    if (_rates is EqualUnmodifiableMapView) return _rates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_rates);
  }

  final List<ExchangeRateEntity> _rateEntities;
  @override
  @JsonKey()
  List<ExchangeRateEntity> get rateEntities {
    if (_rateEntities is EqualUnmodifiableListView) return _rateEntities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rateEntities);
  }

  @override
  String toString() {
    return 'CurrencyState.loaded(baseCurrency: $baseCurrency, selectedCurrency: $selectedCurrency, rates: $rates, rateEntities: $rateEntities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurrencyLoadedImpl &&
            (identical(other.baseCurrency, baseCurrency) ||
                other.baseCurrency == baseCurrency) &&
            (identical(other.selectedCurrency, selectedCurrency) ||
                other.selectedCurrency == selectedCurrency) &&
            const DeepCollectionEquality().equals(other._rates, _rates) &&
            const DeepCollectionEquality()
                .equals(other._rateEntities, _rateEntities));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      baseCurrency,
      selectedCurrency,
      const DeepCollectionEquality().hash(_rates),
      const DeepCollectionEquality().hash(_rateEntities));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CurrencyLoadedImplCopyWith<_$CurrencyLoadedImpl> get copyWith =>
      __$$CurrencyLoadedImplCopyWithImpl<_$CurrencyLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)
        loaded,
    required TResult Function(String message) failure,
  }) {
    return loaded(baseCurrency, selectedCurrency, rates, rateEntities);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult? Function(String message)? failure,
  }) {
    return loaded?.call(baseCurrency, selectedCurrency, rates, rateEntities);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(baseCurrency, selectedCurrency, rates, rateEntities);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CurrencyInitial value) initial,
    required TResult Function(CurrencyLoading value) loading,
    required TResult Function(CurrencyLoaded value) loaded,
    required TResult Function(CurrencyFailure value) failure,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CurrencyInitial value)? initial,
    TResult? Function(CurrencyLoading value)? loading,
    TResult? Function(CurrencyLoaded value)? loaded,
    TResult? Function(CurrencyFailure value)? failure,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CurrencyInitial value)? initial,
    TResult Function(CurrencyLoading value)? loading,
    TResult Function(CurrencyLoaded value)? loaded,
    TResult Function(CurrencyFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class CurrencyLoaded implements CurrencyState {
  const factory CurrencyLoaded(
      {required final String baseCurrency,
      required final String selectedCurrency,
      required final Map<String, BigInt> rates,
      final List<ExchangeRateEntity> rateEntities}) = _$CurrencyLoadedImpl;

  String get baseCurrency;
  String get selectedCurrency;
  Map<String, BigInt> get rates;
  List<ExchangeRateEntity> get rateEntities;
  @JsonKey(ignore: true)
  _$$CurrencyLoadedImplCopyWith<_$CurrencyLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CurrencyFailureImplCopyWith<$Res> {
  factory _$$CurrencyFailureImplCopyWith(_$CurrencyFailureImpl value,
          $Res Function(_$CurrencyFailureImpl) then) =
      __$$CurrencyFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$CurrencyFailureImplCopyWithImpl<$Res>
    extends _$CurrencyStateCopyWithImpl<$Res, _$CurrencyFailureImpl>
    implements _$$CurrencyFailureImplCopyWith<$Res> {
  __$$CurrencyFailureImplCopyWithImpl(
      _$CurrencyFailureImpl _value, $Res Function(_$CurrencyFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$CurrencyFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$CurrencyFailureImpl implements CurrencyFailure {
  const _$CurrencyFailureImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'CurrencyState.failure(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurrencyFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CurrencyFailureImplCopyWith<_$CurrencyFailureImpl> get copyWith =>
      __$$CurrencyFailureImplCopyWithImpl<_$CurrencyFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)
        loaded,
    required TResult Function(String message) failure,
  }) {
    return failure(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
    TResult? Function(String message)? failure,
  }) {
    return failure?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(String baseCurrency, String selectedCurrency,
            Map<String, BigInt> rates, List<ExchangeRateEntity> rateEntities)?
        loaded,
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
    required TResult Function(CurrencyInitial value) initial,
    required TResult Function(CurrencyLoading value) loading,
    required TResult Function(CurrencyLoaded value) loaded,
    required TResult Function(CurrencyFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CurrencyInitial value)? initial,
    TResult? Function(CurrencyLoading value)? loading,
    TResult? Function(CurrencyLoaded value)? loaded,
    TResult? Function(CurrencyFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CurrencyInitial value)? initial,
    TResult Function(CurrencyLoading value)? loading,
    TResult Function(CurrencyLoaded value)? loaded,
    TResult Function(CurrencyFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class CurrencyFailure implements CurrencyState {
  const factory CurrencyFailure({required final String message}) =
      _$CurrencyFailureImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$CurrencyFailureImplCopyWith<_$CurrencyFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
