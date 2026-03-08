import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:school_app/core/utils/firestore_keys.dart';

class HomeworkService {
  HomeworkService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> addHomework({
    required String schoolId,
    required String classId,
    required String section,
    required String subject,
    required String description,
    required DateTime dueDate,
  }) async {
    final teacher = _auth.currentUser;
    if (teacher == null) {
      throw Exception('Teacher not logged in');
    }

    final teacherId = teacher.uid;

    await _db.collection('schools').doc(schoolId).collection('homework').add({
      'classId': classId,
      'section': section,
      'classKey': classKeyFrom(classId, section),
      'subject': subject,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
