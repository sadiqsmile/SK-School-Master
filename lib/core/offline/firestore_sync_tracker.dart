import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class FirestoreSyncStatus {
  const FirestoreSyncStatus({
    required this.isSyncing,
    this.lastWriteQueuedAt,
    this.lastSyncedAt,
  });

  final bool isSyncing;
  final DateTime? lastWriteQueuedAt;
  final DateTime? lastSyncedAt;

  FirestoreSyncStatus copyWith({
    bool? isSyncing,
    DateTime? lastWriteQueuedAt,
    DateTime? lastSyncedAt,
  }) {
    return FirestoreSyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      lastWriteQueuedAt: lastWriteQueuedAt ?? this.lastWriteQueuedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// A tiny, app-wide sync tracker to build user trust during weak internet.
///
/// This does *not* attempt to perfectly detect offline state. Instead:
/// - When a write is queued, call [notifyWriteQueued].
/// - When Firestore reports that snapshots are in sync, we flip back to "done".
class FirestoreSyncTracker {
  FirestoreSyncTracker._();

  static final FirestoreSyncTracker instance = FirestoreSyncTracker._();

  final ValueNotifier<FirestoreSyncStatus> status =
      ValueNotifier<FirestoreSyncStatus>(const FirestoreSyncStatus(isSyncing: false));

  StreamSubscription<void>? _sub;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    // Fires when all listeners are in sync with the backend.
    _sub = FirebaseFirestore.instance.snapshotsInSync().listen((_) {
      status.value = status.value.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void notifyWriteQueued() {
    status.value = status.value.copyWith(
      isSyncing: true,
      lastWriteQueuedAt: DateTime.now(),
    );
  }

  /// Best-effort: waits until pending writes are committed to the backend.
  ///
  /// If the device is offline, this will not complete; use [timeout] to avoid
  /// hanging the UI.
  Future<bool> waitForServerSync({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      await FirebaseFirestore.instance.waitForPendingWrites().timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
