import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/parent/providers/parent_children_provider.dart';
import 'package:school_app/features/exams/widgets/marks_card_renderer.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/core/utils/marks_calc.dart';
import 'package:school_app/providers/grading_system_provider.dart';
import 'package:school_app/providers/exam_provider.dart';
import 'package:school_app/providers/exam_template_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/providers/school_branding_provider.dart';

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
    final gradingAsync = ref.watch(gradingSystemProvider);

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

    final schoolNameAsync = ref.watch(currentSchoolProvider);
    final schoolLogoUrlAsync = ref.watch(schoolBrandingLogoUrlProvider);

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
                final grading = gradingAsync.maybeWhen(data: (g) => g, orElse: () => null);

                final templateAsync = ref.watch(
                  resolvedExamTemplateProvider(
                    ResolvedExamTemplateArgs(
                      templateId: exam.templateId,
                      examTypeKey: exam.examTypeKey.isNotEmpty ? exam.examTypeKey : exam.examType,
                    ),
                  ),
                );

                return marksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text('Failed to load marks: $e'),
                  data: (marksDoc) {
                    final marks = marksDoc.exists ? ExamMarks.fromDoc(marksDoc) : null;
                    final derived = deriveSubjectRows(exam: exam, marks: marks);
                    final calc = calcTotalsFromRows(derived);

                    final schoolName = schoolNameAsync.maybeWhen(
                      data: (d) => (d.data()?['name'] ?? '').toString(),
                      orElse: () => '',
                    );

                    final schoolLogoUrl = schoolLogoUrlAsync.maybeWhen(
                      data: (u) => u,
                      orElse: () => null,
                    );

                    final template = templateAsync.maybeWhen(data: (t) => t, orElse: () => null);

                    if (template != null) {
                      return MarksCardRenderer(
                        template: template,
                        exam: exam,
                        student: child,
                        marks: marks,
                        schoolName: schoolName,
                        schoolLogoUrl: schoolLogoUrl,
                        gradingSystem: grading,
                      );
                    }

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
                                Text('Grade: ${gradeForPercent(calc.percent, system: grading)}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (derived.isEmpty)
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

String _prettySubject(String key) {
  final cleaned = key.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}
