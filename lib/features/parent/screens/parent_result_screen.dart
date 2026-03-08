import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/parent/providers/parent_children_provider.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/providers/exam_provider.dart';

class ParentResultScreen extends ConsumerStatefulWidget {
  const ParentResultScreen({super.key});

  @override
  ConsumerState<ParentResultScreen> createState() => _ParentResultScreenState();
}

class _ParentResultScreenState extends ConsumerState<ParentResultScreen> {
  String? _selectedExamId;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);

    if (child == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select a child to view results.'),
        ),
      );
    }

    final examsAsync = ref.watch(
      examsByClassProvider(ExamClassKey(classId: child.classId, section: child.section)),
    );

    return examsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load exams: $e')),
      data: (snapshot) {
        final exams = snapshot.docs.map(Exam.fromDoc).toList(growable: false);

        final sorted = [...exams]
          ..sort((a, b) {
            final aTs = a.createdAt;
            final bTs = b.createdAt;
            if (aTs == null && bTs == null) return a.name.compareTo(b.name);
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

        if (sorted.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No exams available yet.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          );
        }

        _selectedExamId ??= sorted.first.id;

        final examId = _selectedExamId ?? sorted.first.id;

        final examDocAsync = ref.watch(examDocProvider(examId));
        final marksAsync = ref.watch(
          studentExamMarksProvider((examId: examId, studentId: child.id)),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${child.name.isEmpty ? child.id : child.name} — Class ${child.classId}${child.section}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: examId,
              decoration: const InputDecoration(
                labelText: 'Select exam',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in sorted)
                  DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name.trim().isEmpty ? '(Untitled)' : e.name.trim()),
                  ),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedExamId = v;
                });
              },
            ),
            const SizedBox(height: 12),
            examDocAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load exam details: $e'),
              data: (doc) {
                final exam = Exam.fromDoc(doc);
                final subjectMax = exam.subjectMaxMarks;

                return marksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text('Failed to load marks: $e'),
                  data: (marksDoc) {
                    final marks = marksDoc.exists ? ExamMarks.fromDoc(marksDoc) : null;
                    final subjectMarks = marks?.subjectMarks ?? const <String, int>{};

                    final calc = _calcTotals(subjectMarks: subjectMarks, subjectMaxMarks: subjectMax);
                    final subjects = subjectMarks.keys.toList(growable: false)..sort();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.examName.trim().isEmpty
                                      ? 'Exam'
                                      : exam.examName.trim(),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                if (exam.examType.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    exam.examType.trim(),
                                    style: const TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text('Total: ${calc.total} / ${calc.outOf}'),
                                Text('Grade: ${_grade(calc.percent)}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (subjects.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Marks have not been entered yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                          )
                        else
                          for (final s in subjects)
                            Card(
                              child: ListTile(
                                title: Text(_prettySubject(s)),
                                trailing: Text(
                                  '${subjectMarks[s] ?? 0} / ${subjectMax[s] ?? 50}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

({int total, int outOf, double percent}) _calcTotals({
  required Map<String, int> subjectMarks,
  required Map<String, int> subjectMaxMarks,
}) {
  var total = 0;
  var outOf = 0;

  for (final e in subjectMarks.entries) {
    final subj = e.key;
    final mark = e.value;
    final max = subjectMaxMarks[subj] ?? 50;
    total += mark;
    outOf += max;
  }

  final percent = outOf <= 0 ? 0.0 : (total / outOf) * 100.0;
  return (total: total, outOf: outOf, percent: percent);
}

String _grade(double percent) {
  if (percent >= 90) return 'A+';
  if (percent >= 80) return 'A';
  if (percent >= 70) return 'B';
  if (percent >= 60) return 'C';
  if (percent >= 50) return 'D';
  return 'F';
}

String _prettySubject(String key) {
  final cleaned = key.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}
