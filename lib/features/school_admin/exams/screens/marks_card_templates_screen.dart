import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/core/utils/firestore_keys.dart';
import 'package:school_app/features/school_admin/exams/screens/marks_card_template_builder_screen.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/exam_template.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/providers/exam_provider.dart';
import 'package:school_app/providers/exam_template_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/providers/school_branding_provider.dart';
import 'package:school_app/providers/school_provider.dart';
import 'package:school_app/services/exam_template_service.dart';
import 'package:school_app/features/exams/widgets/marks_card_renderer.dart';

class MarksCardTemplatesScreen extends ConsumerStatefulWidget {
  const MarksCardTemplatesScreen({super.key});

  @override
  ConsumerState<MarksCardTemplatesScreen> createState() => _MarksCardTemplatesScreenState();
}

class _MarksCardTemplatesScreenState extends ConsumerState<MarksCardTemplatesScreen> {
  String? _selectedExamTypeKey;

  @override
  Widget build(BuildContext context) {
    final schoolIdAsync = ref.watch(schoolIdProvider);
    final schoolDocAsync = ref.watch(schoolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks Card Templates'),
      ),
      body: schoolIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load school: $e')),
        data: (schoolId) {
          final examTypesAsync = ref.watch(examTypesProvider);

          return examTypesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load exam types: $e')),
            data: (typesSnap) {
              final examTypes = typesSnap.docs
                  .map((d) {
                    final data = d.data();
                    return (
                      key: d.id,
                      name: (data['name'] ?? '').toString(),
                      defaultTemplateId: (data['defaultTemplateId'] ?? '').toString(),
                    );
                  })
                  .where((t) => t.name.trim().isNotEmpty)
                  .toList(growable: false)
                ..sort((a, b) => a.name.compareTo(b.name));

              if (_selectedExamTypeKey == null && examTypes.isNotEmpty) {
                _selectedExamTypeKey = examTypes.first.key;
              }

              final selectedKey = (_selectedExamTypeKey ?? '').trim();
              final templatesAsync = ref.watch(
                examTemplatesProvider(selectedKey.isEmpty ? null : selectedKey),
              );

              final schoolName = schoolDocAsync.maybeWhen(
                data: (doc) => (doc.data()?['name'] ?? '').toString(),
                orElse: () => '',
              );

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exam type',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Select exam type',
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: examTypes.any((t) => t.key == _selectedExamTypeKey)
                                    ? _selectedExamTypeKey
                                    : null,
                                isExpanded: true,
                                items: [
                                  for (final t in examTypes)
                                    DropdownMenuItem(
                                      value: t.key,
                                      child: Text(t.name),
                                    ),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedExamTypeKey = v;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: selectedKey.isEmpty
                                ? null
                                : () {
                                    final selected = examTypes
                                        .where((t) => t.key == selectedKey)
                                        .firstOrNull;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MarksCardTemplateBuilderScreen(
                                          examTypeKey: selectedKey,
                                          examTypeName: selected?.name ?? selectedKey,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create template'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  templatesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load templates: $e'),
                    data: (snap) {
                      final templates = snap.docs
                          .where((d) => d.exists)
                          .map((d) => ExamTemplate.fromDoc(d))
                          .where((t) => t.name.trim().isNotEmpty)
                          .toList(growable: false);

                      if (templates.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No templates yet for this exam type.\n\nTap “Create template” to build one with live preview.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        );
                      }

                      final defaultId = examTypes
                          .where((t) => t.key == selectedKey)
                          .map((t) => t.defaultTemplateId)
                          .firstOrNull
                          ?.trim();

                      return Column(
                        children: [
                          for (final t in templates)
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.description_rounded),
                                title: Text(t.name),
                                subtitle: Text(
                                  'Columns: ${t.columns.length} • Summary: ${t.summaryRows.length} • Extra: ${t.extraFields.length}',
                                ),
                                trailing: PopupMenuButton<_TemplateAction>(
                                  onSelected: (action) async {
                                    if (action == _TemplateAction.edit) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MarksCardTemplateBuilderScreen(
                                            templateId: t.id,
                                            examTypeKey: t.examTypeKey,
                                            examTypeName: t.examTypeName,
                                          ),
                                        ),
                                      );
                                    } else if (action == _TemplateAction.preview) {
                                      await _showPreview(
                                        context: context,
                                        schoolName: schoolName,
                                        template: t,
                                      );
                                    } else if (action == _TemplateAction.setDefault) {
                                      try {
                                        await ExamTemplateService().setDefaultTemplateForExamType(
                                          schoolId: schoolId,
                                          examTypeKey: normalizeKeyLower(t.examTypeKey),
                                          templateId: t.id,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Default template set')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed: $e')),
                                          );
                                        }
                                      }
                                    } else if (action == _TemplateAction.delete) {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) {
                                          return AlertDialog(
                                            title: const Text('Delete template?'),
                                            content: Text('Delete "${t.name}"?'),
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
                                        await ExamTemplateService().deleteTemplate(
                                          schoolId: schoolId,
                                          templateId: t.id,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Deleted')),
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
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: _TemplateAction.preview,
                                      child: Text('Preview'),
                                    ),
                                    const PopupMenuItem(
                                      value: _TemplateAction.edit,
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: _TemplateAction.setDefault,
                                      enabled: (defaultId ?? '') != t.id,
                                      child: Text(
                                        (defaultId ?? '') == t.id
                                            ? 'Default (current)'
                                            : 'Set as default',
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: _TemplateAction.delete,
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                                onTap: () => _showPreview(
                                  context: context,
                                  schoolName: schoolName,
                                  template: t,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPreview({
    required BuildContext context,
    required String schoolName,
    required ExamTemplate template,
  }) async {
    String? schoolLogoUrl;
    try {
      schoolLogoUrl = await ref.read(schoolBrandingLogoUrlProvider.future);
    } catch (_) {
      schoolLogoUrl = null;
    }

    if (!context.mounted) return;

    // Lightweight mock preview.
    final exam = Exam(
      id: 'preview',
      examName: 'Unit Test 1',
      examType: template.examTypeName,
      examTypeKey: template.examTypeKey,
      templateId: template.id,
      classId: '5',
      section: 'A',
      createdAt: DateTime.now(),
      subjectMaxMarks: const {'math': 50, 'english': 50, 'science': 50},
      subjectComponentMaxMarks: const {
        'science': {'practical': 20, 'theory': 30},
      },
    );

    final marks = ExamMarks(
      studentId: 'student_1',
      subjectMarks: const {'math': 44, 'english': 38},
      subjectComponentMarks: const {
        'science': {'practical': 18, 'theory': 24},
      },
    );

    const student = Student(
      id: 'student_1',
      name: 'Aisha Khan',
      admissionNo: 'A-102',
      classId: '5',
      section: 'A',
      parentName: 'Parent',
      parentPhone: '000',
      academicYear: '2025-2026',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Preview • ${template.name}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MarksCardRenderer(
                  template: template,
                  exam: exam,
                  student: student,
                  marks: marks,
                  schoolName: schoolName,
                  schoolLogoUrl: schoolLogoUrl,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _TemplateAction { preview, edit, setDefault, delete }

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
