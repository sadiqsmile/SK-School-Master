import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference homeworkRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('homework');
  }

  Stream<QuerySnapshot> getHomework(String schoolId) {
    return homeworkRef(schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addHomework({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await homeworkRef(schoolId).add({
      ...data,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteHomework({
    required String schoolId,
    required String homeworkId,
  }) async {
    await homeworkRef(schoolId).doc(homeworkId).delete();
  }
}
