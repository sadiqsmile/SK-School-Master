import 'package:flutter/material.dart';

import 'package:school_app/core/utils/marks_calc.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/exam_template.dart';
import 'package:school_app/models/grading_system.dart';
import 'package:school_app/models/student.dart';

class MarksCardRenderer extends StatelessWidget {
  const MarksCardRenderer({
    super.key,
    required this.template,
    required this.exam,
    required this.student,
    required this.marks,
    this.schoolName,
    this.schoolLogoUrl,
    this.gradingSystem,
  });

  final ExamTemplate template;
  final Exam exam;
  final Student student;
  final ExamMarks? marks;
  final String? schoolName;
  final String? schoolLogoUrl;
  final GradingSystem? gradingSystem;

  @override
  Widget build(BuildContext context) {
    final derived = deriveSubjectRows(exam: exam, marks: marks);
    final totals = calcTotalsFromRows(derived);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              template: template,
              schoolName: schoolName,
              schoolLogoUrl: schoolLogoUrl,
              exam: exam,
              academicYear: student.academicYear,
            ),
            const SizedBox(height: 10),
            _StudentInfo(student: student),
            const SizedBox(height: 12),
            _MarksTable(
              template: template,
              rows: derived,
              totals: totals,
              gradingSystem: gradingSystem,
            ),
            const SizedBox(height: 12),
            _Summary(
              template: template,
              totals: totals,
              gradingSystem: gradingSystem,
            ),
            if (template.extraFields.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ExtraFields(fields: template.extraFields),
            ],
            if (template.signatures.showTeacher || template.signatures.showPrincipal) ...[
              const SizedBox(height: 16),
              _Signatures(signatures: template.signatures),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.template,
    required this.schoolName,
    required this.schoolLogoUrl,
    required this.exam,
    required this.academicYear,
  });

  final ExamTemplate template;
  final String? schoolName;
  final String? schoolLogoUrl;
  final Exam exam;
  final String academicYear;

  @override
  Widget build(BuildContext context) {
    final h = template.header;

    final lines = <String>[];
    if (h.headerText.trim().isNotEmpty) lines.add(h.headerText.trim());
    if (h.showSchoolName && (schoolName ?? '').trim().isNotEmpty) {
      lines.add((schoolName ?? '').trim());
    }

    if (h.showExamName) {
      final name = exam.examName.trim().isEmpty ? 'Exam' : exam.examName.trim();
      lines.add(name);
    }

    if (h.showExamType && exam.examType.trim().isNotEmpty) {
      lines.add(exam.examType.trim());
    }

    if (h.showAcademicYear && academicYear.trim().isNotEmpty) {
      lines.add('Academic Year: ${academicYear.trim()}');
    }

    final logoUrl = (schoolLogoUrl ?? '').trim();
    if (lines.isEmpty && logoUrl.isEmpty) return const SizedBox.shrink();

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 2),
            child: Text(
              lines[i],
              style: TextStyle(
                fontWeight: i <= 1 ? FontWeight.w900 : FontWeight.w700,
                fontSize: i == 0 ? 16 : 13,
              ),
            ),
          ),
      ],
    );

    if (logoUrl.isEmpty) {
      return textBlock;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.school_rounded, color: Color(0xFF0F172A));
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: textBlock),
      ],
    );
  }
}

class _StudentInfo extends StatelessWidget {
  const _StudentInfo({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final items = <String, String>{
      'Student': student.name.isEmpty ? student.id : student.name,
      'Admission': student.admissionNo,
      'Class': '${student.classId}${student.section}',
    };

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final e in items.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '${e.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: e.value.isEmpty ? '—' : e.value),
                ],
              ),
            ),
          ),
      ],
    );
  }
}


String _prettySubject(String key) {
  final cleaned = key.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned
      .split(' ')
      .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
      .join(' ');
}

