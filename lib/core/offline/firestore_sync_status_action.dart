import 'package:flutter/material.dart';

import 'firestore_sync_tracker.dart';

/// A small AppBar action that shows whether writes are still syncing.
class FirestoreSyncStatusAction extends StatelessWidget {
  const FirestoreSyncStatusAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FirestoreSyncStatus>(
      valueListenable: FirestoreSyncTracker.instance.status,
      builder: (context, s, _) {
        final icon = s.isSyncing
            ? Icons.cloud_upload_rounded
            : Icons.cloud_done_rounded;
        final tooltip = s.isSyncing ? 'Syncing…' : 'All changes synced';

        return IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) {
                String fmt(DateTime? dt) {
                  if (dt == null) return '—';
                  final hh = dt.hour.toString().padLeft(2, '0');
                  final mm = dt.minute.toString().padLeft(2, '0');
                  final ss = dt.second.toString().padLeft(2, '0');
                  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm:$ss';
                }

                return AlertDialog(
                  title: const Text('Sync status'),
                  content: Text(
                    'Status: ${s.isSyncing ? 'Syncing' : 'Up to date'}\n'
                    'Last write queued: ${fmt(s.lastWriteQueuedAt)}\n'
                    'Last sync: ${fmt(s.lastSyncedAt)}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
