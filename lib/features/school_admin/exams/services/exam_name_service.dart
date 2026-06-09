import 'package:cloud_firestore/cloud_firestore.dart';

class ExamNameService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> addExamName({
    required String schoolId,
    required String name,
  }) async {

    final existing =
        await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('exam_names')
            .where(
              'name',
              isEqualTo: name,
            )
            .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'Exam name already exists',
      );
    }

    final count =
        await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('exam_names')
            .count()
            .get();

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('exam_names')
        .add({
      'name': name,
      'order': count.count ?? 0,
      'active': true,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExamName({
    required String schoolId,
    required String docId,
  }) async {

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('exam_names')
        .doc(docId)
        .delete();
  }

  Future<void> updateExamName({
    required String schoolId,
    required String docId,
    required String name,
  }) async {

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('exam_names')
        .doc(docId)
        .update({
      'name': name,
    });
  }
}