import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/school_admin_provider.dart';

class ExamClassKey {
  const ExamClassKey({required this.classId, required this.section});

  final String classId;
  final String section;

  @override
  bool operator ==(Object other) {
    return other is ExamClassKey &&
        other.classId == classId &&
        other.section == section;
  }

  @override
  int get hashCode => Object.hash(classId, section);
}

/// Streams exam types for the current user's school.
///
/// Firestore:
/// schools/{schoolId}/examTypes/{examTypeId}
final examTypesProvider = StreamProvider.autoDispose<
    QuerySnapshot<Map<String, dynamic>>>(
  (ref) async* {
    final schoolId = await ref.watch(schoolIdProvider.future);
    yield* FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('examTypes')
        .snapshots();
  },
);

/// Streams exams for a class/section in the current user's school.
///
/// Firestore:
/// schools/{schoolId}/exams/{examId}
final examsByClassProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, ExamClassKey>((ref, key) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  // Avoid orderBy() to reduce composite index requirements.
  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('exams')
      .where('classId', isEqualTo: key.classId)
      .where('section', isEqualTo: key.section)
      .snapshots();
});

/// Streams marks docs for an exam.
///
/// Firestore:
/// schools/{schoolId}/exams/{examId}/marks/{studentId}
final examMarksProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, examId) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('exams')
      .doc(examId)
      .collection('marks')
      .snapshots();
});

/// Streams a single student's marks doc for an exam.
final studentExamMarksProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, ({String examId, String studentId})>((
  ref,
  args,
) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('exams')
      .doc(args.examId)
      .collection('marks')
      .doc(args.studentId)
      .snapshots();
});

/// Reads an exam doc.
final examDocProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, examId) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('exams')
      .doc(examId)
      .snapshots();
});
