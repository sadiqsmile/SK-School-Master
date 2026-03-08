import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/platform_status_provider.dart';
import 'package:school_app/providers/super_admin_provider.dart';
import 'package:school_app/services/reset_school_data_service.dart';

class ResetSchoolDataSheet extends ConsumerStatefulWidget {
  const ResetSchoolDataSheet({super.key});

  @override
  ConsumerState<ResetSchoolDataSheet> createState() => _ResetSchoolDataSheetState();
}

class _ResetSchoolDataSheetState extends ConsumerState<ResetSchoolDataSheet>
    with SingleTickerProviderStateMixin {
  final _resetConfirmController = TextEditingController();
  final _restoreConfirmController = TextEditingController();
  final _service = ResetSchoolDataService();

  // Target selection
  bool _allSchools = false;
  final Set<String> _selectedSchoolIds = <String>{};
  String _search = '';

  // Reset settings
  bool _backupConfirmed = false;
  bool _deleteAuthUsers = false;
  String? _backupId;
  Map<String, dynamic>? _backupResult;

  // Restore settings
  List<Map<String, dynamic>> _backups = <Map<String, dynamic>>[];
  String? _selectedBackupId;
  bool _overwriteConfirmed = false;
  bool _restoreAll = true;

  // UI state
  bool _busy = false;
  Map<String, dynamic>? _preview;
  String? _error;

  bool _arming = false;
  int _armSecondsLeft = 0;
  Timer? _timer;

  bool _restoreArming = false;
  int _restoreArmSecondsLeft = 0;
  Timer? _restoreTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _restoreTimer?.cancel();
    _resetConfirmController.dispose();
    _restoreConfirmController.dispose();
    super.dispose();
  }

  List<String> get _targetSchoolIds => _selectedSchoolIds.toList()..sort();

  String _expectedResetPhrase() {
    if (_allSchools) return 'DELETE ALL';
    if (_selectedSchoolIds.length == 1) {
      return 'DELETE ${_targetSchoolIds.first}'.toUpperCase();
    }
    return 'DELETE ${_selectedSchoolIds.length} SCHOOLS';
  }

  String _expectedRestorePhrase({required bool restoreAll}) {
    if (restoreAll) return 'RESTORE ALL';
    if (_selectedSchoolIds.length == 1) {
      return 'RESTORE ${_targetSchoolIds.first}'.toUpperCase();
    }
    return 'RESTORE ${_selectedSchoolIds.length} SCHOOLS';
  }

  bool get _hasTargets => _allSchools || _selectedSchoolIds.isNotEmpty;

  bool get _canCreateBackup => _hasTargets;

  bool get _canPreviewReset {
    if (!_hasTargets) return false;
    if (!_backupConfirmed) return false;
    final expected = _expectedResetPhrase().toUpperCase();
    final typed = _resetConfirmController.text.trim().toUpperCase();
    return typed == expected;
  }

  bool get _canArmReset {
    if (!_canPreviewReset) return false;
    // Enforce in-app snapshot must exist before arming.
    return (_backupId ?? '').trim().isNotEmpty;
  }

  bool get _canExecuteReset => _arming && _armSecondsLeft == 0 && _canArmReset;

  void _startArmResetCountdown() {
    _timer?.cancel();
    setState(() {
      _arming = true;
      _armSecondsLeft = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _armSecondsLeft = (_armSecondsLeft - 1).clamp(0, 999);
      });
      if (_armSecondsLeft <= 0) t.cancel();
    });
  }

  void _disarmReset() {
    _timer?.cancel();
    setState(() {
      _arming = false;
      _armSecondsLeft = 0;
    });
  }

  void _startArmRestoreCountdown() {
    _restoreTimer?.cancel();
    setState(() {
      _restoreArming = true;
      _restoreArmSecondsLeft = 5;
    });
    _restoreTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _restoreArmSecondsLeft = (_restoreArmSecondsLeft - 1).clamp(0, 999);
      });
      if (_restoreArmSecondsLeft <= 0) t.cancel();
    });
  }

  void _disarmRestore() {
    _restoreTimer?.cancel();
    setState(() {
      _restoreArming = false;
      _restoreArmSecondsLeft = 0;
    });
  }

  void _touchDangerInputs() {
    _disarmReset();
    _disarmRestore();
    setState(() {
      _preview = null;
      _error = null;
    });
  }

  Future<void> _createBackup() async {
    setState(() {
      _busy = true;
      _error = null;
      _backupResult = null;
      _backupId = null;
    });

    try {
      final res = await _service.createBackup(
        allSchools: _allSchools,
        schoolIds: _allSchools ? null : _targetSchoolIds,
      );
      if (!mounted) return;
      setState(() {
        _backupResult = res;
        _backupId = (res['backupId'] ?? '').toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _runPreviewReset() async {
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });

    try {
      final res = await _service.preview(
        allSchools: _allSchools,
        schoolIds: _allSchools ? null : _targetSchoolIds,
        confirmPhrase: _resetConfirmController.text,
        backupConfirmed: _backupConfirmed,
        deleteAuthUsers: _deleteAuthUsers,
      );
      if (!mounted) return;
      setState(() {
        _preview = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _executeReset() async {
    final bid = (_backupId ?? '').trim();
    if (bid.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final res = await _service.execute(
        allSchools: _allSchools,
        schoolIds: _allSchools ? null : _targetSchoolIds,
        backupId: bid,
        confirmPhrase: _resetConfirmController.text,
        backupConfirmed: _backupConfirmed,
        deleteAuthUsers: _deleteAuthUsers,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset completed.')),
      );
      Navigator.of(context).pop(res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _loadBackups() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final list = await _service.listBackups();
      if (!mounted) return;
      setState(() {
        _backups = list;
        _selectedBackupId = _selectedBackupId ?? (list.isNotEmpty ? list.first['backupId']?.toString() : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _executeRestore({required bool restoreAll}) async {
    final bid = (_selectedBackupId ?? '').trim();
    if (bid.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final res = await _service.restoreBackup(
        backupId: bid,
        restoreAll: restoreAll,
        schoolIds: restoreAll ? null : _targetSchoolIds,
        confirmPhrase: _restoreConfirmController.text,
        overwriteConfirmed: _overwriteConfirmed,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore completed.')),
      );
      Navigator.of(context).pop(res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceAsync = ref.watch(maintenanceModeProvider);
    final schoolsAsync = ref.watch(schoolsProvider);
    final maintenanceEnabled = maintenanceAsync.valueOrNull == true;

    final canRestoreSelected = _selectedSchoolIds.isNotEmpty;

    final resetExpected = _expectedResetPhrase();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Data Reset & Restore (Danger Zone)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'These tools can permanently delete or overwrite data.\n\n'
                  'Hard safety rules:\n'
                  '• Maintenance Mode must be ON\n'
                  '• Backup snapshot must be created before reset\n'
                  '• You must type the exact confirmation phrase\n'
                  '• Buttons unlock after a countdown\n\n'
                  'If you are not 100% sure, close this screen.',
                  style: TextStyle(height: 1.35, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              maintenanceAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load maintenance status: $e'),
                data: (enabled) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: enabled ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: enabled ? Colors.green.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          enabled ? Icons.verified_rounded : Icons.warning_rounded,
                          color: enabled ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            enabled
                                ? 'Maintenance Mode is ON (required)'
                                : 'Maintenance Mode is OFF — enable it on the dashboard first.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'Reset'),
                  Tab(text: 'Restore'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    // -----------------
                    // Reset tab
                    // -----------------
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CheckboxListTile(
                            value: _allSchools,
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() {
                                      _allSchools = v == true;
                                      if (_allSchools) {
                                        _selectedSchoolIds.clear();
                                      }
                                      _backupId = null;
                                      _backupResult = null;
                                    });
                                    _touchDangerInputs();
                                  },
                            title: const Text('Select ALL schools (wipe everything)'),
                            subtitle: const Text(
                              'This will delete ALL schools and ALL non-super-admin user docs.',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 8),
                          if (!_allSchools) ...[
                            TextField(
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Search schools',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _search = v;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            schoolsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Failed to load schools: $e'),
                              data: (snap) {
                                final query = _search.trim().toLowerCase();
                                final docs = snap.docs.where((d) {
                                  final data = d.data();
                                  final name = (data['name'] ?? data['schoolName'] ?? '').toString();
                                  final hay = '${d.id} $name'.toLowerCase();
                                  return query.isEmpty || hay.contains(query);
                                }).toList();

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Selected: ${_selectedSchoolIds.length}',
                                                style: const TextStyle(fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _selectedSchoolIds
                                                          ..clear()
                                                          ..addAll(docs.map((d) => d.id));
                                                        _backupId = null;
                                                        _backupResult = null;
                                                      });
                                                      _touchDangerInputs();
                                                    },
                                              child: const Text('Select all (filtered)'),
                                            ),
                                            TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _selectedSchoolIds.clear();
                                                        _backupId = null;
                                                        _backupResult = null;
                                                      });
                                                      _touchDangerInputs();
                                                    },
                                              child: const Text('Clear'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      SizedBox(
                                        height: 240,
                                        child: ListView.builder(
                                          itemCount: docs.length,
                                          itemBuilder: (context, i) {
                                            final d = docs[i];
                                            final data = d.data();
                                            final name = (data['name'] ?? data['schoolName'] ?? '').toString();
                                            final checked = _selectedSchoolIds.contains(d.id);
                                            return CheckboxListTile(
                                              value: checked,
                                              onChanged: _busy
                                                  ? null
                                                  : (v) {
                                                      setState(() {
                                                        if (v == true) {
                                                          _selectedSchoolIds.add(d.id);
                                                        } else {
                                                          _selectedSchoolIds.remove(d.id);
                                                        }
                                                        _backupId = null;
                                                        _backupResult = null;
                                                      });
                                                      _touchDangerInputs();
                                                    },
                                              title: Text(name.isNotEmpty ? name : d.id),
                                              subtitle: Text(d.id),
                                              controlAffinity: ListTileControlAffinity.leading,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: (_busy || !maintenanceEnabled || !_canCreateBackup)
                                  ? null
                                  : _createBackup,
                              icon: const Icon(Icons.backup_rounded),
                              label: const Text('Create backup snapshot (required)'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_backupId != null && _backupId!.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'Backup created: $_backupId\n${_backupResult ?? {}}',
                                style: const TextStyle(fontSize: 12.5, height: 1.3),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          CheckboxListTile(
                            value: _backupConfirmed,
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() {
                                      _backupConfirmed = v == true;
                                    });
                                    _touchDangerInputs();
                                  },
                            title: const Text('I confirm I took a backup before wipe'),
                            subtitle: const Text(
                              'This reset requires a backup snapshot (created above). '
                              'For best safety also export Firestore to Cloud Storage.',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confirmation phrase (type exactly): ${resetExpected.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _resetConfirmController,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Type the phrase here',
                            ),
                            onChanged: (_) => _touchDangerInputs(),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            value: _deleteAuthUsers,
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() {
                                      _deleteAuthUsers = v;
                                    });
                                    _touchDangerInputs();
                                  },
                            title: const Text('Also delete Firebase Auth users (very dangerous)'),
                            subtitle: const Text(
                              'This attempts to delete Auth users for affected schools. '
                              'Recommended OFF unless you truly want to remove teacher/parent accounts.',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: (_busy || !_canPreviewReset || !maintenanceEnabled)
                                      ? null
                                      : _runPreviewReset,
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Preview'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: (_busy || !_canArmReset || !maintenanceEnabled)
                                      ? null
                                      : _startArmResetCountdown,
                                  icon: const Icon(Icons.lock_open_rounded),
                                  label: Text(_arming ? 'Armed' : 'Arm reset'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_preview != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'Preview:\n${_preview.toString()}',
                                style: const TextStyle(fontSize: 12.5, height: 1.3),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_arming && _armSecondsLeft > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text(
                                'Reset button unlocks in $_armSecondsLeft seconds…',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.red.shade200,
                                disabledForegroundColor: Colors.white70,
                              ),
                              onPressed: (_busy || !_canExecuteReset) ? null : _executeReset,
                              icon: const Icon(Icons.delete_forever_rounded),
                              label: Text(_busy ? 'Working…' : 'RESET NOW'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: (_busy || !_arming) ? null : _disarmReset,
                            child: const Text('Disarm'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    // -----------------
                    // Restore tab
                    // -----------------
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Restore will overwrite current Firestore data with a selected backup snapshot.',
                            style: TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _loadBackups,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Load backups'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Select backup',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedBackupId,
                                hint: const Text('Choose a backup'),
                                items: _backups
                                    .map(
                                      (b) => DropdownMenuItem<String>(
                                        value: b['backupId']?.toString(),
                                        child: Text(
                                          '${b['backupId']}  (${b['status'] ?? 'unknown'})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _busy
                                    ? null
                                    : (v) {
                                        setState(() {
                                          _selectedBackupId = v;
                                        });
                                        _touchDangerInputs();
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            value: _restoreAll,
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() {
                                      _restoreAll = v;
                                    });
                                    _touchDangerInputs();
                                  },
                            title: const Text('Restore ALL schools from this backup'),
                            subtitle: const Text(
                              'Turn OFF to restore only the selected schools (from the Reset tab selection).',
                            ),
                          ),
                          const SizedBox(height: 6),
                          CheckboxListTile(
                            value: _overwriteConfirmed,
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() {
                                      _overwriteConfirmed = v == true;
                                    });
                                    _touchDangerInputs();
                                  },
                            title: const Text('I understand this will overwrite current data'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _restoreAll
                                ? 'Confirmation phrase (type exactly): ${_expectedRestorePhrase(restoreAll: true).toUpperCase()}'
                                : (canRestoreSelected
                                    ? 'Confirmation phrase (type exactly): ${_expectedRestorePhrase(restoreAll: false).toUpperCase()}'
                                    : 'Select at least 1 school in the Reset tab first'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _restoreConfirmController,
                            enabled: !_busy && (_restoreAll || canRestoreSelected),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Type the phrase here',
                            ),
                            onChanged: (_) => _touchDangerInputs(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: (_busy ||
                                          !maintenanceEnabled ||
                                          !_overwriteConfirmed ||
                                          (_restoreAll ? false : !canRestoreSelected))
                                      ? null
                                      : _startArmRestoreCountdown,
                                  icon: const Icon(Icons.lock_open_rounded),
                                  label: Text(_restoreArming ? 'Armed' : 'Arm restore'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: (_busy || !_restoreArming) ? null : _disarmRestore,
                                  child: const Text('Disarm'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_restoreArming && _restoreArmSecondsLeft > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text(
                                'Restore button unlocks in $_restoreArmSecondsLeft seconds…',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange.shade700,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.deepOrange.shade200,
                                disabledForegroundColor: Colors.white70,
                              ),
                              onPressed: (_busy || !_restoreArming || _restoreArmSecondsLeft > 0)
                                  ? null
                                  : () {
                                      final expected = _expectedRestorePhrase(restoreAll: _restoreAll);
                                      if (_restoreConfirmController.text.trim().toUpperCase() != expected) {
                                        setState(() {
                                          _error = 'Type the exact phrase: $expected';
                                        });
                                        return;
                                      }
                                      _executeRestore(restoreAll: _restoreAll);
                                    },
                              icon: const Icon(Icons.restore_rounded),
                              label: Text(_busy ? 'Working…' : 'RESTORE NOW'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Restore copies Firestore data only. Firebase Auth accounts/passwords are not restored automatically.',
                              style: TextStyle(fontSize: 12.5, height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
