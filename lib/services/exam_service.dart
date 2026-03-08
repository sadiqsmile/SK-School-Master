import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/core/utils/firestore_keys.dart';

class ExamService {
  ExamService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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

    final normalizedId = normalizeKeyLower(trimmed);
    if (normalizedId.isEmpty) throw Exception('Invalid exam type name');

    final col = _db.collection('schools').doc(schoolId).collection('examTypes');
    final newRef = col.doc(normalizedId);

    // If renaming, prevent collisions.
    if (existingId != null && existingId != normalizedId) {
      final exists = await newRef.get();
      if (exists.exists) {
        throw Exception('Exam type already exists');
      }

      final oldDoc = await col.doc(existingId).get();
      final oldData = oldDoc.data() ?? const <String, dynamic>{};

      final batch = _db.batch();
      batch.set(
        newRef,
        {
          // Carry over any existing fields (e.g. defaultTemplateId) so renaming
          // doesn't lose settings.
          ...oldData,
          'name': trimmed,
          'normalizedName': normalizedId,
          // Keep existing createdAt if present, otherwise set it.
          if (oldData['createdAt'] is! Timestamp)
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
    String? examTypeKey,
    String? templateId,
  }) async {
    final trimmedExamName = examName.trim();
    if (trimmedExamName.isEmpty) {
      throw Exception('Exam name is required');
    }

    final trimmedType = examType.trim();
    final normalizedTypeKey = (examTypeKey ?? normalizeKeyLower(trimmedType)).trim();

    final ref = _db.collection('schools').doc(schoolId).collection('exams').doc();

    await ref.set({
      // New fields
      'examType': trimmedType,
      'examName': trimmedExamName,

      // Stable linking key for templates/defaults.
      if (normalizedTypeKey.isNotEmpty) 'examTypeKey': normalizedTypeKey,

      // Optional: lock a specific template to this exam.
      if (templateId != null && templateId.trim().isNotEmpty)
        'templateId': templateId.trim(),

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
    final subj = normalizeKeyLower(subjectKey);
    if (subj.isEmpty) throw Exception('Subject is required');
    if (maxMarks <= 0) throw Exception('Max marks must be greater than 0');

    final examRef = _db.collection('schools').doc(schoolId).collection('exams').doc(examId);

    final batch = _db.batch();

    // Persist max marks for the subject.
    // - Legacy: subjectMaxMarks.{subj} = max
    // - Canonical: subjectMaxByComponent.{subj}.total = max
    batch.set(
      examRef,
      {
        'subjects': FieldValue.arrayUnion([subj]),
        'subjectMaxMarks.$subj': maxMarks,
        'subjectMaxByComponent.$subj.total': maxMarks,
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
          // Legacy
          'subjectMarks.$subj': safeMark,
          // Canonical
          'subjects.$subj.total': safeMark,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Saves marks for a single subject *component* (e.g. oral/written/practical)
  /// for many students.
  ///
  /// Data structure:
  /// schools/{schoolId}/exams/{examId}
  ///   subjectComponentMaxMarks: { math: { oral: 10, written: 40 } }
  ///
  /// schools/{schoolId}/exams/{examId}/marks/{studentId}
  ///   subjectComponentMarks: { math: { oral: 8, written: 35 } }
  ///
  /// This intentionally does NOT try to keep `subjectMarks` in sync on write,
  /// because updating totals safely would require reading existing component
  /// values first. Clients can compute totals when rendering.
  Future<void> saveSubjectComponentMarks({
    required String schoolId,
    required String examId,
    required String subjectKey,
    required String componentKey,
    required int maxMarks,
    required Map<String, int> marksByStudentId,
  }) async {
    final subj = normalizeKeyLower(subjectKey);
    final comp = normalizeKeyLower(componentKey);
    if (subj.isEmpty) throw Exception('Subject is required');
    if (comp.isEmpty) throw Exception('Component key is required');
    if (maxMarks <= 0) throw Exception('Max marks must be greater than 0');

    final examRef = _db.collection('schools').doc(schoolId).collection('exams').doc(examId);
    final batch = _db.batch();

    // Persist max marks for the component.
    // - Legacy: subjectComponentMaxMarks.{subj}.{comp} = max
    // - Canonical: subjectMaxByComponent.{subj}.{comp} = max
    batch.set(
      examRef,
      {
        'subjects': FieldValue.arrayUnion([subj]),
        'subjectComponentMaxMarks.$subj.$comp': maxMarks,
        'subjectMaxByComponent.$subj.$comp': maxMarks,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final marksCol = examRef.collection('marks');
    for (final entry in marksByStudentId.entries) {
      final studentId = entry.key;
      final mark = entry.value;
      if (studentId.trim().isEmpty) continue;

      final safeMark = mark.clamp(0, maxMarks);
      final docRef = marksCol.doc(studentId);
      batch.set(
        docRef,
        {
          // Legacy
          'subjectComponentMarks.$subj.$comp': safeMark,
          // Canonical
          'subjects.$subj.$comp': safeMark,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
