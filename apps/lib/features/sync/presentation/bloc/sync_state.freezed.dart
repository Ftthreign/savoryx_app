// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SyncState {
  int get pendingCount => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int pendingCount, DateTime? lastSyncedAt) idle,
    required TResult Function(int pendingCount) syncing,
    required TResult Function(DateTime lastSyncedAt, int pendingCount) success,
    required TResult Function(
            String message, int pendingCount, DateTime? lastSyncedAt)
        failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult? Function(int pendingCount)? syncing,
    TResult? Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult? Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult Function(int pendingCount)? syncing,
    TResult Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncIdle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(SyncSuccess value) success,
    required TResult Function(SyncFailure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncIdle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(SyncSuccess value)? success,
    TResult? Function(SyncFailure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncIdle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(SyncSuccess value)? success,
    TResult Function(SyncFailure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SyncStateCopyWith<SyncState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStateCopyWith<$Res> {
  factory $SyncStateCopyWith(SyncState value, $Res Function(SyncState) then) =
      _$SyncStateCopyWithImpl<$Res, SyncState>;
  @useResult
  $Res call({int pendingCount});
}

/// @nodoc
class _$SyncStateCopyWithImpl<$Res, $Val extends SyncState>
    implements $SyncStateCopyWith<$Res> {
  _$SyncStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingCount = null,
  }) {
    return _then(_value.copyWith(
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncIdleImplCopyWith<$Res>
    implements $SyncStateCopyWith<$Res> {
  factory _$$SyncIdleImplCopyWith(
          _$SyncIdleImpl value, $Res Function(_$SyncIdleImpl) then) =
      __$$SyncIdleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int pendingCount, DateTime? lastSyncedAt});
}

/// @nodoc
class __$$SyncIdleImplCopyWithImpl<$Res>
    extends _$SyncStateCopyWithImpl<$Res, _$SyncIdleImpl>
    implements _$$SyncIdleImplCopyWith<$Res> {
  __$$SyncIdleImplCopyWithImpl(
      _$SyncIdleImpl _value, $Res Function(_$SyncIdleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingCount = null,
    Object? lastSyncedAt = freezed,
  }) {
    return _then(_$SyncIdleImpl(
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastSyncedAt: freezed == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$SyncIdleImpl extends SyncIdle {
  const _$SyncIdleImpl({this.pendingCount = 0, this.lastSyncedAt}) : super._();

  @override
  @JsonKey()
  final int pendingCount;
  @override
  final DateTime? lastSyncedAt;

  @override
  String toString() {
    return 'SyncState.idle(pendingCount: $pendingCount, lastSyncedAt: $lastSyncedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncIdleImpl &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.lastSyncedAt, lastSyncedAt) ||
                other.lastSyncedAt == lastSyncedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pendingCount, lastSyncedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncIdleImplCopyWith<_$SyncIdleImpl> get copyWith =>
      __$$SyncIdleImplCopyWithImpl<_$SyncIdleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int pendingCount, DateTime? lastSyncedAt) idle,
    required TResult Function(int pendingCount) syncing,
    required TResult Function(DateTime lastSyncedAt, int pendingCount) success,
    required TResult Function(
            String message, int pendingCount, DateTime? lastSyncedAt)
        failure,
  }) {
    return idle(pendingCount, lastSyncedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult? Function(int pendingCount)? syncing,
    TResult? Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult? Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
  }) {
    return idle?.call(pendingCount, lastSyncedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult Function(int pendingCount)? syncing,
    TResult Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(pendingCount, lastSyncedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncIdle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(SyncSuccess value) success,
    required TResult Function(SyncFailure value) failure,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncIdle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(SyncSuccess value)? success,
    TResult? Function(SyncFailure value)? failure,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncIdle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(SyncSuccess value)? success,
    TResult Function(SyncFailure value)? failure,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class SyncIdle extends SyncState {
  const factory SyncIdle(
      {final int pendingCount, final DateTime? lastSyncedAt}) = _$SyncIdleImpl;
  const SyncIdle._() : super._();

  @override
  int get pendingCount;
  DateTime? get lastSyncedAt;
  @override
  @JsonKey(ignore: true)
  _$$SyncIdleImplCopyWith<_$SyncIdleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncingImplCopyWith<$Res>
    implements $SyncStateCopyWith<$Res> {
  factory _$$SyncingImplCopyWith(
          _$SyncingImpl value, $Res Function(_$SyncingImpl) then) =
      __$$SyncingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int pendingCount});
}

/// @nodoc
class __$$SyncingImplCopyWithImpl<$Res>
    extends _$SyncStateCopyWithImpl<$Res, _$SyncingImpl>
    implements _$$SyncingImplCopyWith<$Res> {
  __$$SyncingImplCopyWithImpl(
      _$SyncingImpl _value, $Res Function(_$SyncingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingCount = null,
  }) {
    return _then(_$SyncingImpl(
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SyncingImpl extends Syncing {
  const _$SyncingImpl({required this.pendingCount}) : super._();

  @override
  final int pendingCount;

  @override
  String toString() {
    return 'SyncState.syncing(pendingCount: $pendingCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncingImpl &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pendingCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncingImplCopyWith<_$SyncingImpl> get copyWith =>
      __$$SyncingImplCopyWithImpl<_$SyncingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int pendingCount, DateTime? lastSyncedAt) idle,
    required TResult Function(int pendingCount) syncing,
    required TResult Function(DateTime lastSyncedAt, int pendingCount) success,
    required TResult Function(
            String message, int pendingCount, DateTime? lastSyncedAt)
        failure,
  }) {
    return syncing(pendingCount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult? Function(int pendingCount)? syncing,
    TResult? Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult? Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
  }) {
    return syncing?.call(pendingCount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult Function(int pendingCount)? syncing,
    TResult Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing(pendingCount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncIdle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(SyncSuccess value) success,
    required TResult Function(SyncFailure value) failure,
  }) {
    return syncing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncIdle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(SyncSuccess value)? success,
    TResult? Function(SyncFailure value)? failure,
  }) {
    return syncing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncIdle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(SyncSuccess value)? success,
    TResult Function(SyncFailure value)? failure,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing(this);
    }
    return orElse();
  }
}

abstract class Syncing extends SyncState {
  const factory Syncing({required final int pendingCount}) = _$SyncingImpl;
  const Syncing._() : super._();

  @override
  int get pendingCount;
  @override
  @JsonKey(ignore: true)
  _$$SyncingImplCopyWith<_$SyncingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncSuccessImplCopyWith<$Res>
    implements $SyncStateCopyWith<$Res> {
  factory _$$SyncSuccessImplCopyWith(
          _$SyncSuccessImpl value, $Res Function(_$SyncSuccessImpl) then) =
      __$$SyncSuccessImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime lastSyncedAt, int pendingCount});
}

/// @nodoc
class __$$SyncSuccessImplCopyWithImpl<$Res>
    extends _$SyncStateCopyWithImpl<$Res, _$SyncSuccessImpl>
    implements _$$SyncSuccessImplCopyWith<$Res> {
  __$$SyncSuccessImplCopyWithImpl(
      _$SyncSuccessImpl _value, $Res Function(_$SyncSuccessImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastSyncedAt = null,
    Object? pendingCount = null,
  }) {
    return _then(_$SyncSuccessImpl(
      lastSyncedAt: null == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SyncSuccessImpl extends SyncSuccess {
  const _$SyncSuccessImpl({required this.lastSyncedAt, this.pendingCount = 0})
      : super._();

  @override
  final DateTime lastSyncedAt;
  @override
  @JsonKey()
  final int pendingCount;

  @override
  String toString() {
    return 'SyncState.success(lastSyncedAt: $lastSyncedAt, pendingCount: $pendingCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncSuccessImpl &&
            (identical(other.lastSyncedAt, lastSyncedAt) ||
                other.lastSyncedAt == lastSyncedAt) &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, lastSyncedAt, pendingCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncSuccessImplCopyWith<_$SyncSuccessImpl> get copyWith =>
      __$$SyncSuccessImplCopyWithImpl<_$SyncSuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int pendingCount, DateTime? lastSyncedAt) idle,
    required TResult Function(int pendingCount) syncing,
    required TResult Function(DateTime lastSyncedAt, int pendingCount) success,
    required TResult Function(
            String message, int pendingCount, DateTime? lastSyncedAt)
        failure,
  }) {
    return success(lastSyncedAt, pendingCount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult? Function(int pendingCount)? syncing,
    TResult? Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult? Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
  }) {
    return success?.call(lastSyncedAt, pendingCount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult Function(int pendingCount)? syncing,
    TResult Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(lastSyncedAt, pendingCount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncIdle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(SyncSuccess value) success,
    required TResult Function(SyncFailure value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncIdle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(SyncSuccess value)? success,
    TResult? Function(SyncFailure value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncIdle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(SyncSuccess value)? success,
    TResult Function(SyncFailure value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class SyncSuccess extends SyncState {
  const factory SyncSuccess(
      {required final DateTime lastSyncedAt,
      final int pendingCount}) = _$SyncSuccessImpl;
  const SyncSuccess._() : super._();

  DateTime get lastSyncedAt;
  @override
  int get pendingCount;
  @override
  @JsonKey(ignore: true)
  _$$SyncSuccessImplCopyWith<_$SyncSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncFailureImplCopyWith<$Res>
    implements $SyncStateCopyWith<$Res> {
  factory _$$SyncFailureImplCopyWith(
          _$SyncFailureImpl value, $Res Function(_$SyncFailureImpl) then) =
      __$$SyncFailureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int pendingCount, DateTime? lastSyncedAt});
}

/// @nodoc
class __$$SyncFailureImplCopyWithImpl<$Res>
    extends _$SyncStateCopyWithImpl<$Res, _$SyncFailureImpl>
    implements _$$SyncFailureImplCopyWith<$Res> {
  __$$SyncFailureImplCopyWithImpl(
      _$SyncFailureImpl _value, $Res Function(_$SyncFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? pendingCount = null,
    Object? lastSyncedAt = freezed,
  }) {
    return _then(_$SyncFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      pendingCount: null == pendingCount
          ? _value.pendingCount
          : pendingCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastSyncedAt: freezed == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$SyncFailureImpl extends SyncFailure {
  const _$SyncFailureImpl(
      {required this.message, this.pendingCount = 0, this.lastSyncedAt})
      : super._();

  @override
  final String message;
  @override
  @JsonKey()
  final int pendingCount;
  @override
  final DateTime? lastSyncedAt;

  @override
  String toString() {
    return 'SyncState.failure(message: $message, pendingCount: $pendingCount, lastSyncedAt: $lastSyncedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncFailureImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.lastSyncedAt, lastSyncedAt) ||
                other.lastSyncedAt == lastSyncedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, message, pendingCount, lastSyncedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncFailureImplCopyWith<_$SyncFailureImpl> get copyWith =>
      __$$SyncFailureImplCopyWithImpl<_$SyncFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int pendingCount, DateTime? lastSyncedAt) idle,
    required TResult Function(int pendingCount) syncing,
    required TResult Function(DateTime lastSyncedAt, int pendingCount) success,
    required TResult Function(
            String message, int pendingCount, DateTime? lastSyncedAt)
        failure,
  }) {
    return failure(message, pendingCount, lastSyncedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult? Function(int pendingCount)? syncing,
    TResult? Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult? Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
  }) {
    return failure?.call(message, pendingCount, lastSyncedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int pendingCount, DateTime? lastSyncedAt)? idle,
    TResult Function(int pendingCount)? syncing,
    TResult Function(DateTime lastSyncedAt, int pendingCount)? success,
    TResult Function(String message, int pendingCount, DateTime? lastSyncedAt)?
        failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(message, pendingCount, lastSyncedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncIdle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(SyncSuccess value) success,
    required TResult Function(SyncFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncIdle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(SyncSuccess value)? success,
    TResult? Function(SyncFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncIdle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(SyncSuccess value)? success,
    TResult Function(SyncFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class SyncFailure extends SyncState {
  const factory SyncFailure(
      {required final String message,
      final int pendingCount,
      final DateTime? lastSyncedAt}) = _$SyncFailureImpl;
  const SyncFailure._() : super._();

  String get message;
  @override
  int get pendingCount;
  DateTime? get lastSyncedAt;
  @override
  @JsonKey(ignore: true)
  _$$SyncFailureImplCopyWith<_$SyncFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
