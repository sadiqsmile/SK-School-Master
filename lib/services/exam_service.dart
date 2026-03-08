import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/core/utils/firestore_keys.dart';

class ExamService {
  ExamService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Creates/updates an exam type under:
  /// schools/{schoolId}/examTypes/{examTypeId}
  ///
  /// We use a normalized key as the document id to prevent duplicates.
  Future<DocumentReference<Map<String, dynamic>>> upsertExamType({
    required String schoolId,
    required String name,
    String? existingId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Exam type name is required');

    final normalizedId = _normalizeKey(trimmed);
    if (normalizedId.isEmpty) throw Exception('Invalid exam type name');

    final col = _db.collection('schools').doc(schoolId).collection('examTypes');
    final newRef = col.doc(normalizedId);

    // If renaming, prevent collisions.
    if (existingId != null && existingId != normalizedId) {
      final exists = await newRef.get();
      if (exists.exists) {
        throw Exception('Exam type already exists');
      }

      final batch = _db.batch();
      batch.set(
        newRef,
        {
          'name': trimmed,
          'normalizedName': normalizedId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      batch.delete(col.doc(existingId));
      await batch.commit();
      return newRef;
    }

    await newRef.set(
      {
        'name': trimmed,
        'normalizedName': normalizedId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return newRef;
  }

  Future<void> deleteExamType({
    required String schoolId,
    required String examTypeId,
  }) async {
    await _db
        .collection('schools')
        .doc(schoolId)
        .collection('examTypes')
        .doc(examTypeId)
        .delete();
  }

  /// Legacy create method (kept for compatibility).
  /// Prefer [createExamV2].
  Future<DocumentReference<Map<String, dynamic>>> createExam({
    required String schoolId,
    required String name,
    required String classId,
    required String section,
  }) {
    return createExamV2(
      schoolId: schoolId,
      examType: '',
      examName: name,
      classId: classId,
      section: section,
    );
  }

  /// Creates an exam with type + exam name.
  ///
  /// Firestore:
  /// schools/{schoolId}/exams/{examId}
  ///   examType: "Unit Test"
  ///   examName: "Unit Test 1"
  ///   classId, section, createdAt
  Future<DocumentReference<Map<String, dynamic>>> createExamV2({
    required String schoolId,
    required String examType,
    required String examName,
    required String classId,
    required String section,
  }) async {
    final trimmedExamName = examName.trim();
    if (trimmedExamName.isEmpty) {
      throw Exception('Exam name is required');
    }

    final trimmedType = examType.trim();

    final ref = _db.collection('schools').doc(schoolId).collection('exams').doc();

    await ref.set({
      // New fields
      'examType': trimmedType,
      'examName': trimmedExamName,

      // Backward compatibility field (older screens read `name`).
      'name': trimmedExamName,

      'classId': classId.trim(),
      'section': section.trim(),
      'classKey': classKeyFrom(classId, section),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref;
  }

  Future<void> deleteExam({
    required String schoolId,
    required String examId,
  }) async {
    await _db
        .collection('schools')
        .doc(schoolId)
        .collection('exams')
        .doc(examId)
        .delete();
  }

  /// Saves marks for a single subject for many students.
  ///
  /// Data structure:
  /// schools/{schoolId}/exams/{examId}/marks/{studentId}
  ///   subjectMarks: { subjectKey: mark }
  ///
  /// Also records max marks for this subject on the exam doc:
  ///   subjectMaxMarks: { subjectKey: maxMarks }
  Future<void> saveSubjectMarks({
    required String schoolId,
    required String examId,
    required String subjectKey,
    required int maxMarks,
    required Map<String, int> marksByStudentId,
  }) async {
    final subj = subjectKey.trim().toLowerCase();
    if (subj.isEmpty) throw Exception('Subject is required');
    if (maxMarks <= 0) throw Exception('Max marks must be greater than 0');

    final examRef = _db.collection('schools').doc(schoolId).collection('exams').doc(examId);

    final batch = _db.batch();

    // Persist max marks for the subject.
    batch.set(
      examRef,
      {
        'subjectMaxMarks': {subj: maxMarks},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final marksCol = examRef.collection('marks');
    for (final entry in marksByStudentId.entries) {
      final studentId = entry.key;
      final mark = entry.value;

      if (studentId.trim().isEmpty) continue;

      // Clamp defensively.
      final safeMark = mark.clamp(0, maxMarks);

      final docRef = marksCol.doc(studentId);
      batch.set(
        docRef,
        {
          'subjectMarks': {subj: safeMark},
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
