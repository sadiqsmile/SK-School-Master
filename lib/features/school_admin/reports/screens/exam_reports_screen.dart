import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart' as classes_stream;
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/core/utils/marks_calc.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/grading_system.dart';
import 'package:school_app/providers/grading_system_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';

class ExamReportsScreen extends ConsumerStatefulWidget {
  const ExamReportsScreen({super.key});

  @override
  ConsumerState<ExamReportsScreen> createState() => _ExamReportsScreenState();
}

class _ExamReportsScreenState extends ConsumerState<ExamReportsScreen> {
  String? _classId;
  String? _sectionId;
  String? _examId;

  Future<_ExamReport>? _future;

  String _prettyExamTitle(Exam e) {
    final t = e.examType.trim();
    return t.isEmpty ? e.examName : '$t • ${e.examName}';
  }

  String _grade(double percent, {GradingSystem? system}) {
    return gradeForPercent(percent, system: system);
  }

  Future<_ExamReport> _buildReport({
    required String schoolId,
    required String classId,
    required String sectionId,
    required String examId,
  }) async {
    final db = FirebaseFirestore.instance;

    final grading = await ref.read(gradingSystemProvider.future);

    final examDoc = await db
        .collection('schools')
        .doc(schoolId)
        .collection('exams')
        .doc(examId)
        .get();

    if (!examDoc.exists) throw Exception('Exam not found');

    final exam = Exam.fromDoc(examDoc);

    final studentsSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: sectionId)
        .get();

    final Map<String, String> studentName = {
      for (final s in studentsSnap.docs)
        s.id: (s.data()['name'] ?? s.id).toString(),
    };

    final marksSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('exams')
        .doc(examId)
        .collection('marks')
        .get();

    final marks = <ExamMarks>[];
    for (final doc in marksSnap.docs) {
      marks.add(ExamMarks.fromDoc(doc));
    }

    final subjectSums = <String, int>{};
    final subjectCounts = <String, int>{};

    final studentTotals = <_StudentScore>[];

    int passCount = 0;

    for (final m in marks) {
      final calc = calcTotals(exam: exam, marks: m);

      if (calc.percent >= grading.passPercent) passCount++;

      studentTotals.add(
        _StudentScore(
          studentId: m.studentId,
          name: studentName[m.studentId] ?? m.studentId,
          total: calc.total,
          outOf: calc.outOf,
          percent: calc.percent,
          grade: _grade(calc.percent, system: grading),
        ),
      );

      final derived = deriveSubjectRows(exam: exam, marks: m);
      for (final r in derived) {
        final k = r.subjectKey;
        subjectSums[k] = (subjectSums[k] ?? 0) + r.obtained;
        subjectCounts[k] = (subjectCounts[k] ?? 0) + 1;
      }
    }

    studentTotals.sort((a, b) => b.percent.compareTo(a.percent));

    final examMaxRows = deriveSubjectRows(exam: exam, marks: null);
    final maxBySubject = <String, int>{
      for (final r in examMaxRows) r.subjectKey: r.outOf,
    };

    final subjectAverages = <_SubjectAverage>[];
    for (final subj in subjectSums.keys) {
      final sum = subjectSums[subj] ?? 0;
      final count = subjectCounts[subj] ?? 0;
      final max = maxBySubject[subj] ?? (exam.subjectMaxMarks[subj] ?? 50);
      final avg = count <= 0 ? 0.0 : sum / count;
      final percent = max <= 0 ? 0.0 : (avg / max) * 100;

      subjectAverages.add(
        _SubjectAverage(
          subject: subj,
          average: avg,
          outOf: max,
          percent: percent,
        ),
      );
    }

    subjectAverages.sort((a, b) => b.percent.compareTo(a.percent));

    final total = marks.isEmpty ? 0 : marks.length;
    final passPct = total <= 0 ? 0.0 : (passCount / total) * 100;

