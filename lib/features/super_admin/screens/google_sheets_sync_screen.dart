import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/super_admin_provider.dart';
import 'package:school_app/features/super_admin/services/google_sheets_sync_service.dart';

class GoogleSheetsSyncScreen extends ConsumerStatefulWidget {
  const GoogleSheetsSyncScreen({super.key});

  @override
  ConsumerState<GoogleSheetsSyncScreen> createState() => _GoogleSheetsSyncScreenState();
}

class _GoogleSheetsSyncScreenState extends ConsumerState<GoogleSheetsSyncScreen> {
  final _service = GoogleSheetsSyncService();

  String? _schoolId;
  bool _enabled = false;
  int _daysBack = 30;
  int _maxRowsPerTab = 20000;

  final _spreadsheetIdCtrl = TextEditingController();
  final _daysBackCtrl = TextEditingController();
  final _maxRowsCtrl = TextEditingController();

  bool _loadingCfg = false;
  bool _saving = false;
  bool _syncing = false;

  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _daysBackCtrl.text = '$_daysBack';
    _maxRowsCtrl.text = '$_maxRowsPerTab';
  }

  @override
  void dispose() {
    _spreadsheetIdCtrl.dispose();
    _daysBackCtrl.dispose();
    _maxRowsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final sid = _schoolId;
    if (sid == null || sid.trim().isEmpty) return;

    setState(() {
      _loadingCfg = true;
      _lastResult = null;
    });

    try {
      final cfg = await _service.getConfig(schoolId: sid);
      if (!mounted) return;

      setState(() {
        _enabled = cfg?.enabled ?? false;
        _daysBack = cfg?.daysBack ?? 30;
        _maxRowsPerTab = cfg?.maxRowsPerTab ?? 20000;
        _spreadsheetIdCtrl.text = cfg?.spreadsheetId ?? '';
        _daysBackCtrl.text = '$_daysBack';
        _maxRowsCtrl.text = '$_maxRowsPerTab';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load config: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingCfg = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    final sid = _schoolId;
    if (sid == null || sid.trim().isEmpty) return;

    final spreadsheetId = _spreadsheetIdCtrl.text.trim();
    if (_enabled && spreadsheetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spreadsheet ID is required when enabled.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _lastResult = null;
    });

    try {
      await _service.setConfig(
        schoolId: sid,
        enabled: _enabled,
        spreadsheetId: spreadsheetId,
        daysBack: _daysBack,
        maxRowsPerTab: _maxRowsPerTab,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sheets sync config saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _syncNow() async {
    final sid = _schoolId;
    if (sid == null || sid.trim().isEmpty) return;

    if (!_enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable sync first (then Save).')),
      );
      return;
    }

    setState(() {
      _syncing = true;
      _lastResult = null;
    });

    try {
      final res = await _service.syncNow(
        schoolId: sid,
        daysBack: _daysBack,
        maxRowsPerTab: _maxRowsPerTab,
      );
      if (!mounted) return;

      setState(() {
        _lastResult = res;
      });

      final counts = res['counts'];
      final countText = counts is Map
          ? 'students=${counts['students'] ?? '-'}, fees=${counts['fees'] ?? '-'}, marks=${counts['marks'] ?? '-'}, attendance=${counts['attendance'] ?? '-'}'
          : 'done';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced to Google Sheets ($countText).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF1F5F9);
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Sync'),
      ),
      body: Container(
        color: bg,
        child: schoolsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load schools: $e')),
          data: (snapshot) {
            final schools = snapshot.docs
                .map((d) {
                  final data = d.data();
                  final name = (data['name'] ?? data['schoolName'] ?? '').toString();
                  final id = (data['schoolId'] ?? d.id).toString();
                  return (id: id, name: name.isEmpty ? id : name);
                })
                .toList(growable: false)
              ..sort((a, b) => a.name.compareTo(b.name));

            if (schools.isNotEmpty && (_schoolId == null || _schoolId!.trim().isEmpty)) {
              _schoolId = schools.first.id;
              // Load config once on first build.
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'What this does',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Exports school data into a Google Spreadsheet (tabs: students, teachers, parents, fees, marks, attendance).\n\nSecurity-first defaults:\n- Super Admin only\n- Uses server-side credentials (no keys in the app)\n- Does NOT export sensitive Auth/PIN fields\n- Attendance is limited to last N days and capped to avoid huge exports',
                          style: TextStyle(color: Color(0xFF475569), height: 1.35),
                        ),
                        const SizedBox(height: 14),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'School',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: schools.any((s) => s.id == _schoolId) ? _schoolId : null,
                              isExpanded: true,
                              items: [
                                for (final s in schools)
                                  DropdownMenuItem(
                                    value: s.id,
                                    child: Text('${s.name}  •  ${s.id}'),
                                  ),
                              ],
                              onChanged: (_saving || _syncing || _loadingCfg)
                                  ? null
                                  : (v) async {
                                      setState(() {
                                        _schoolId = v;
                                      });
                                      await _loadConfig();
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Google Sheets Sync'),
                          subtitle: const Text('Disabled by default (recommended).'),
                          value: _enabled,
                          onChanged: (_saving || _syncing || _loadingCfg)
                              ? null
                              : (v) => setState(() => _enabled = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spreadsheetIdCtrl,
                          enabled: !(_saving || _syncing || _loadingCfg),
                          decoration: const InputDecoration(
                            labelText: 'Spreadsheet ID',
                            hintText: 'Example: 1AbCDefGhIJKlmnOPqrsTUVwxyz...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                enabled: !(_saving || _syncing || _loadingCfg),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Attendance days back',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _daysBackCtrl,
                                onChanged: (v) {
                                  final n = int.tryParse(v.trim());
                                  if (n != null) setState(() => _daysBack = n.clamp(1, 120));
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                enabled: !(_saving || _syncing || _loadingCfg),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max rows / tab',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _maxRowsCtrl,
                                onChanged: (v) {
                                  final n = int.tryParse(v.trim());
                                  if (n != null) setState(() => _maxRowsPerTab = n.clamp(1000, 100000));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_loadingCfg)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(),
                          ),
                        FilledButton.icon(
                          onPressed: (_saving || _syncing || _loadingCfg) ? null : _saveConfig,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_saving ? 'Saving…' : 'Save'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: (_saving || _syncing || _loadingCfg) ? null : _syncNow,
                          icon: _syncing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync_rounded),
                          label: Text(_syncing ? 'Syncing…' : 'Sync now'),
                        ),
                        if (_lastResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              _lastResult.toString(),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Tip: share the spreadsheet with your Firebase service account email (PROJECT_ID@appspot.gserviceaccount.com).',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
