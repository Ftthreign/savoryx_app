import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show MissingPluginException;

abstract interface class NetworkConnectivityMonitor {
  Stream<bool> get onOnlineChanged;

  Future<bool> isConnected();
}

bool isOnlineConnectivityResults(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

class ConnectivityPlusMonitor implements NetworkConnectivityMonitor {
  ConnectivityPlusMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onOnlineChanged => _connectivity.onConnectivityChanged
      .map(isOnlineConnectivityResults)
      .handleError(
        (Object _) {},
        test: (error) => error is MissingPluginException,
      );

  @override
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return isOnlineConnectivityResults(results);
    } on MissingPluginException {
      return false;
    }
  }
}

class ConnectivitySyncListener {
  ConnectivitySyncListener({
    required NetworkConnectivityMonitor monitor,
    required Future<void> Function() onSyncRequested,
    void Function(Object error, StackTrace stackTrace)? onSyncError,
    this.debounceDuration = const Duration(milliseconds: 1500),
  })  : _monitor = monitor,
        _onSyncRequested = onSyncRequested,
        _onSyncError = onSyncError;

  final NetworkConnectivityMonitor _monitor;
  final Future<void> Function() _onSyncRequested;
  final void Function(Object error, StackTrace stackTrace)? _onSyncError;
  final Duration debounceDuration;

  StreamSubscription<bool>? _subscription;
  Timer? _debounceTimer;
  bool _isSyncInProgress = false;
  bool _wasOffline = false;
  bool _hasReceivedEvent = false;
  bool _disposed = false;

  bool get isSyncInProgress => _isSyncInProgress;

  Future<void> start() async {
    if (_disposed) return;

    await _subscription?.cancel();
    _hasReceivedEvent = false;
    _subscription = _monitor.onOnlineChanged.listen(_handleConnectivityChanged);

    final currentlyConnected = await _monitor.isConnected();
    if (!_disposed && !_hasReceivedEvent) {
      _wasOffline = !currentlyConnected;
    }
  }

  void _handleConnectivityChanged(bool isOnline) {
    if (_disposed) return;
    _hasReceivedEvent = true;

    if (!isOnline) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _wasOffline = true;
      return;
    }

    final isDebouncing = _debounceTimer?.isActive ?? false;
    if (_wasOffline || isDebouncing) {
      _wasOffline = false;
      _scheduleDebouncedSync();
    }
  }

  void _scheduleDebouncedSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _debounceTimer = null;
      unawaited(_executeSyncGuarded());
    });
  }

  Future<bool> triggerManualSync() async {
    if (_disposed || _isSyncInProgress) {
      return false;
    }

    _debounceTimer?.cancel();
    _debounceTimer = null;
    return _executeSyncGuarded();
  }

  Future<bool> _executeSyncGuarded() async {
    if (_disposed || _isSyncInProgress) {
      return false;
    }

    _isSyncInProgress = true;
    try {
      await _onSyncRequested();
      return true;
    } catch (error, stackTrace) {
      _onSyncError?.call(error, stackTrace);
      return false;
    } finally {
      _isSyncInProgress = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
