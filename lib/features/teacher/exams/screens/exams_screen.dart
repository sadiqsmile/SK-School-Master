import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/providers/students_by_class_provider.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/core/utils/marks_calc.dart';
import 'package:school_app/models/grading_system.dart';
import 'package:school_app/providers/grading_system_provider.dart';
import 'package:school_app/providers/exam_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/exam_service.dart';
import 'package:school_app/core/offline/firestore_sync_status_action.dart';

import 'enter_marks_screen.dart';
import 'create_exam_screen.dart';

class TeacherExamsScreen extends ConsumerWidget {
  const TeacherExamsScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolIdAsync = ref.watch(schoolIdProvider);

    return schoolIdAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Exams')),
        body: Center(child: Text(e.toString())),
      ),
      data: (schoolId) {
        final examsAsync = ref.watch(
          examsByClassProvider(ExamClassKey(classId: classId, section: sectionId)),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Exams $classId-$sectionId'),
            actions: const [
              FirestoreSyncStatusAction(),
            ],
          ),
          body: examsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load exams: $e')),
            data: (snapshot) {
              final exams = snapshot.docs
                  .map(Exam.fromDoc)
                  .toList(growable: false);

              final sorted = [...exams]
                ..sort((a, b) {
                  final aTs = a.createdAt;
                  final bTs = b.createdAt;
                  if (aTs == null && bTs == null) {
                    return a.name.compareTo(b.name);
                  }
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

              if (sorted.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No exams created yet.\n\nTap + to create one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final exam = sorted[i];
                  final subtitle = _formatCreatedAt(exam.createdAt);

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.edit_document),
                      title: Text(exam.examName.trim().isEmpty ? '(Untitled)' : exam.examName.trim()),
                      subtitle: Text(
                        '${exam.examType.trim().isEmpty ? 'Exam' : exam.examType.trim()}${subtitle == null ? '' : ' • $subtitle'}',
                      ),
                      trailing: PopupMenuButton<_ExamAction>(
                        onSelected: (action) async {
                          if (action == _ExamAction.enterMarks) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EnterMarksScreen(
                                  exam: exam,
                                  classId: classId,
                                  sectionId: sectionId,
                                ),
                              ),
                            );
                          } else if (action == _ExamAction.viewResults) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExamResultsScreen(
                                  exam: exam,
                                  classId: classId,
                                  sectionId: sectionId,
                                ),
                              ),
                            );
                          } else if (action == _ExamAction.delete) {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Delete exam?'),
                                  content: const Text(
                                    'This deletes the exam document.\n\nNote: Firestore does not auto-delete subcollections, so marks documents may remain stored.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (ok != true) return;

                            try {
                              await ExamService().deleteExam(
                                schoolId: schoolId,
                                examId: exam.id,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exam deleted')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _ExamAction.enterMarks,
                            child: Text('Enter marks'),
                          ),
                          PopupMenuItem(
                            value: _ExamAction.viewResults,
                            child: Text('View class results'),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: _ExamAction.delete,
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExamResultsScreen(
                              exam: exam,
                              classId: classId,
                              sectionId: sectionId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateExamScreen(
                    classId: classId,
                    sectionId: sectionId,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

enum _ExamAction { enterMarks, viewResults, delete }

// (Create exam dialog removed; we now use CreateExamScreen for Exam Type + Name.)

class ExamResultsScreen extends ConsumerWidget {
  const ExamResultsScreen({
    super.key,
    required this.exam,
    required this.classId,
    required this.sectionId,
  });

  final Exam exam;
  final String classId;
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsByClassProvider((classId, sectionId)));
    final marksAsync = ref.watch(examMarksProvider(exam.id));
    final examLiveAsync = ref.watch(examDocProvider(exam.id));
    final gradingAsync = ref.watch(gradingSystemProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.examName.trim().isEmpty ? 'Results' : exam.examName.trim()),
        actions: const [
          FirestoreSyncStatusAction(),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load students: $e')),
        data: (studentsSnap) {
          final students = studentsSnap.docs
              .map((d) => Student.fromMap(d.id, d.data()))
              .toList(growable: false);

          students.sort((a, b) => a.name.compareTo(b.name));

          return marksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load marks: $e')),
            data: (marksSnap) {
              final marksByStudentId = <String, ExamMarks>{
                for (final d in marksSnap.docs) d.id: ExamMarks.fromDoc(d),
              };

              final liveExam = examLiveAsync.maybeWhen(
                data: (doc) => Exam.fromDoc(doc),
                orElse: () => exam,
              );

              final grading = gradingAsync.maybeWhen(data: (g) => g, orElse: () => null);

              final rows = students
                  .map((s) {
                    final m = marksByStudentId[s.id];
                    final calc = calcTotals(exam: liveExam, marks: m);
                    return _ResultRow(
                      student: s,
                      total: calc.total,
                      outOf: calc.outOf,
                      percent: calc.percent,
                      grade: gradeForPercent(calc.percent, system: grading),
                    );
                  })
                  .toList(growable: false)
                ..sort((a, b) => b.total.compareTo(a.total));

              if (rows.isEmpty) {
                return const Center(child: Text('No students found.'));
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _SummaryHeader(rows: rows),
                  const SizedBox(height: 10),
                  for (final r in rows)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            r.student.name.trim().isEmpty ? r.student.id.substring(0, 1) : r.student.name.trim().substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(r.student.name.trim().isEmpty ? r.student.id : r.student.name.trim()),
                        subtitle: Text('Total: ${r.total} / ${r.outOf}   •   Grade: ${r.grade}'),
                        trailing: Text('${r.percent.toStringAsFixed(1)}%'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _StudentMarksDetailScreen(
                                exam: liveExam,
                                student: r.student,
                                marks: marksByStudentId[r.student.id],
                                grading: grading,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.rows});

  final List<_ResultRow> rows;

  @override
  Widget build(BuildContext context) {
    final avg = rows.isEmpty
        ? 0.0
        : rows.map((r) => r.percent).reduce((a, b) => a + b) / rows.length;

    final top = rows.isEmpty ? null : rows.first;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Average: ${avg.toStringAsFixed(1)}%'),
            if (top != null) ...[
              const SizedBox(height: 6),
              Text(
                'Top student: ${top.student.name.trim().isEmpty ? top.student.id : top.student.name.trim()} (${top.total}/${top.outOf})',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentMarksDetailScreen extends StatelessWidget {
  const _StudentMarksDetailScreen({
    required this.exam,
    required this.student,
    required this.marks,
    required this.grading,
  });

  final Exam exam;
  final Student student;
  final ExamMarks? marks;
  final GradingSystem? grading;

  @override
  Widget build(BuildContext context) {
    final derived = deriveSubjectRows(exam: exam, marks: marks);
    final totals = calcTotalsFromRows(derived);
    final grade = gradeForPercent(totals.percent, system: grading);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name.trim().isEmpty ? student.id : student.name.trim()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.examName.trim().isEmpty ? 'Exam' : exam.examName.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text('Total: ${totals.total} / ${totals.outOf}'),
                  Text('Grade: $grade'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (derived.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No marks entered yet.'),
              ),
            )
          else
            for (final r in derived)
              Card(
                child: ListTile(
                  title: Text(_prettySubject(r.subjectKey)),
                  trailing: Text(
                    '${r.obtained} / ${r.outOf}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

String? _formatCreatedAt(DateTime? dt) {
  if (dt == null) return null;
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _prettySubject(String key) {
  final cleaned = key.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

class _ResultRow {
  const _ResultRow({
    required this.student,
    required this.total,
    required this.outOf,
    required this.percent,
    required this.grade,
  });

  final Student student;
  final int total;
  final int outOf;
  final double percent;
  final String grade;
}
