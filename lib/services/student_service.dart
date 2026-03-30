import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStudent({
    required Student student,
    required String schoolId,
  }) async {
    final doc = _firestore.collection('students').doc();

    await doc.set(student.toMap(schoolId));
  }

  Stream<List<Student>> getStudents(String schoolId) {
    return _firestore
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Student.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateStudent(Student student, String schoolId) async {
    await _firestore
        .collection('students')
        .doc(student.id)
        .update(student.toMap(schoolId));
  }

  // ✅ ONLY THIS DELETE FUNCTION
  Future<void> deleteStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
  }
}