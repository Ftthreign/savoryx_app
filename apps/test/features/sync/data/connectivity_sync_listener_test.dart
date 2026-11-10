import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/sync/data/datasources/connectivity_sync_listener.dart';

class FakeNetworkConnectivityMonitor implements NetworkConnectivityMonitor {
  FakeNetworkConnectivityMonitor({this.initialConnected = false});

  bool initialConnected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onOnlineChanged => _controller.stream;

  @override
  Future<bool> isConnected() async => initialConnected;

  void emit(bool isOnline) {
    initialConnected = isOnline;
    _controller.add(isOnline);
  }

  Future<void> close() => _controller.close();
}

void main() {
  group('isOnlineConnectivityResults', () {
    test('returns false when results are empty or contain only none', () {
      expect(isOnlineConnectivityResults(const []), isFalse);
      expect(
        isOnlineConnectivityResults(const [ConnectivityResult.none]),
        isFalse,
      );
    });

    test('returns true when wifi, mobile, or ethernet is present', () {
      expect(
        isOnlineConnectivityResults(const [ConnectivityResult.wifi]),
        isTrue,
      );
      expect(
        isOnlineConnectivityResults(const [ConnectivityResult.mobile]),
        isTrue,
      );
      expect(
        isOnlineConnectivityResults(const [ConnectivityResult.ethernet]),
        isTrue,
      );
    });
  });

  group('ConnectivitySyncListener (Task #46)', () {
    late FakeNetworkConnectivityMonitor monitor;

    setUp(() {
      monitor = FakeNetworkConnectivityMonitor(initialConnected: false);
    });

    tearDown(() async {
      await monitor.close();
    });

    test('debounces offline-to-online transition for exactly 1500ms', () {
      fakeAsync((async) {
        var syncCalls = 0;
        final listener = ConnectivitySyncListener(
          monitor: monitor,
          onSyncRequested: () async {
            syncCalls++;
          },
        );

        listener.start();
        async.flushMicrotasks();

        // Transition offline -> online
        monitor.emit(true);
        async.flushMicrotasks();

        // Must NOT trigger before 1500ms
        async.elapse(const Duration(milliseconds: 1499));
        expect(syncCalls, equals(0));

        // Triggers right at 1500ms
        async.elapse(const Duration(milliseconds: 1));
        expect(syncCalls, equals(1));

        listener.dispose();
        async.flushMicrotasks();
      });
    });

    test('suppresses rapid network flapping and restarts 1500ms debounce timer',
        () {
      fakeAsync((async) {
        var syncCalls = 0;
        final listener = ConnectivitySyncListener(
          monitor: monitor,
          onSyncRequested: () async {
            syncCalls++;
          },
        );

        listener.start();
        async.flushMicrotasks();

        // t=0: online
        monitor.emit(true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        expect(syncCalls, equals(0));

        // t=600ms: drops offline -> cancels debounce timer
        monitor.emit(false);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1200));
        expect(syncCalls, equals(0));

        // t=1800ms: recovers online -> starts fresh 1500ms debounce
        monitor.emit(true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1499));
        expect(syncCalls, equals(0));

        // t=3300ms (1500ms after stable reconnect): fires once
        async.elapse(const Duration(milliseconds: 1));
        expect(syncCalls, equals(1));

        listener.dispose();
        async.flushMicrotasks();
      });
    });

    test('ignores duplicate triggers while sync is already in progress',
        () async {
      final firstSyncCompleter = Completer<void>();
      var syncCalls = 0;

      final listener = ConnectivitySyncListener(
        monitor: monitor,
        debounceDuration: const Duration(milliseconds: 10),
        onSyncRequested: () async {
          syncCalls++;
          if (syncCalls == 1) {
            await firstSyncCompleter.future;
          }
        },
      );

      await listener.start();

      // Start manual sync (holds lock until firstSyncCompleter completes)
      final firstFuture = listener.triggerManualSync();
      expect(listener.isSyncInProgress, isTrue);

      // Concurrent manual trigger while locked returns false immediately
      final blockedManual = await listener.triggerManualSync();
      expect(blockedManual, isFalse);
      expect(syncCalls, equals(1));

      // Connectivity reconnect while first sync is in progress is also guarded
      monitor.emit(true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(syncCalls, equals(1));

      // Release lock and verify manual sync works again
      firstSyncCompleter.complete();
      expect(await firstFuture, isTrue);
      expect(listener.isSyncInProgress, isFalse);

      expect(await listener.triggerManualSync(), isTrue);
      expect(syncCalls, equals(2));

      await listener.dispose();
    });

    test('resets lock cleanly even when onSyncRequested throws and blocks after dispose',
        () async {
      Object? capturedError;
      var attempts = 0;
      final listener = ConnectivitySyncListener(
        monitor: monitor,
        onSyncRequested: () async {
          attempts++;
          if (attempts == 1) {
            throw StateError('transient network error');
          }
        },
        onSyncError: (error, _) {
          capturedError = error;
        },
      );

      await listener.start();

      final firstResult = await listener.triggerManualSync();
      expect(firstResult, isFalse);
      expect(capturedError, isA<StateError>());
      expect(listener.isSyncInProgress, isFalse);

      // Subsequent manual sync recovers cleanly
      final retryResult = await listener.triggerManualSync();
      expect(retryResult, isTrue);
      expect(attempts, equals(2));

      await listener.dispose();
      expect(await listener.triggerManualSync(), isFalse);
    });
  });
}
