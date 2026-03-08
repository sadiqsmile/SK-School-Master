import 'package:cloud_firestore/cloud_firestore.dart';

enum MarksCardColumnType {
  subject,
  maxTotal,
  obtainedTotal,
  percentage,
  grade,
  component,
}

MarksCardColumnType? marksCardColumnTypeFromString(String raw) {
  switch (raw) {
    case 'subject':
      return MarksCardColumnType.subject;
    case 'maxTotal':
      return MarksCardColumnType.maxTotal;
    case 'obtainedTotal':
      return MarksCardColumnType.obtainedTotal;
    case 'percentage':
      return MarksCardColumnType.percentage;
    case 'grade':
      return MarksCardColumnType.grade;
    case 'component':
      return MarksCardColumnType.component;
  }
  return null;
}

String marksCardColumnTypeToString(MarksCardColumnType t) {
  switch (t) {
    case MarksCardColumnType.subject:
      return 'subject';
    case MarksCardColumnType.maxTotal:
      return 'maxTotal';
    case MarksCardColumnType.obtainedTotal:
      return 'obtainedTotal';
    case MarksCardColumnType.percentage:
      return 'percentage';
    case MarksCardColumnType.grade:
      return 'grade';
    case MarksCardColumnType.component:
      return 'component';
  }
}

class ExamTemplateColumn {
  const ExamTemplateColumn({
    required this.id,
    required this.label,
    required this.type,
    this.componentKey,
  });

  final String id;
  final String label;
  final MarksCardColumnType type;

  /// Only for [MarksCardColumnType.component].
  final String? componentKey;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': marksCardColumnTypeToString(type),
      if (componentKey != null) 'componentKey': componentKey,
    };
  }

  static ExamTemplateColumn? fromMap(Object? raw) {
    if (raw is! Map) return null;

    final id = (raw['id'] ?? '').toString();
    final label = (raw['label'] ?? '').toString();
    final typeRaw = (raw['type'] ?? '').toString();
    final type = marksCardColumnTypeFromString(typeRaw);
    if (id.trim().isEmpty || label.trim().isEmpty || type == null) return null;

    final componentKey = (raw['componentKey'] ?? '').toString().trim();

    return ExamTemplateColumn(
      id: id,
      label: label,
      type: type,
      componentKey: componentKey.isEmpty ? null : componentKey,
    );
  }
}

enum MarksCardSummaryRowType { total, percentage, grade }

MarksCardSummaryRowType? marksCardSummaryRowTypeFromString(String raw) {
  switch (raw) {
    case 'total':
      return MarksCardSummaryRowType.total;
    case 'percentage':
      return MarksCardSummaryRowType.percentage;
    case 'grade':
      return MarksCardSummaryRowType.grade;
  }
  return null;
}

String marksCardSummaryRowTypeToString(MarksCardSummaryRowType t) {
  switch (t) {
    case MarksCardSummaryRowType.total:
      return 'total';
    case MarksCardSummaryRowType.percentage:
      return 'percentage';
    case MarksCardSummaryRowType.grade:
      return 'grade';
  }
}

class ExamTemplateSummaryRow {
  const ExamTemplateSummaryRow({
    required this.type,
    required this.label,
  });

  final MarksCardSummaryRowType type;
  final String label;

  Map<String, dynamic> toMap() {
    return {
      'type': marksCardSummaryRowTypeToString(type),
      'label': label,
    };
  }

  static ExamTemplateSummaryRow? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final typeRaw = (raw['type'] ?? '').toString();
    final type = marksCardSummaryRowTypeFromString(typeRaw);
    final label = (raw['label'] ?? '').toString();
    if (type == null || label.trim().isEmpty) return null;

    return ExamTemplateSummaryRow(type: type, label: label);
  }
}

class ExamTemplateExtraField {
  const ExamTemplateExtraField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
    };
  }

  static ExamTemplateExtraField? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final label = (raw['label'] ?? '').toString();
    if (label.trim().isEmpty) return null;
    final value = (raw['value'] ?? '').toString();
    return ExamTemplateExtraField(label: label, value: value);
  }
}

class ExamTemplateHeaderConfig {
  const ExamTemplateHeaderConfig({
    required this.showSchoolName,
    required this.showExamName,
    required this.showExamType,
    required this.showAcademicYear,
    required this.headerText,
  });

  final bool showSchoolName;
  final bool showExamName;
  final bool showExamType;
  final bool showAcademicYear;
  final String headerText;

  Map<String, dynamic> toMap() {
    return {
      'showSchoolName': showSchoolName,
      'showExamName': showExamName,
      'showExamType': showExamType,
      'showAcademicYear': showAcademicYear,
      'headerText': headerText,
    };
  }

