import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:school_app/features/super_admin/services/platform_file_backup_service.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final _service = PlatformFileBackupService();

  bool _busy = false;
  List<PlatformFileBackupItem> _backups = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
    });

    try {
      final items = await _service.listFileBackups();
      if (!mounted) return;
      setState(() {
        _backups = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _runGuarded(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await fn();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createBackupAll() async {
    await _runGuarded(() async {
      final result = await _service.createFileBackup(allSchools: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup started: ${result.backupFileId}')),
      );

      await _refresh();
    });
  }

  Future<void> _download(PlatformFileBackupItem item) async {
    await _runGuarded(() async {
      final uri = await _service.getDownloadUrl(backupFileId: item.backupFileId);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open download URL');
      }
    });
  }

  String _expectedRestorePhrase(PlatformFileBackupItem item) {
    if (item.allSchools) return 'RESTORE ALL';
    if (item.schoolIds.length == 1) return 'RESTORE ${item.schoolIds.first}';
    return 'RESTORE ${item.schoolIds.length} SCHOOLS';
  }

  Future<void> _restore(PlatformFileBackupItem item) async {
    final expected = _expectedRestorePhrase(item);
    final controller = TextEditingController();

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Restore from file backup?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will DELETE existing Firestore data for the selected scope and restore from the backup file.',
                  style: TextStyle(color: Colors.red.shade800, height: 1.3),
                ),
                const SizedBox(height: 12),
                const Text('Type the exact phrase to confirm:'),
                const SizedBox(height: 6),
                SelectableText(
                  expected,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation phrase',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Requires Maintenance Mode enabled.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );

      if (ok != true) return;

      final phrase = controller.text.trim();
      await _runGuarded(() async {
        await _service.restoreFileBackup(
          backupFileId: item.backupFileId,
          restoreAll: true,
          schoolIds: null,
          overwriteConfirmed: true,
          confirmPhrase: phrase,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore completed.')),
        );
      });
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C896);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.black.withAlpha(15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Single-file backup (server-generated)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Creates a single .jsonl.gz backup file in Cloud Storage and registers it in Firestore.\n\nNotes:\n• Requires Maintenance Mode enabled.\n• Backup contains schools/* trees plus users + parentPhones for the selected schools.\n• Firebase Auth users/passwords are NOT included.',
                    style: TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _createBackupAll,
                      icon: const Icon(Icons.backup_rounded),
                      label: const Text(
                        'Create backup (ALL schools)',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Recent backups',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (_backups.isEmpty)
            const Text(
              'No backups found yet.',
              style: TextStyle(color: Colors.black54),
            )
          else
            for (final b in _backups)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.black.withAlpha(12)),
                ),
                child: ListTile(
                  title: Text(
                    b.backupFileId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${b.status} • ${b.allSchools ? 'ALL schools' : '${b.schoolIds.length} schools'}'
                    '${b.createdAtIso != null ? ' • ${b.createdAtIso}' : ''}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Download',
                        onPressed: _busy ? null : () => _download(b),
                        icon: const Icon(Icons.download_rounded),
                      ),
                      IconButton(
                        tooltip: 'Restore',
                        onPressed: _busy ? null : () => _restore(b),
                        icon: Icon(Icons.restore_rounded, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
