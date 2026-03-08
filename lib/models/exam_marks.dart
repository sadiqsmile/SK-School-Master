import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/core/constants/marks_schema.dart';

class ExamMarks {
  const ExamMarks({
    required this.studentId,
    required this.subjectMarks,
    required this.subjectComponentMarks,
    this.subjects = const <String, Map<String, int>>{},
  });

  final String studentId;
  final Map<String, int> subjectMarks;

  /// Optional subjectKey -> componentKey -> mark.
  /// Stored as: subjectComponentMarks: { math: { oral: 8, written: 35 } }
  final Map<String, Map<String, int>> subjectComponentMarks;

  /// Canonical schema: subjectKey -> componentKey -> mark.
  /// Stored as: subjects: { math: { total: 44 }, science: { practical: 18, theory: 24 } }
  final Map<String, Map<String, int>> subjects;

  static ExamMarks fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final raw = data['subjectMarks'];

    final Map<String, int> marks = {};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final k = entry.key?.toString();
        if (k == null || k.trim().isEmpty) continue;
        final v = entry.value;
        if (v is int) {
          marks[k] = v;
        } else if (v is num) {
          marks[k] = v.toInt();
        } else if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) marks[k] = parsed;
        }
      }
    }

    final rawComp = data['subjectComponentMarks'];
    final Map<String, Map<String, int>> compMarks = {};
    if (rawComp is Map) {
      for (final entry in rawComp.entries) {
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

        if (inner.isNotEmpty) compMarks[subj] = inner;
      }
    }

    // Canonical subjects map.
    final rawSubjects = data['subjects'];
    final Map<String, Map<String, int>> subjects = {};
    if (rawSubjects is Map) {
      for (final entry in rawSubjects.entries) {
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

        if (inner.isNotEmpty) subjects[subj] = inner;
      }
    }

    // Merge canonical into legacy-shaped maps so existing UI continues to work.
    for (final subjEntry in subjects.entries) {
      final subj = subjEntry.key;
      final comps = subjEntry.value;

      final total = comps[kTotalComponentKey];
      if (total != null) {
        marks[subj] = total;
      }

      final nonTotal = <String, int>{
        for (final e in comps.entries)
          if (e.key != kTotalComponentKey) e.key: e.value,
      };
      if (nonTotal.isNotEmpty) {
        compMarks[subj] = {
          ...(compMarks[subj] ?? const <String, int>{}),
          ...nonTotal,
        };
      }
    }

    return ExamMarks(
      studentId: doc.id,
      subjectMarks: marks,
      subjectComponentMarks: compMarks,
      subjects: subjects,
    );
  }
}
