import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  const Exam({
    required this.id,
    required this.examName,
    required this.examType,
    required this.classId,
    required this.section,
    required this.createdAt,
    required this.subjectMaxMarks,
  });

  final String id;
  final String examName;
  final String examType;
  final String classId;
  final String section;
  final DateTime? createdAt;

  /// Optional map of subjectKey -> maxMarks.
  /// Stored on the exam doc as: subjectMaxMarks: { math: 50, english: 50 }
  final Map<String, int> subjectMaxMarks;

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

    return Exam(
      id: doc.id,
      examType: (data['examType'] ?? '').toString(),
      examName: (data['examName'] ?? data['name'] ?? '').toString(),
      classId: (data['classId'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      createdAt: created,
      subjectMaxMarks: subjectMax,
    );
  }
}
