import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/core/utils/firestore_keys.dart';
import 'package:school_app/features/exams/widgets/marks_card_renderer.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/exam_template.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/providers/exam_template_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/providers/school_branding_provider.dart';
import 'package:school_app/providers/school_provider.dart';
import 'package:school_app/services/exam_template_service.dart';

class MarksCardTemplateBuilderScreen extends ConsumerStatefulWidget {
  const MarksCardTemplateBuilderScreen({
    super.key,
    this.templateId,
    required this.examTypeKey,
    required this.examTypeName,
  });

  final String? templateId;
  final String examTypeKey;
  final String examTypeName;

  @override
  ConsumerState<MarksCardTemplateBuilderScreen> createState() => _MarksCardTemplateBuilderScreenState();
}

class _MarksCardTemplateBuilderScreenState extends ConsumerState<MarksCardTemplateBuilderScreen> {
  static const _maxColumns = 8;
  static const _maxSummary = 10;
  static const _maxExtraFields = 10;

  final _nameController = TextEditingController();
  final _headerTextController = TextEditingController();

  bool _showSchoolName = true;
  bool _showExamName = true;
  bool _showExamType = true;
  bool _showAcademicYear = true;

  bool _showTeacherSign = true;
  bool _showPrincipalSign = true;
  final _teacherLabelController = TextEditingController(text: 'Class Teacher');
  final _principalLabelController = TextEditingController(text: 'Principal');

  final List<ExamTemplateColumn> _columns = [];

  bool _summaryTotal = true;
  bool _summaryPercent = true;
  bool _summaryGrade = true;

  final List<ExamTemplateExtraField> _extraFields = [];

  bool _setAsDefault = true;

  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _headerTextController.dispose();
    _teacherLabelController.dispose();
    _principalLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolIdAsync = ref.watch(schoolIdProvider);
    final schoolName = ref.watch(schoolProvider).maybeWhen(
          data: (doc) => (doc.data()?['name'] ?? '').toString(),
          orElse: () => '',
        );

