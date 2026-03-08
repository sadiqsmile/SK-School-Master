import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/super_admin/services/backfill_service.dart';
import 'package:school_app/providers/super_admin_provider.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String? _schoolId;

  bool _students = true;
  bool _teachers = true;
  bool _exams = true;
  bool _homework = true;

  bool _running = false;
  BackfillResult? _result;
  final List<String> _logs = [];

  void _log(String msg) {
    setState(() {
      _logs.insert(0, msg);
    });
  }

  Future<void> _run() async {
    final messenger = ScaffoldMessenger.of(context);
    final schoolId = _schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a school.')),
      );
      return;
    }

    setState(() {
      _running = true;
      _result = null;
      _logs.clear();
    });

    try {
      final service = BackfillService();
      final result = await service.backfillSchool(
        schoolId: schoolId,
        options: BackfillOptions(
          students: _students,
          teachers: _teachers,
          exams: _exams,
          homework: _homework,
        ),
        onProgress: (p) => _log(p.message),
      );

      if (!mounted) return;

      setState(() {
        _result = result;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Backfill completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Backfill failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
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
        title: const Text('Maintenance & Backfill'),
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
                          'Backfill required security fields',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This writes missing normalized fields used by Firestore rules, like classKey and assignmentKeys. Run once before launch (or after migrating legacy data).',
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
                              onChanged: _running
                                  ? null
                                  : (v) => setState(() {
                                        _schoolId = v;
                                      }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Toggle(
                          title: 'Students → backfill classKey',
                          subtitle: 'schools/{schoolId}/students',
                          value: _students,
                          onChanged: _running ? null : (v) => setState(() => _students = v),
                        ),
                        _Toggle(
                          title: 'Teachers → backfill assignmentKeys',
                          subtitle: 'schools/{schoolId}/teachers',
                          value: _teachers,
                          onChanged: _running ? null : (v) => setState(() => _teachers = v),
                        ),
                        _Toggle(
                          title: 'Exams → backfill classKey',
                          subtitle: 'schools/{schoolId}/exams',
                          value: _exams,
                          onChanged: _running ? null : (v) => setState(() => _exams = v),
                        ),
                        _Toggle(
                          title: 'Homework → backfill classKey',
                          subtitle: 'schools/{schoolId}/homework',
                          value: _homework,
                          onChanged: _running ? null : (v) => setState(() => _homework = v),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _running ? null : _run,
                          icon: _running
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_circle_fill_rounded),
                          label: Text(_running ? 'Running…' : 'Run Backfill'),
                        ),
                        if (_result != null) ...[
                          const SizedBox(height: 12),
                          _ResultCard(result: _result!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logs',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_logs.isEmpty)
                          const Text(
                            'No logs yet. Run backfill to see progress here.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          )
                        else
                          ..._logs.take(40).map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    m,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
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

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final BackfillResult result;

  @override
  Widget build(BuildContext context) {
    final errors = result.errors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Students: updated ${result.studentsUpdated} / scanned ${result.studentsScanned}'),
          Text('Teachers: updated ${result.teachersUpdated} / scanned ${result.teachersScanned}'),
          Text('Exams: updated ${result.examsUpdated} / scanned ${result.examsScanned}'),
          Text('Homework: updated ${result.homeworkUpdated} / scanned ${result.homeworkScanned}'),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Errors', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            for (final e in errors.take(5)) Text('• $e'),
            if (errors.length > 5)
              Text('…and ${errors.length - 5} more.'),
          ],
        ],
      ),
    );
  }
}
