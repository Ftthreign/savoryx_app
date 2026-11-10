// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SyncEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(void Function()? onComplete) manualRequested,
    required TResult Function() connectivityTriggered,
    required TResult Function(int count) pendingCountUpdated,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(void Function()? onComplete)? manualRequested,
    TResult? Function()? connectivityTriggered,
    TResult? Function(int count)? pendingCountUpdated,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(void Function()? onComplete)? manualRequested,
    TResult Function()? connectivityTriggered,
    TResult Function(int count)? pendingCountUpdated,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStarted value) started,
    required TResult Function(SyncManualRequested value) manualRequested,
    required TResult Function(SyncConnectivityTriggered value)
        connectivityTriggered,
    required TResult Function(SyncPendingCountUpdated value)
        pendingCountUpdated,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStarted value)? started,
    TResult? Function(SyncManualRequested value)? manualRequested,
    TResult? Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult? Function(SyncPendingCountUpdated value)? pendingCountUpdated,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStarted value)? started,
    TResult Function(SyncManualRequested value)? manualRequested,
    TResult Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult Function(SyncPendingCountUpdated value)? pendingCountUpdated,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncEventCopyWith<$Res> {
  factory $SyncEventCopyWith(SyncEvent value, $Res Function(SyncEvent) then) =
      _$SyncEventCopyWithImpl<$Res, SyncEvent>;
}

/// @nodoc
class _$SyncEventCopyWithImpl<$Res, $Val extends SyncEvent>
    implements $SyncEventCopyWith<$Res> {
  _$SyncEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$SyncStartedImplCopyWith<$Res> {
  factory _$$SyncStartedImplCopyWith(
          _$SyncStartedImpl value, $Res Function(_$SyncStartedImpl) then) =
      __$$SyncStartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncStartedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncStartedImpl>
    implements _$$SyncStartedImplCopyWith<$Res> {
  __$$SyncStartedImplCopyWithImpl(
      _$SyncStartedImpl _value, $Res Function(_$SyncStartedImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SyncStartedImpl implements SyncStarted {
  const _$SyncStartedImpl();

  @override
  String toString() {
    return 'SyncEvent.started()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncStartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(void Function()? onComplete) manualRequested,
    required TResult Function() connectivityTriggered,
    required TResult Function(int count) pendingCountUpdated,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(void Function()? onComplete)? manualRequested,
    TResult? Function()? connectivityTriggered,
    TResult? Function(int count)? pendingCountUpdated,
  }) {
    return started?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(void Function()? onComplete)? manualRequested,
    TResult Function()? connectivityTriggered,
    TResult Function(int count)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStarted value) started,
    required TResult Function(SyncManualRequested value) manualRequested,
    required TResult Function(SyncConnectivityTriggered value)
        connectivityTriggered,
    required TResult Function(SyncPendingCountUpdated value)
        pendingCountUpdated,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStarted value)? started,
    TResult? Function(SyncManualRequested value)? manualRequested,
    TResult? Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult? Function(SyncPendingCountUpdated value)? pendingCountUpdated,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStarted value)? started,
    TResult Function(SyncManualRequested value)? manualRequested,
    TResult Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult Function(SyncPendingCountUpdated value)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class SyncStarted implements SyncEvent {
  const factory SyncStarted() = _$SyncStartedImpl;
}

/// @nodoc
abstract class _$$SyncManualRequestedImplCopyWith<$Res> {
  factory _$$SyncManualRequestedImplCopyWith(_$SyncManualRequestedImpl value,
          $Res Function(_$SyncManualRequestedImpl) then) =
      __$$SyncManualRequestedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({void Function()? onComplete});
}

/// @nodoc
class __$$SyncManualRequestedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncManualRequestedImpl>
    implements _$$SyncManualRequestedImplCopyWith<$Res> {
  __$$SyncManualRequestedImplCopyWithImpl(_$SyncManualRequestedImpl _value,
      $Res Function(_$SyncManualRequestedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? onComplete = freezed,
  }) {
    return _then(_$SyncManualRequestedImpl(
      onComplete: freezed == onComplete
          ? _value.onComplete
          : onComplete // ignore: cast_nullable_to_non_nullable
              as void Function()?,
    ));
  }
}

/// @nodoc

class _$SyncManualRequestedImpl implements SyncManualRequested {
  const _$SyncManualRequestedImpl({this.onComplete});

  @override
  final void Function()? onComplete;

  @override
  String toString() {
    return 'SyncEvent.manualRequested(onComplete: $onComplete)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncManualRequestedImpl &&
            (identical(other.onComplete, onComplete) ||
                other.onComplete == onComplete));
  }

  @override
  int get hashCode => Object.hash(runtimeType, onComplete);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncManualRequestedImplCopyWith<_$SyncManualRequestedImpl> get copyWith =>
      __$$SyncManualRequestedImplCopyWithImpl<_$SyncManualRequestedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(void Function()? onComplete) manualRequested,
    required TResult Function() connectivityTriggered,
    required TResult Function(int count) pendingCountUpdated,
  }) {
    return manualRequested(onComplete);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(void Function()? onComplete)? manualRequested,
    TResult? Function()? connectivityTriggered,
    TResult? Function(int count)? pendingCountUpdated,
  }) {
    return manualRequested?.call(onComplete);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(void Function()? onComplete)? manualRequested,
    TResult Function()? connectivityTriggered,
    TResult Function(int count)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (manualRequested != null) {
      return manualRequested(onComplete);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStarted value) started,
    required TResult Function(SyncManualRequested value) manualRequested,
    required TResult Function(SyncConnectivityTriggered value)
        connectivityTriggered,
    required TResult Function(SyncPendingCountUpdated value)
        pendingCountUpdated,
  }) {
    return manualRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStarted value)? started,
    TResult? Function(SyncManualRequested value)? manualRequested,
    TResult? Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult? Function(SyncPendingCountUpdated value)? pendingCountUpdated,
  }) {
    return manualRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStarted value)? started,
    TResult Function(SyncManualRequested value)? manualRequested,
    TResult Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult Function(SyncPendingCountUpdated value)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (manualRequested != null) {
      return manualRequested(this);
    }
    return orElse();
  }
}