String _grade(double percent, {GradingSystem? system}) {
  return gradeForPercent(percent, system: system);
}

class _MarksTable extends StatelessWidget {
  const _MarksTable({
    required this.template,
    required this.rows,
    required this.totals,
    required this.gradingSystem,
  });

  final ExamTemplate template;
  final List<DerivedSubjectRow> rows;
  final Totals totals;
  final GradingSystem? gradingSystem;

  @override
  Widget build(BuildContext context) {
    final cols = template.columns;
    if (cols.isEmpty) {
      return const Text(
        'Template has no columns yet.',
        style: TextStyle(color: Color(0xFF6B7280)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 56,
        columns: [
          for (final c in cols)
            DataColumn(
              label: Text(
                c.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
        rows: [
          for (final r in rows)
            DataRow(
              cells: [
                for (final c in cols)
                  DataCell(
                    Text(
                      _cellValue(column: c, row: r, totals: totals),
                      style: TextStyle(
                        fontWeight: c.type == MarksCardColumnType.subject
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _cellValue({
    required ExamTemplateColumn column,
    required DerivedSubjectRow row,
    required Totals totals,
  }) {
    switch (column.type) {
      case MarksCardColumnType.subject:
        return _prettySubject(row.subjectKey);
      case MarksCardColumnType.maxTotal:
        return row.outOf <= 0 ? '—' : row.outOf.toString();
      case MarksCardColumnType.obtainedTotal:
        return row.outOf <= 0 ? '—' : row.obtained.toString();
      case MarksCardColumnType.percentage:
        if (row.outOf <= 0) return '—';
        final p = (row.obtained / row.outOf) * 100.0;
        return '${p.toStringAsFixed(0)}%';
      case MarksCardColumnType.grade:
        if (row.outOf <= 0) return '—';
        final p = (row.obtained / row.outOf) * 100.0;
        return _grade(p, system: gradingSystem);
      case MarksCardColumnType.component:
        final compKey = (column.componentKey ?? '').trim();
        if (compKey.isEmpty) return '—';
        final got = row.componentObtained[compKey] ?? 0;
        final outOf = row.componentOutOf[compKey] ?? 0;
        if (outOf > 0) return '$got / $outOf';
        return got.toString();
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.template,
    required this.totals,
    required this.gradingSystem,
  });

  final ExamTemplate template;
  final Totals totals;
  final GradingSystem? gradingSystem;

  @override
  Widget build(BuildContext context) {
    final rows = template.summaryRows;
    if (rows.isEmpty) return const SizedBox.shrink();

    String valueFor(MarksCardSummaryRowType t) {
      switch (t) {
        case MarksCardSummaryRowType.total:
          return totals.outOf <= 0 ? '—' : '${totals.total} / ${totals.outOf}';
        case MarksCardSummaryRowType.percentage:
          return totals.outOf <= 0 ? '—' : '${totals.percent.toStringAsFixed(0)}%';
        case MarksCardSummaryRowType.grade:
          return totals.outOf <= 0
              ? '—'
              : _grade(totals.percent, system: gradingSystem);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  valueFor(r.type),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExtraFields extends StatelessWidget {
  const _ExtraFields({required this.fields});

  final List<ExamTemplateExtraField> fields;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  f.value.trim().isEmpty ? '—' : f.value.trim(),
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Signatures extends StatelessWidget {
  const _Signatures({required this.signatures});

  final ExamTemplateSignaturesConfig signatures;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (signatures.showTeacher)
          Expanded(
            child: _SignatureLine(label: signatures.teacherLabel),
          ),
        if (signatures.showTeacher && signatures.showPrincipal) const SizedBox(width: 18),
        if (signatures.showPrincipal)
          Expanded(
            child: _SignatureLine(label: signatures.principalLabel),
          ),
      ],
    );
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 1,
          color: const Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 6),
        Text(
          label.trim().isEmpty ? '—' : label.trim(),
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}
