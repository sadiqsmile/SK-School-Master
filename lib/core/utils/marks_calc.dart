import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/models/grading_system.dart';
import 'package:school_app/core/constants/marks_schema.dart';

// Uses [kTotalComponentKey] from core/constants/marks_schema.dart.

typedef DerivedSubjectRow = ({
  String subjectKey,
  int obtained,
  int outOf,
  Map<String, int> componentObtained,
  Map<String, int> componentOutOf,
});

typedef Totals = ({int total, int outOf, double percent});

List<DerivedSubjectRow> deriveSubjectRows({
  required Exam exam,
  required ExamMarks? marks,
}) {
  final subjKeys = <String>{
    ...exam.subjectMaxMarks.keys,
    ...exam.subjectComponentMaxMarks.keys,
    ...exam.subjectMaxByComponent.keys,
    ...?marks?.subjectMarks.keys,
    ...?marks?.subjectComponentMarks.keys,
    ...?marks?.subjects.keys,
  }
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false)
    ..sort();

  int sumMap(Map<String, int> m) => m.values.fold<int>(0, (a, b) => a + b);

  Map<String, int> maxForSubject(String subj) {
    // Prefer canonical map when present.
    final canonical = exam.subjectMaxByComponent[subj];
    if (canonical != null && canonical.isNotEmpty) return canonical;

    // Backward compatibility: legacy split fields.
    final comp = exam.subjectComponentMaxMarks[subj] ?? const <String, int>{};
    if (comp.isNotEmpty) return comp;

    final total = exam.subjectMaxMarks[subj];
    if (total != null) return {kTotalComponentKey: total};

    return const <String, int>{};
  }

  Map<String, int> marksForSubject(String subj) {
    // Prefer canonical map when present.
    final canonical = marks?.subjects[subj];
    if (canonical != null && canonical.isNotEmpty) return canonical;

    // Backward compatibility: legacy split fields.
    final comp = marks?.subjectComponentMarks[subj] ?? const <String, int>{};
    if (comp.isNotEmpty) return comp;

    final total = marks?.subjectMarks[subj];
    if (total != null) return {kTotalComponentKey: total};

    return const <String, int>{};
  }

  bool hasNonTotalKeys(Map<String, int> m) {
    return m.keys.any((k) => k.trim().isNotEmpty && k != kTotalComponentKey);
  }

  int obtainedFrom(Map<String, int> compObt, Map<String, int> compOutOf) {
    // If exam defines real components, sum them; else use the stored total.
    if (hasNonTotalKeys(compOutOf)) {
      final only = {
        for (final e in compObt.entries)
          if (e.key != kTotalComponentKey) e.key: e.value,
      };
      return sumMap(only);
    }

    return compObt[kTotalComponentKey] ?? (compObt.isEmpty ? 0 : sumMap(compObt));
  }

  int outOfFrom(Map<String, int> compOutOf) {
    if (hasNonTotalKeys(compOutOf)) {
      final only = {
        for (final e in compOutOf.entries)
          if (e.key != kTotalComponentKey) e.key: e.value,
      };
      return sumMap(only);
    }

    return compOutOf[kTotalComponentKey] ?? (compOutOf.isEmpty ? 0 : sumMap(compOutOf));
  }

  return [
    for (final subj in subjKeys)
      () {
        final compOutOf = maxForSubject(subj);
        final compObt = marksForSubject(subj);

        final obtained = obtainedFrom(compObt, compOutOf);
        final outOf = outOfFrom(compOutOf);

        final visibleCompKeys = <String>{
          ...compOutOf.keys,
          ...compObt.keys,
        }.where((k) => k.trim().isNotEmpty).toList(growable: false)
          ..sort();

        final componentObtained = <String, int>{
          for (final k in visibleCompKeys) k: compObt[k] ?? 0,
        };
        final componentOutOf = <String, int>{
          for (final k in visibleCompKeys) k: compOutOf[k] ?? 0,
        };

        return (
          subjectKey: subj,
          obtained: obtained,
          outOf: outOf,
          componentObtained: componentObtained,
          componentOutOf: componentOutOf,
        );
      }(),
  ];
}

Totals calcTotalsFromRows(List<DerivedSubjectRow> rows) {
  var total = 0;
  var outOf = 0;

  for (final r in rows) {
    if (r.outOf <= 0) continue;
    total += r.obtained;
    outOf += r.outOf;
  }

  final percent = outOf <= 0 ? 0.0 : (total / outOf) * 100.0;
  return (total: total, outOf: outOf, percent: percent);
}

Totals calcTotals({
  required Exam exam,
  required ExamMarks? marks,
}) {
  final rows = deriveSubjectRows(exam: exam, marks: marks);
  return calcTotalsFromRows(rows);
}

String gradeForPercent(
  double percent, {
  GradingSystem? system,
}) {
  final s = system ?? GradingSystem.defaults();

  // Defensive: ensure sorted descending.
  final bands = [...s.bands]..sort((a, b) => b.minPercent.compareTo(a.minPercent));

  for (final b in bands) {
    if (percent >= b.minPercent) return b.grade;
  }

  // Shouldn't happen because a 0% band is expected.
  return bands.isEmpty ? '—' : bands.last.grade;
}
