import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/core/constants/marks_schema.dart';

class Exam {
  const Exam({
    required this.id,
    required this.examName,
    required this.examType,
    required this.examTypeKey,
    required this.templateId,
    required this.classId,
    required this.section,
    required this.createdAt,
    required this.subjectMaxMarks,
    required this.subjectComponentMaxMarks,
    this.subjectMaxByComponent = const <String, Map<String, int>>{},
    this.subjects = const <String>[],
  });

  final String id;
  final String examName;
  final String examType;
  /// Normalized, stable key used for linking templates/defaults.
  /// Example: "Unit Test" -> "unit_test"
  final String examTypeKey;

  /// Optional template locked to this exam.
  final String templateId;
  final String classId;
  final String section;
  final DateTime? createdAt;

  /// Optional map of subjectKey -> maxMarks.
  /// Stored on the exam doc as: subjectMaxMarks: { math: 50, english: 50 }
  final Map<String, int> subjectMaxMarks;

  /// Optional subjectKey -> componentKey -> maxMarks.
  /// Stored on the exam doc as:
  /// subjectComponentMaxMarks: { math: { oral: 10, written: 40 } }
  final Map<String, Map<String, int>> subjectComponentMaxMarks;

  /// Canonical schema: subjectKey -> componentKey -> maxMarks.
  ///
  /// Firestore field: subjectMaxByComponent
  /// Example: { math: { total: 50 } } OR { science: { theory: 30, practical: 20 } }
  final Map<String, Map<String, int>> subjectMaxByComponent;

  /// Optional explicit subject list on the exam doc.
  ///
  /// Firestore field: subjects (array)
  final List<String> subjects;

  /// Backward-compatible alias.
  String get name => examName;

  static Exam fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    DateTime? created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) created = rawCreated.toDate();

    final rawMax = data['subjectMaxMarks'];
    final Map<String, int> subjectMax = {};
    if (rawMax is Map) {
      for (final entry in rawMax.entries) {
        final key = entry.key?.toString();
        if (key == null || key.trim().isEmpty) continue;
        final v = entry.value;
        if (v is int) {
          subjectMax[key] = v;
        } else if (v is num) {
          subjectMax[key] = v.toInt();
        } else if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) subjectMax[key] = parsed;
        }
      }
    }

    final rawCompMax = data['subjectComponentMaxMarks'];
    final Map<String, Map<String, int>> compMax = {};
    if (rawCompMax is Map) {
      for (final entry in rawCompMax.entries) {
        final subj = entry.key?.toString();
        if (subj == null || subj.trim().isEmpty) continue;
        final v = entry.value;
        if (v is! Map) continue;

        final inner = <String, int>{};
        for (final innerEntry in v.entries) {
          final compKey = innerEntry.key?.toString();
          if (compKey == null || compKey.trim().isEmpty) continue;
          final compVal = innerEntry.value;
          if (compVal is int) {
            inner[compKey] = compVal;
          } else if (compVal is num) {
            inner[compKey] = compVal.toInt();
          } else if (compVal is String) {
            final parsed = int.tryParse(compVal);
            if (parsed != null) inner[compKey] = parsed;
          }
        }

        if (inner.isNotEmpty) compMax[subj] = inner;
      }
    }

    // Canonical max-by-component map.
    final rawMaxV2 = data['subjectMaxByComponent'];
    final Map<String, Map<String, int>> maxByComp = {};
    if (rawMaxV2 is Map) {
      for (final entry in rawMaxV2.entries) {
        final subj = entry.key?.toString();
        if (subj == null || subj.trim().isEmpty) continue;
        final v = entry.value;
        if (v is! Map) continue;

        final inner = <String, int>{};
        for (final innerEntry in v.entries) {
          final compKey = innerEntry.key?.toString();
          if (compKey == null || compKey.trim().isEmpty) continue;
          final compVal = innerEntry.value;
          if (compVal is int) {
            inner[compKey] = compVal;
          } else if (compVal is num) {
            inner[compKey] = compVal.toInt();
          } else if (compVal is String) {
            final parsed = int.tryParse(compVal);
            if (parsed != null) inner[compKey] = parsed;
          }
        }

        if (inner.isNotEmpty) maxByComp[subj] = inner;
      }
    }

    // Merge canonical into legacy-shaped maps so existing UI continues to work.
    // Canonical total -> subjectMaxMarks, other components -> subjectComponentMaxMarks.
    for (final subjEntry in maxByComp.entries) {
      final subj = subjEntry.key;
      final comps = subjEntry.value;

      final total = comps[kTotalComponentKey];
      if (total != null) {
        subjectMax[subj] = total;
      }

      final nonTotal = <String, int>{
        for (final e in comps.entries)
          if (e.key != kTotalComponentKey) e.key: e.value,
      };
      if (nonTotal.isNotEmpty) {
        compMax[subj] = {
          ...(compMax[subj] ?? const <String, int>{}),
          ...nonTotal,
        };
      }
    }

    final rawSubjects = data['subjects'];
    final List<String> subjects = [];
    if (rawSubjects is List) {
      for (final s in rawSubjects) {
        final k = s?.toString().trim();
        if (k == null || k.isEmpty) continue;
        subjects.add(k);
      }
    }

    return Exam(
      id: doc.id,
      examType: (data['examType'] ?? '').toString(),
      examTypeKey: (data['examTypeKey'] ?? '').toString(),
      templateId: (data['templateId'] ?? '').toString(),
      examName: (data['examName'] ?? data['name'] ?? '').toString(),
      classId: (data['classId'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      createdAt: created,
      subjectMaxMarks: subjectMax,
      subjectComponentMaxMarks: compMax,
      subjectMaxByComponent: maxByComp,
      subjects: subjects,
    );
  }
}
