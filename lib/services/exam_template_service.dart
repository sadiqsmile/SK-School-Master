import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/models/exam_template.dart';

class ExamTemplateService {
  ExamTemplateService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _templatesCol(String schoolId) {
    return _db.collection('schools').doc(schoolId).collection('examTemplates');
  }

  DocumentReference<Map<String, dynamic>> _examTypeDoc(String schoolId, String examTypeKey) {
    return _db.collection('schools').doc(schoolId).collection('examTypes').doc(examTypeKey);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> templatesSnapshots({
    required String schoolId,
    String? examTypeKey,
  }) {
    var q = _templatesCol(schoolId).orderBy('updatedAt', descending: true);
    final key = (examTypeKey ?? '').trim();
    if (key.isNotEmpty) {
      q = q.where('examTypeKey', isEqualTo: key);
    }
    return q.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> templateDocSnapshots({
    required String schoolId,
    required String templateId,
  }) {
    return _templatesCol(schoolId).doc(templateId).snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> upsertTemplate({
    required String schoolId,
    required ExamTemplate template,
  }) async {
    // When template.id is empty, create a new doc with auto id.
    final effectiveRef = template.id.isEmpty
        ? _templatesCol(schoolId).doc()
        : _templatesCol(schoolId).doc(template.id);

    await effectiveRef.set(
      {
        ...template.toMap(),
        if (template.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return effectiveRef;
  }

  Future<void> deleteTemplate({
    required String schoolId,
    required String templateId,
  }) async {
    await _templatesCol(schoolId).doc(templateId).delete();
  }

  Future<void> setDefaultTemplateForExamType({
    required String schoolId,
    required String examTypeKey,
    required String templateId,
  }) async {
    await _examTypeDoc(schoolId, examTypeKey).set(
      {
        'defaultTemplateId': templateId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