  static ExamTemplateHeaderConfig fromMap(Object? raw) {
    if (raw is! Map) {
      return const ExamTemplateHeaderConfig(
        showSchoolName: true,
        showExamName: true,
        showExamType: true,
        showAcademicYear: true,
        headerText: '',
      );
    }

    return ExamTemplateHeaderConfig(
      showSchoolName: raw['showSchoolName'] == true,
      showExamName: raw['showExamName'] == true,
      showExamType: raw['showExamType'] == true,
      showAcademicYear: raw['showAcademicYear'] == true,
      headerText: (raw['headerText'] ?? '').toString(),
    );
  }
}

class ExamTemplateSignaturesConfig {
  const ExamTemplateSignaturesConfig({
    required this.showTeacher,
    required this.showPrincipal,
    required this.teacherLabel,
    required this.principalLabel,
  });

  final bool showTeacher;
  final bool showPrincipal;
  final String teacherLabel;
  final String principalLabel;

  Map<String, dynamic> toMap() {
    return {
      'showTeacher': showTeacher,
      'showPrincipal': showPrincipal,
      'teacherLabel': teacherLabel,
      'principalLabel': principalLabel,
    };
  }

  static ExamTemplateSignaturesConfig fromMap(Object? raw) {
    if (raw is! Map) {
      return const ExamTemplateSignaturesConfig(
        showTeacher: true,
        showPrincipal: true,
        teacherLabel: 'Class Teacher',
        principalLabel: 'Principal',
      );
    }

    return ExamTemplateSignaturesConfig(
      showTeacher: raw['showTeacher'] != false,
      showPrincipal: raw['showPrincipal'] != false,
      teacherLabel: (raw['teacherLabel'] ?? 'Class Teacher').toString(),
      principalLabel: (raw['principalLabel'] ?? 'Principal').toString(),
    );
  }
}

class ExamTemplate {
  const ExamTemplate({
    required this.id,
    required this.name,
    required this.examTypeKey,
    required this.examTypeName,
    required this.header,
    required this.columns,
    required this.summaryRows,
    required this.extraFields,
    required this.signatures,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Normalized key (usually equals examTypes doc id).
  final String examTypeKey;

  /// Display name for convenience.
  final String examTypeName;

  final ExamTemplateHeaderConfig header;
  final List<ExamTemplateColumn> columns;
  final List<ExamTemplateSummaryRow> summaryRows;
  final List<ExamTemplateExtraField> extraFields;
  final ExamTemplateSignaturesConfig signatures;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': 1,
      'name': name,
      'examTypeKey': examTypeKey,
      'examTypeName': examTypeName,
      'header': header.toMap(),
      'columns': columns.map((c) => c.toMap()).toList(growable: false),
      'summaryRows': summaryRows.map((r) => r.toMap()).toList(growable: false),
      'extraFields': extraFields.map((f) => f.toMap()).toList(growable: false),
      'signatures': signatures.toMap(),
    };
  }

  static ExamTemplate fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    DateTime? createdAt;
    final createdRaw = data['createdAt'];
    if (createdRaw is Timestamp) createdAt = createdRaw.toDate();

    DateTime? updatedAt;
    final updatedRaw = data['updatedAt'];
    if (updatedRaw is Timestamp) updatedAt = updatedRaw.toDate();

    final rawColumns = data['columns'];
    final columns = <ExamTemplateColumn>[];
    if (rawColumns is List) {
      for (final item in rawColumns) {
        final c = ExamTemplateColumn.fromMap(item);
        if (c != null) columns.add(c);
      }
    }

    final rawSummary = data['summaryRows'];
    final summary = <ExamTemplateSummaryRow>[];
    if (rawSummary is List) {
      for (final item in rawSummary) {
        final r = ExamTemplateSummaryRow.fromMap(item);
        if (r != null) summary.add(r);
      }
    }

    final rawExtra = data['extraFields'];
    final extra = <ExamTemplateExtraField>[];
    if (rawExtra is List) {
      for (final item in rawExtra) {
        final f = ExamTemplateExtraField.fromMap(item);
        if (f != null) extra.add(f);
      }
    }

    return ExamTemplate(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      examTypeKey: (data['examTypeKey'] ?? '').toString(),
      examTypeName: (data['examTypeName'] ?? '').toString(),
      header: ExamTemplateHeaderConfig.fromMap(data['header']),
      columns: columns,
      summaryRows: summary,
      extraFields: extra,
      signatures: ExamTemplateSignaturesConfig.fromMap(data['signatures']),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
