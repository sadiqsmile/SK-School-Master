import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeworkSubmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference submissionRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('homework_submissions');
  }

  Future<String> uploadFile({
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('homework_submissions/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> submitHomework({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await submissionRef(schoolId).add({
      ...data,
      "submittedAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSubmissions(String schoolId, String homeworkId) {
    return submissionRef(schoolId)
        .where('homeworkId', isEqualTo: homeworkId)
        .snapshots();
  }
}
