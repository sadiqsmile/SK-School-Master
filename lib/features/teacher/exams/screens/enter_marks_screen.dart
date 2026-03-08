import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/providers/students_by_class_provider.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/providers/exam_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/exam_service.dart';
import 'package:school_app/core/offline/firestore_sync_tracker.dart';
import 'package:school_app/core/offline/firestore_sync_status_action.dart';

class EnterMarksScreen extends ConsumerStatefulWidget {
  const EnterMarksScreen({
    super.key,
    required this.exam,
    required this.classId,
    required this.sectionId,
  });

  final Exam exam;
  final String classId;
  final String sectionId;

  @override
  ConsumerState<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends ConsumerState<EnterMarksScreen> {
  final _subjectController = TextEditingController(text: 'math');
  final _maxMarksController = TextEditingController(text: '50');

  final Map<String, TextEditingController> _markControllers = {};
  String _lastSyncedSubjectKey = '';

  @override
  void dispose() {
    _subjectController.dispose();
    _maxMarksController.dispose();
    for (final c in _markControllers.values) {
      c.dispose();
    }
    _markControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolIdAsync = ref.watch(schoolIdProvider);
    final studentsAsync = ref.watch(studentsByClassProvider((widget.classId, widget.sectionId)));
    final marksAsync = ref.watch(examMarksProvider(widget.exam.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enter Marks • ${widget.exam.examName.isEmpty ? 'Exam' : widget.exam.examName}',
        ),
        actions: const [
          FirestoreSyncStatusAction(),
        ],
      ),
      body: schoolIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load school: $e')),
        data: (schoolId) {
          return studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load students: $e')),
            data: (studentsSnap) {
              final students = studentsSnap.docs
                  .map((d) => Student.fromMap(d.id, d.data()))
                  .toList(growable: false)
                ..sort((a, b) => a.name.compareTo(b.name));

              // Ensure controllers exist.
              for (final s in students) {
                _markControllers.putIfAbsent(s.id, () => TextEditingController());
              }

              return marksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load existing marks: $e')),
                data: (marksSnap) {
                  final subjectKey = _normalizedSubjectKey(_subjectController.text);

                  final marksByStudentId = <String, ExamMarks>{
                    for (final d in marksSnap.docs) d.id: ExamMarks.fromDoc(d),
                  };

                  // Prefill controllers for this subject, only when subject changes.
                  if (_lastSyncedSubjectKey != subjectKey) {
                    _syncControllersFromExisting(
                      subjectKey: subjectKey,
                      students: students,
                      marksByStudentId: marksByStudentId,
                    );
                    _lastSyncedSubjectKey = subjectKey;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _TopControls(
                        subjectController: _subjectController,
                        maxMarksController: _maxMarksController,
                        onQuickSubject: (s) {
                          setState(() {
                            _subjectController.text = s;
                            _lastSyncedSubjectKey = '';
                          });
                        },
                        onChanged: () {
                          setState(() {
                            _lastSyncedSubjectKey = '';
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Enter marks quickly',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () => _save(
                                  context: context,
                                  schoolId: schoolId,
                                  students: students,
                                ),
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('Save'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final s in students)
                        Card(
                          child: ListTile(
                            title: Text(s.name.isEmpty ? s.id : s.name),
                            subtitle: Text('Adm: ${s.admissionNo}'),
                            trailing: SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _markControllers[s.id],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 60),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _syncControllersFromExisting({
    required String subjectKey,
    required List<Student> students,
    required Map<String, ExamMarks> marksByStudentId,
  }) {
    for (final s in students) {
      final c = _markControllers[s.id];
      if (c == null) continue;

      // Only prefill if blank to avoid overriding user edits.
      if (c.text.trim().isNotEmpty) continue;

      final existing = marksByStudentId[s.id]?.subjectMarks[subjectKey];
      if (existing == null) continue;
      c.text = existing.toString();
    }
  }

  Future<void> _save({
    required BuildContext context,
    required String schoolId,
    required List<Student> students,
  }) async {
    final subjectKey = _normalizedSubjectKey(_subjectController.text);
    final maxMarks = int.tryParse(_maxMarksController.text.trim()) ?? 0;

    if (subjectKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject (e.g. math)')),
      );
      return;
    }

    if (maxMarks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid max marks (e.g. 50)')),
      );
      return;
    }

    final Map<String, int> marksByStudentId = {};

    for (final s in students) {
      final raw = _markControllers[s.id]?.text.trim() ?? '';
      if (raw.isEmpty) continue;

      final v = int.tryParse(raw);
      if (v == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid mark for ${s.name.isEmpty ? s.id : s.name}')),
        );
        return;
      }

      if (v < 0 || v > maxMarks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marks must be between 0 and $maxMarks')),
        );
        return;
      }

      marksByStudentId[s.id] = v;
    }

    try {
      await ExamService().saveSubjectMarks(
        schoolId: schoolId,
        examId: widget.exam.id,
        subjectKey: subjectKey,
        maxMarks: maxMarks,
        marksByStudentId: marksByStudentId,
      );

      FirestoreSyncTracker.instance.notifyWriteQueued();
      final synced = await FirestoreSyncTracker.instance.waitForServerSync(
        timeout: const Duration(seconds: 2),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced
                  ? 'Marks saved'
                  : 'Marks saved locally — will sync when internet returns',
            ),
          ),
        );
      }

      // Reset controllers so a subject change re-syncs fresh.
      setState(() {
        _lastSyncedSubjectKey = '';
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.subjectController,
    required this.maxMarksController,
    required this.onQuickSubject,
    required this.onChanged,
  });

  final TextEditingController subjectController;
  final TextEditingController maxMarksController;
  final ValueChanged<String> onQuickSubject;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Setup',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject key',
                      hintText: 'math',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: maxMarksController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      hintText: '50',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in const ['math', 'english', 'science', 'social', 'hindi'])
                  ActionChip(
                    label: Text(_prettySubject(s)),
                    onPressed: () => onQuickSubject(s),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tip: Subject key is stored in Firestore (lowercase). Example: math, english, science',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizedSubjectKey(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('-', '_');
}

String _prettySubject(String key) {
  final cleaned = key.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}