abstract class SyncManualRequested implements SyncEvent {
  const factory SyncManualRequested({final void Function()? onComplete}) =
      _$SyncManualRequestedImpl;

  void Function()? get onComplete;
  @JsonKey(ignore: true)
  _$$SyncManualRequestedImplCopyWith<_$SyncManualRequestedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncConnectivityTriggeredImplCopyWith<$Res> {
  factory _$$SyncConnectivityTriggeredImplCopyWith(
          _$SyncConnectivityTriggeredImpl value,
          $Res Function(_$SyncConnectivityTriggeredImpl) then) =
      __$$SyncConnectivityTriggeredImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncConnectivityTriggeredImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncConnectivityTriggeredImpl>
    implements _$$SyncConnectivityTriggeredImplCopyWith<$Res> {
  __$$SyncConnectivityTriggeredImplCopyWithImpl(
      _$SyncConnectivityTriggeredImpl _value,
      $Res Function(_$SyncConnectivityTriggeredImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SyncConnectivityTriggeredImpl implements SyncConnectivityTriggered {
  const _$SyncConnectivityTriggeredImpl();

  @override
  String toString() {
    return 'SyncEvent.connectivityTriggered()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncConnectivityTriggeredImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(void Function()? onComplete) manualRequested,
    required TResult Function() connectivityTriggered,
    required TResult Function(int count) pendingCountUpdated,
  }) {
    return connectivityTriggered();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(void Function()? onComplete)? manualRequested,
    TResult? Function()? connectivityTriggered,
    TResult? Function(int count)? pendingCountUpdated,
  }) {
    return connectivityTriggered?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(void Function()? onComplete)? manualRequested,
    TResult Function()? connectivityTriggered,
    TResult Function(int count)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (connectivityTriggered != null) {
      return connectivityTriggered();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStarted value) started,
    required TResult Function(SyncManualRequested value) manualRequested,
    required TResult Function(SyncConnectivityTriggered value)
        connectivityTriggered,
    required TResult Function(SyncPendingCountUpdated value)
        pendingCountUpdated,
  }) {
    return connectivityTriggered(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStarted value)? started,
    TResult? Function(SyncManualRequested value)? manualRequested,
    TResult? Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult? Function(SyncPendingCountUpdated value)? pendingCountUpdated,
  }) {
    return connectivityTriggered?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStarted value)? started,
    TResult Function(SyncManualRequested value)? manualRequested,
    TResult Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult Function(SyncPendingCountUpdated value)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (connectivityTriggered != null) {
      return connectivityTriggered(this);
    }
    return orElse();
  }
}

