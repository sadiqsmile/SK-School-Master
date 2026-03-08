import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherService {
  TeacherService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _teachersRef(String schoolId) {
    return _db.collection('schools').doc(schoolId).collection('teachers');
  }

  Future<DocumentReference<Map<String, dynamic>>> addTeacher({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    return _teachersRef(schoolId).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTeacher({
    required String schoolId,
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    await _teachersRef(schoolId).doc(teacherId).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateTeacher({
    required String schoolId,
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    await _teachersRef(schoolId).doc(teacherId).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