    return _ExamReport(
      exam: exam,
      totalStudentsWithMarks: total,
      passPercent: passPct,
      subjectAverages: subjectAverages,
      topStudents: studentTotals.take(10).toList(growable: false),
    );
  }

  Future<List<Exam>> _loadExams({
    required String schoolId,
    required String classId,
    required String sectionId,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('exams')
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: sectionId)
        .get();

    final exams = snap.docs.map(Exam.fromDoc).toList(growable: false);

    exams.sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return exams;
  }

  void _generate(String schoolId) {
    final classId = (_classId ?? '').trim();
    final sectionId = (_sectionId ?? '').trim();
    final examId = (_examId ?? '').trim();

    if (classId.isEmpty || sectionId.isEmpty || examId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select class, section, and exam.')),
      );
      return;
    }

    setState(() {
      _future = _buildReport(
        schoolId: schoolId,
        classId: classId,
        sectionId: sectionId,
        examId: examId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8FAFF);
    const accent = Color(0xFF2563EB);

    final schoolAsync = ref.watch(currentSchoolProvider);
    final classesAsync = ref.watch(classes_stream.classesProvider);

    Widget decoratedDropdown<T>({
      required String label,
      required T? value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
      String? hintText,
    }) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            hint: hintText == null ? null : Text(hintText),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
    }

    return AdminLayout(
      title: 'Exam Reports',
      body: Container(
        color: bg,
        child: schoolAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load school: $e')),
          data: (schoolDoc) {
            final schoolId = schoolDoc.id;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Card(
                  borderColor: accent.withAlpha(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      classesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Failed to load classes: $e'),
                        data: (snap) {
                          final items = snap.docs
                              .map((d) {
                                final data = d.data();
                                final name = (data['name'] ?? d.id).toString();
                                return (id: d.id, name: name);
                              })
                              .toList(growable: false)
                            ..sort((a, b) => a.name.compareTo(b.name));

                          if (_classId == null && items.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() => _classId = items.first.id);
                            });
                          }

                          return decoratedDropdown<String>(
                            label: 'Class',
                            value: _classId,
                            hintText: items.isEmpty ? 'No classes' : 'Select class',
                            items: [
                              for (final c in items)
                                DropdownMenuItem(value: c.id, child: Text(c.name)),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _classId = v;
                                _sectionId = null;
                                _examId = null;
                                _future = null;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_classId == null)
                        const Text('Select a class to load sections.')
                      else
                        ref.watch(sectionsProvider(_classId!)).when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Failed to load sections: $e'),
                              data: (snap) {
                                final sections = snap.docs
                                    .map((d) {
                                      final data = d.data();
                                      final name = (data['name'] ?? d.id).toString();
                                      return (id: d.id, name: name);
                                    })
                                    .toList(growable: false)
                                  ..sort((a, b) => a.name.compareTo(b.name));

                                if (_sectionId == null && sections.isNotEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(() => _sectionId = sections.first.id);
                                  });
                                }

                                return decoratedDropdown<String>(
                                  label: 'Section',
                                  value: _sectionId,
                                  hintText: sections.isEmpty
                                      ? 'No sections'
                                      : 'Select section',
                                  items: [
                                    for (final s in sections)
                                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _sectionId = v;
                                      _examId = null;
                                      _future = null;
                                    });
                                  },
                                );
                              },
                            ),
                      const SizedBox(height: 10),
                      if ((_classId ?? '').isNotEmpty && (_sectionId ?? '').isNotEmpty)
                        FutureBuilder<List<Exam>>(
                          future: _loadExams(
                            schoolId: schoolId,
                            classId: _classId!,
                            sectionId: _sectionId!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Failed to load exams: ${snapshot.error}');
                            }
                            final exams = snapshot.data ?? const <Exam>[];

                            if (_examId == null && exams.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() => _examId = exams.first.id);
                              });
                            }

                            return decoratedDropdown<String>(
                              label: 'Exam',
                              value: _examId,
                              hintText: exams.isEmpty ? 'No exams' : 'Select exam',
                              items: [
                                for (final e in exams)
                                  DropdownMenuItem(
                                    value: e.id,
                                    child: Text(_prettyExamTitle(e)),
                                  ),
                              ],
                              onChanged: exams.isEmpty
                                  ? (_) {}
                                  : (v) {
                                      setState(() {
                                        _examId = v;
                                        _future = null;
                                      });
                                    },
                            );
                          },
                        )
                      else
                        const Text(
                          'Select class and section to load exams.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _generate(schoolId),
                        icon: const Icon(Icons.analytics_rounded),
                        label: const Text('Generate report'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_future == null)
                  const _InfoCard(
                    text:
                        'Generate a report to see subject averages, pass percentage and top students for an exam.',
                  )
                else
                  FutureBuilder<_ExamReport>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _WarnCard(message: snapshot.error.toString());
                      }
                      final report = snapshot.data;
                      if (report == null) {
                        return const _WarnCard(message: 'No data');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Card(
                            borderColor: accent.withAlpha(60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _prettyExamTitle(report.exam),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Students with marks: ${report.totalStudentsWithMarks}',
                                  style: const TextStyle(color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Stat(
                                        accent: accent,
                                        title: 'Pass %',
                                        value: '${report.passPercent.toStringAsFixed(0)}%',
                                        icon: Icons.verified_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _Stat(
                                        accent: accent,
                                        title: 'Subjects',
                                        value: '${report.subjectAverages.length}',
                                        icon: Icons.menu_book_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Card(
                            borderColor: accent.withAlpha(60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Subject performance',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 10),
                                if (report.subjectAverages.isEmpty)
                                  const Text(
                                    'No subjects found yet. Add marks first.',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  )
                                else
                                  ...report.subjectAverages.map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s.subject,
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          Text(
                                            '${s.average.toStringAsFixed(1)} / ${s.outOf}',
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 110,
                                            child: LinearProgressIndicator(
                                              value: (s.percent / 100).clamp(0, 1).toDouble(),
                                              minHeight: 8,
                                              backgroundColor: accent.withAlpha(16),
                                              valueColor: const AlwaysStoppedAnimation(accent),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Card(
                            borderColor: accent.withAlpha(60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Top students',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 10),
                                if (report.topStudents.isEmpty)
                                  const Text(
                                    'No marks found yet.',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  )
                                else
                                  ...report.topStudents.map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s.name,
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${s.total}/${s.outOf}',
                                            style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: accent.withAlpha(14),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: accent.withAlpha(60)),
                                            ),
                                            child: Text(
                                              '${s.percent.toStringAsFixed(0)}%  ${s.grade}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: accent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExamReport {
  const _ExamReport({
    required this.exam,
    required this.totalStudentsWithMarks,
    required this.passPercent,
    required this.subjectAverages,
    required this.topStudents,
  });

  final Exam exam;
  final int totalStudentsWithMarks;
  final double passPercent;
  final List<_SubjectAverage> subjectAverages;
  final List<_StudentScore> topStudents;
}

class _SubjectAverage {
  const _SubjectAverage({
    required this.subject,
    required this.average,
    required this.outOf,
    required this.percent,
  });

  final String subject;
  final double average;
  final int outOf;
  final double percent;
}

class _StudentScore {
  const _StudentScore({
    required this.studentId,
    required this.name,
    required this.total,
    required this.outOf,
    required this.percent,
    required this.grade,
  });

  final String studentId;
  final String name;
  final int total;
  final int outOf;
  final double percent;
  final String grade;
}

class _Card extends StatelessWidget {
  const _Card({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.accent,
    required this.title,
    required this.value,
    required this.icon,
  });

  final Color accent;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x332563EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarnCard extends StatelessWidget {
  const _WarnCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