    final templateId = (widget.templateId ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(templateId.isEmpty ? 'Create Template' : 'Edit Template'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: () async {
              final schoolId = await ref.read(schoolIdProvider.future);
              if (!context.mounted) return;
              await _save(context: context, schoolId: schoolId);
            },
            icon: const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: schoolIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (schoolId) {
          if (templateId.isEmpty) {
            _ensureInitializedFromNew();
            return _buildBody(
              schoolId: schoolId,
              schoolName: schoolName,
            );
          }

          final templateAsync = ref.watch(examTemplateDocProvider(templateId));
          return templateAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load template: $e')),
            data: (doc) {
              if (!doc.exists) {
                return const Center(child: Text('Template not found.'));
              }

              final t = ExamTemplate.fromDoc(doc);
              _ensureInitializedFromExisting(t);

              return _buildBody(
                schoolId: schoolId,
                schoolName: schoolName,
              );
            },
          );
        },
      ),
    );
  }

  void _ensureInitializedFromNew() {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = '${widget.examTypeName} Template';

    _columns
      ..clear()
      ..addAll([
        ExamTemplateColumn(
          id: 'subject',
          label: 'Subject',
          type: MarksCardColumnType.subject,
        ),
        ExamTemplateColumn(
          id: 'max',
          label: 'Max',
          type: MarksCardColumnType.maxTotal,
        ),
        ExamTemplateColumn(
          id: 'marks',
          label: 'Marks',
          type: MarksCardColumnType.obtainedTotal,
        ),
      ]);

    _extraFields
      ..clear()
      ..addAll(const [
        ExamTemplateExtraField(label: 'Remarks', value: ''),
      ]);
  }

  void _ensureInitializedFromExisting(ExamTemplate t) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = t.name;
    _headerTextController.text = t.header.headerText;

    _showSchoolName = t.header.showSchoolName;
    _showExamName = t.header.showExamName;
    _showExamType = t.header.showExamType;
    _showAcademicYear = t.header.showAcademicYear;

    _columns
      ..clear()
      ..addAll(t.columns);

    _summaryTotal = t.summaryRows.any((r) => r.type == MarksCardSummaryRowType.total);
    _summaryPercent = t.summaryRows.any((r) => r.type == MarksCardSummaryRowType.percentage);
    _summaryGrade = t.summaryRows.any((r) => r.type == MarksCardSummaryRowType.grade);

    _extraFields
      ..clear()
      ..addAll(t.extraFields);

    _showTeacherSign = t.signatures.showTeacher;
    _showPrincipalSign = t.signatures.showPrincipal;
    _teacherLabelController.text = t.signatures.teacherLabel;
    _principalLabelController.text = t.signatures.principalLabel;

    // When editing, don't auto-set as default unless the user wants to.
    _setAsDefault = false;
  }

  Widget _buildBody({
    required String schoolId,
    required String schoolName,
  }) {
    final templateForPreview = _buildTemplateForPreview();

    final schoolLogoUrl = ref.watch(schoolBrandingLogoUrlProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
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
                  'Basics',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text('Exam type: ${widget.examTypeName} (key: ${widget.examTypeKey})'),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _setAsDefault,
                  onChanged: (v) => setState(() => _setAsDefault = v),
                  title: const Text('Set as default for this exam type'),
                  subtitle: const Text('New exams of this type will use this template automatically.'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Header',
          child: Column(
            children: [
              TextField(
                controller: _headerTextController,
                decoration: const InputDecoration(
                  labelText: 'Header text (optional)',
                  hintText: 'e.g. Progress Report',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _toggle('Show school name', _showSchoolName, (v) => setState(() => _showSchoolName = v)),
              _toggle('Show exam name', _showExamName, (v) => setState(() => _showExamName = v)),
              _toggle('Show exam type', _showExamType, (v) => setState(() => _showExamType = v)),
              _toggle('Show academic year', _showAcademicYear, (v) => setState(() => _showAcademicYear = v)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Table columns (max $_maxColumns)',
          subtitle: 'Tip: Add component columns for Oral / Written / Practical.',
          trailing: IconButton(
            tooltip: 'Add column',
            onPressed: _columns.length >= _maxColumns
                ? null
                : () async {
                    final col = await _showAddColumnDialog(context);
                    if (col == null) return;
                    setState(() {
                      if (_columns.length >= _maxColumns) return;
                      _columns.add(col);
                    });
                  },
            icon: const Icon(Icons.add_rounded),
          ),
          child: Column(
            children: [
              if (_columns.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No columns yet.'),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _columns.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _columns.removeAt(oldIndex);
                      _columns.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, i) {
                    final c = _columns[i];
                    return ListTile(
                      key: ValueKey(c.id),
                      leading: const Icon(Icons.drag_handle_rounded),
                      title: Text(c.label),
                      subtitle: Text(
                        c.type == MarksCardColumnType.component
                            ? 'Component • ${c.componentKey ?? ''}'
                            : c.type.name,
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                            _columns.removeAt(i);
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Summary rows (max $_maxSummary)',
          child: Column(
            children: [
              _toggle('Total', _summaryTotal, (v) => setState(() => _summaryTotal = v)),
              _toggle('Percentage', _summaryPercent, (v) => setState(() => _summaryPercent = v)),
              _toggle('Grade', _summaryGrade, (v) => setState(() => _summaryGrade = v)),
              const SizedBox(height: 6),
              const Text(
                'More summary types (rank, pass/fail, etc.) can be added later.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Extra fields (max $_maxExtraFields)',
          trailing: IconButton(
            tooltip: 'Add field',
            onPressed: _extraFields.length >= _maxExtraFields
                ? null
                : () async {
                    final field = await _showUpsertExtraFieldDialog(context);
                    if (field == null) return;
                    setState(() {
                      if (_extraFields.length >= _maxExtraFields) return;
                      _extraFields.add(field);
                    });
                  },
            icon: const Icon(Icons.add_rounded),
          ),
          child: Column(
            children: [
              if (_extraFields.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No extra fields.'),
                )
              else
                for (var i = 0; i < _extraFields.length; i++)
                  ListTile(
                    title: Text(_extraFields[i].label),
                    subtitle: Text(_extraFields[i].value.trim().isEmpty ? '—' : _extraFields[i].value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () async {
                            final updated = await _showUpsertExtraFieldDialog(
                              context,
                              initial: _extraFields[i],
                            );
                            if (updated == null) return;
                            setState(() => _extraFields[i] = updated);
                          },
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _extraFields.removeAt(i)),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Signatures',
          child: Column(
            children: [
              _toggle('Teacher signature', _showTeacherSign, (v) => setState(() => _showTeacherSign = v)),
              if (_showTeacherSign) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _teacherLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _toggle('Principal signature', _showPrincipalSign, (v) => setState(() => _showPrincipalSign = v)),
              if (_showPrincipalSign) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _principalLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Principal label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Live preview',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 8),
        MarksCardRenderer(
          template: templateForPreview,
          exam: _mockExam(templateForPreview),
          student: _mockStudent(),
          marks: _mockMarks(templateForPreview),
          schoolName: schoolName,
          schoolLogoUrl: schoolLogoUrl,
        ),
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                // ignore: use_null_aware_elements
                if (trailing != null) trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(label),
    );
  }

  ExamTemplate _buildTemplateForPreview() {
    final name = _nameController.text.trim();

    final safeColumns = _columns.isEmpty
        ? [
            ExamTemplateColumn(id: 'subject', label: 'Subject', type: MarksCardColumnType.subject),
            ExamTemplateColumn(id: 'marks', label: 'Marks', type: MarksCardColumnType.obtainedTotal),
          ]
        : _columns;

    final summary = <ExamTemplateSummaryRow>[];
    if (_summaryTotal) summary.add(const ExamTemplateSummaryRow(type: MarksCardSummaryRowType.total, label: 'Total'));
    if (_summaryPercent) summary.add(const ExamTemplateSummaryRow(type: MarksCardSummaryRowType.percentage, label: 'Percentage'));
    if (_summaryGrade) summary.add(const ExamTemplateSummaryRow(type: MarksCardSummaryRowType.grade, label: 'Grade'));

    return ExamTemplate(
      id: (widget.templateId ?? '').trim(),
      name: name.isEmpty ? '${widget.examTypeName} Template' : name,
      examTypeKey: widget.examTypeKey,
      examTypeName: widget.examTypeName,
      header: ExamTemplateHeaderConfig(
        showSchoolName: _showSchoolName,
        showExamName: _showExamName,
        showExamType: _showExamType,
        showAcademicYear: _showAcademicYear,
        headerText: _headerTextController.text,
      ),
      columns: safeColumns,
      summaryRows: summary.take(_maxSummary).toList(growable: false),
      extraFields: _extraFields.take(_maxExtraFields).toList(growable: false),
      signatures: ExamTemplateSignaturesConfig(
        showTeacher: _showTeacherSign,
        showPrincipal: _showPrincipalSign,
        teacherLabel: _teacherLabelController.text,
        principalLabel: _principalLabelController.text,
      ),
      createdAt: null,
      updatedAt: null,
    );
  }

  Future<ExamTemplateColumn?> _showAddColumnDialog(BuildContext context) async {
    final type = await showModalBottomSheet<MarksCardColumnType>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Add column', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              ListTile(
                leading: const Icon(Icons.subject_rounded),
                title: const Text('Subject'),
                onTap: () => Navigator.pop(ctx, MarksCardColumnType.subject),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_rounded),
                title: const Text('Max (Total)'),
                onTap: () => Navigator.pop(ctx, MarksCardColumnType.maxTotal),
              ),
              ListTile(
                leading: const Icon(Icons.score_rounded),
                title: const Text('Marks (Total obtained)'),
                onTap: () => Navigator.pop(ctx, MarksCardColumnType.obtainedTotal),
              ),
              ListTile(
                leading: const Icon(Icons.percent_rounded),
                title: const Text('Percentage'),
                onTap: () => Navigator.pop(ctx, MarksCardColumnType.percentage),
              ),
              ListTile(
                leading: const Icon(Icons.grade_rounded),
                title: const Text('Grade'),
                onTap: () => Navigator.pop(ctx, MarksCardColumnType.grade),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('Component (e.g. Oral / Written / Practical)'),
                onTap: () => Navigator.pop(ctx, MarksCardColumnType.component),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return null;

    if (type == null) return null;

    if (type == MarksCardColumnType.component) {
      final res = await _showComponentColumnDialog(context);
      if (!context.mounted) return null;
      if (res == null) return null;
      return res;
    }

    String defaultLabel(MarksCardColumnType t) {
      switch (t) {
        case MarksCardColumnType.subject:
          return 'Subject';
        case MarksCardColumnType.maxTotal:
          return 'Max';
        case MarksCardColumnType.obtainedTotal:
          return 'Marks';
        case MarksCardColumnType.percentage:
          return '%';
        case MarksCardColumnType.grade:
          return 'Grade';
        case MarksCardColumnType.component:
          return 'Component';
      }
    }

    return ExamTemplateColumn(
      id: _newId(prefix: type.name),
      label: defaultLabel(type),
      type: type,
    );
  }

  Future<ExamTemplateColumn?> _showComponentColumnDialog(BuildContext context) async {
    final labelController = TextEditingController();
    final keyController = TextEditingController();

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Component column'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Oral',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Component key',
                    hintText: 'oral',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Key is used for saving marks (lowercase, no spaces).',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );

      if (ok != true) return null;

      final label = labelController.text.trim();
      final key = normalizeKeyLower(keyController.text);

      if (label.isEmpty || key.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter both label and key.')),
          );
        }
        return null;
      }

      return ExamTemplateColumn(
        id: _newId(prefix: 'comp_$key'),
        label: label,
        type: MarksCardColumnType.component,
        componentKey: key,
      );
    } finally {
      labelController.dispose();
      keyController.dispose();
    }
  }

  Future<ExamTemplateExtraField?> _showUpsertExtraFieldDialog(
    BuildContext context, {
    ExamTemplateExtraField? initial,
  }) async {
    final labelController = TextEditingController(text: initial?.label ?? '');
    final valueController = TextEditingController(text: initial?.value ?? '');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(initial == null ? 'Add extra field' : 'Edit extra field'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value (optional)',
                    hintText: 'Excellent performance',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (ok != true) return null;

      final label = labelController.text.trim();
      if (label.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Label is required.')),
          );
        }
        return null;
      }

      return ExamTemplateExtraField(
        label: label,
        value: valueController.text,
      );
    } finally {
      labelController.dispose();
      valueController.dispose();
    }
  }

  String _newId({required String prefix}) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(9999);
    return '${prefix}_$now$salt';
  }

  Exam _mockExam(ExamTemplate t) {
    // Provide both legacy totals and component totals for preview.
    return Exam(
      id: 'preview',
      examName: 'Unit Test 1',
      examType: t.examTypeName,
      examTypeKey: t.examTypeKey,
      templateId: t.id,
      classId: '5',
      section: 'A',
      createdAt: DateTime.now(),
      subjectMaxMarks: const {
        'math': 50,
        'english': 50,
      },
      subjectComponentMaxMarks: const {
        'science': {'practical': 20, 'theory': 30},
      },
    );
  }

  Student _mockStudent() {
    return const Student(
      id: 'student_1',
      name: 'Aisha Khan',
      admissionNo: 'A-102',
      classId: '5',
      section: 'A',
      parentName: 'Parent',
      parentPhone: '000',
      academicYear: '2025-2026',
    );
  }

  ExamMarks _mockMarks(ExamTemplate t) {
    return const ExamMarks(
      studentId: 'student_1',
      subjectMarks: {
        'math': 44,
        'english': 38,
      },
      subjectComponentMarks: {
        'science': {'practical': 18, 'theory': 24},
      },
    );
  }

  Future<void> _save({
    required BuildContext context,
    required String schoolId,
  }) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required.')),
      );
      return;
    }

    if (_columns.length > _maxColumns) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Max $_maxColumns columns allowed.')),
      );
      return;
    }

    // Ensure there's always a Subject column.
    final hasSubject = _columns.any((c) => c.type == MarksCardColumnType.subject);
    if (!hasSubject) {
      setState(() {
        _columns.insert(
          0,
          ExamTemplateColumn(
            id: _newId(prefix: 'subject'),
            label: 'Subject',
            type: MarksCardColumnType.subject,
          ),
        );
      });
    }

    final template = _buildTemplateForPreview();

    try {
      final ref = await ExamTemplateService().upsertTemplate(
        schoolId: schoolId,
        template: template,
      );

      if (_setAsDefault) {
        await ExamTemplateService().setDefaultTemplateForExamType(
          schoolId: schoolId,
          examTypeKey: normalizeKeyLower(widget.examTypeKey),
          templateId: ref.id,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved')),
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
