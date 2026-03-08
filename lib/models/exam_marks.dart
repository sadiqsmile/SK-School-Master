import 'package:cloud_firestore/cloud_firestore.dart';

class ExamMarks {
  const ExamMarks({
    required this.studentId,
    required this.subjectMarks,
  });

  final String studentId;
  final Map<String, int> subjectMarks;

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

    return ExamMarks(studentId: doc.id, subjectMarks: marks);
  }
}