abstract class SyncConnectivityTriggered implements SyncEvent {
  const factory SyncConnectivityTriggered() = _$SyncConnectivityTriggeredImpl;
}

/// @nodoc
abstract class _$$SyncPendingCountUpdatedImplCopyWith<$Res> {
  factory _$$SyncPendingCountUpdatedImplCopyWith(
          _$SyncPendingCountUpdatedImpl value,
          $Res Function(_$SyncPendingCountUpdatedImpl) then) =
      __$$SyncPendingCountUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int count});
}

/// @nodoc
class __$$SyncPendingCountUpdatedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncPendingCountUpdatedImpl>
    implements _$$SyncPendingCountUpdatedImplCopyWith<$Res> {
  __$$SyncPendingCountUpdatedImplCopyWithImpl(
      _$SyncPendingCountUpdatedImpl _value,
      $Res Function(_$SyncPendingCountUpdatedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
  }) {
    return _then(_$SyncPendingCountUpdatedImpl(
      null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SyncPendingCountUpdatedImpl implements SyncPendingCountUpdated {
  const _$SyncPendingCountUpdatedImpl(this.count);

  @override
  final int count;

  @override
  String toString() {
    return 'SyncEvent.pendingCountUpdated(count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncPendingCountUpdatedImpl &&
            (identical(other.count, count) || other.count == count));
  }

  @override
  int get hashCode => Object.hash(runtimeType, count);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncPendingCountUpdatedImplCopyWith<_$SyncPendingCountUpdatedImpl>
      get copyWith => __$$SyncPendingCountUpdatedImplCopyWithImpl<
          _$SyncPendingCountUpdatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(void Function()? onComplete) manualRequested,
    required TResult Function() connectivityTriggered,
    required TResult Function(int count) pendingCountUpdated,
  }) {
    return pendingCountUpdated(count);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(void Function()? onComplete)? manualRequested,
    TResult? Function()? connectivityTriggered,
    TResult? Function(int count)? pendingCountUpdated,
  }) {
    return pendingCountUpdated?.call(count);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(void Function()? onComplete)? manualRequested,
    TResult Function()? connectivityTriggered,
    TResult Function(int count)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (pendingCountUpdated != null) {
      return pendingCountUpdated(count);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncStarted value) started,
    required TResult Function(SyncManualRequested value) manualRequested,
    required TResult Function(SyncConnectivityTriggered value)
        connectivityTriggered,
    required TResult Function(SyncPendingCountUpdated value)
        pendingCountUpdated,
  }) {
    return pendingCountUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncStarted value)? started,
    TResult? Function(SyncManualRequested value)? manualRequested,
    TResult? Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult? Function(SyncPendingCountUpdated value)? pendingCountUpdated,
  }) {
    return pendingCountUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncStarted value)? started,
    TResult Function(SyncManualRequested value)? manualRequested,
    TResult Function(SyncConnectivityTriggered value)? connectivityTriggered,
    TResult Function(SyncPendingCountUpdated value)? pendingCountUpdated,
    required TResult orElse(),
  }) {
    if (pendingCountUpdated != null) {
      return pendingCountUpdated(this);
    }
    return orElse();
  }
}

abstract class SyncPendingCountUpdated implements SyncEvent {
  const factory SyncPendingCountUpdated(final int count) =
      _$SyncPendingCountUpdatedImpl;

  int get count;
  @JsonKey(ignore: true)
  _$$SyncPendingCountUpdatedImplCopyWith<_$SyncPendingCountUpdatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}
