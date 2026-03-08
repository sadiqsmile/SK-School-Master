import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/core/utils/firestore_keys.dart';
import 'package:school_app/providers/exam_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/exam_service.dart';

class CreateExamScreen extends ConsumerStatefulWidget {
  const CreateExamScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

  @override
  ConsumerState<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends ConsumerState<CreateExamScreen> {
  final _examNameController = TextEditingController();
  String? _selectedExamTypeId;
  final _manualExamTypeController = TextEditingController();

  @override
  void dispose() {
    _examNameController.dispose();
    _manualExamTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolIdAsync = ref.watch(schoolIdProvider);
    final examTypesAsync = ref.watch(examTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Exam')),
      body: schoolIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (schoolId) {
          return examTypesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Body(
              classId: widget.classId,
              sectionId: widget.sectionId,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Failed to load Exam Types: $e\n\nYou can still enter the type manually below.',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                _ManualTypeField(controller: _manualExamTypeController),
                const SizedBox(height: 12),
                _ExamNameField(controller: _examNameController),
                const SizedBox(height: 16),
                _CreateButton(
                  onPressed: () => _create(
                    context: context,
                    schoolId: schoolId,
                    examTypeName: _manualExamTypeController.text,
                    examTypeKey: normalizeKeyLower(_manualExamTypeController.text),
                  ),
                ),
              ],
            ),
            data: (snap) {
              final types = snap.docs
                  .map((d) {
                    final data = d.data();
                    final name = (data['name'] ?? '').toString();
                    final defaultTemplateId = (data['defaultTemplateId'] ?? '').toString();
                    return (id: d.id, name: name, defaultTemplateId: defaultTemplateId);
                  })
                  .where((t) => t.name.trim().isNotEmpty)
                  .toList(growable: false)
                ..sort((a, b) => a.name.compareTo(b.name));

              // Auto-select first type if available.
              _selectedExamTypeId ??= types.isEmpty ? null : types.first.id;

              final selectedTypeName = types
                  .where((t) => t.id == _selectedExamTypeId)
                  .map((t) => t.name)
                  .firstOrNull;

                final selectedDefaultTemplateId = types
                  .where((t) => t.id == _selectedExamTypeId)
                  .map((t) => t.defaultTemplateId)
                  .firstOrNull;

              final showManual = types.isEmpty;

              return _Body(
                classId: widget.classId,
                sectionId: widget.sectionId,
                children: [
                  if (types.isNotEmpty) ...[
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Exam Type',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: types.any((t) => t.id == _selectedExamTypeId)
                              ? _selectedExamTypeId
                              : null,
                          isExpanded: true,
                          items: [
                            for (final t in types)
                              DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedExamTypeId = v;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in types.take(6))
                          ActionChip(
                            label: Text(t.name),
                            onPressed: () {
                              setState(() {
                                _selectedExamTypeId = t.id;
                              });
                            },
                          ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'No Exam Types found yet. Add them from Admin → Exam Types.\n\nFor now you can type one below.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                  if (showManual) ...[
                    const SizedBox(height: 12),
                    _ManualTypeField(controller: _manualExamTypeController),
                  ],
                  const SizedBox(height: 12),
                  _ExamNameField(controller: _examNameController),
                  const SizedBox(height: 16),
                  _CreateButton(
                    onPressed: () => _create(
                      context: context,
                      schoolId: schoolId,
                      examTypeName: showManual
                          ? _manualExamTypeController.text
                          : (selectedTypeName ?? ''),
                      examTypeKey: showManual
                          ? normalizeKeyLower(_manualExamTypeController.text)
                          : (_selectedExamTypeId ?? ''),
                      templateId: showManual
                          ? null
                          : (selectedDefaultTemplateId?.trim().isEmpty ?? true)
                              ? null
                              : selectedDefaultTemplateId,
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

  Future<void> _create({
    required BuildContext context,
    required String schoolId,
    required String examTypeName,
    required String examTypeKey,
    String? templateId,
  }) async {
    try {
      await ExamService().createExamV2(
        schoolId: schoolId,
        examType: examTypeName,
        examName: _examNameController.text,
        classId: widget.classId,
        section: widget.sectionId,
        examTypeKey: examTypeKey,
        templateId: templateId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.classId,
    required this.sectionId,
    required this.children,
  });

  final String classId;
  final String sectionId;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam details',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('Class: $classId$sectionId'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _ManualTypeField extends StatelessWidget {
  const _ManualTypeField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Exam Type (manual)',
        hintText: 'Unit Test',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
    );
  }
}

class _ExamNameField extends StatelessWidget {
  const _ExamNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Exam Name',
        hintText: 'Unit Test 1',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Exam'),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
