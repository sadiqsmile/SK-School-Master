import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/core/utils/firestore_keys.dart';

class PromotionResult {
  const PromotionResult({
    required this.promoted,
    required this.graduated,
    required this.skipped,
    required this.batches,
  });

  final int promoted;
  final int graduated;
  final int skipped;
  final int batches;
}

class PromotionPrecheckResult {
  const PromotionPrecheckResult({
    required this.totalStudents,
    required this.willPromote,
    required this.willGraduate,
    required this.willSkip,
    required this.missingTargetClassNames,
  });

  final int totalStudents;
  final int willPromote;
  final int willGraduate;
  final int willSkip;

  /// Map of missing target className -> number of affected students.
  final Map<String, int> missingTargetClassNames;
}

class PromotionService {
  PromotionService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<PromotionPrecheckResult> precheck({
    required String schoolId,
    required String fromAcademicYear,
  }) async {
    final studentsCol =
        _db.collection('schools').doc(schoolId).collection('students');
    final classesCol =
        _db.collection('schools').doc(schoolId).collection('classes');

    final classesSnap = await classesCol.get();
    final classNameToId = <String, String>{};
    final classIdToName = <String, String>{};
    for (final doc in classesSnap.docs) {
      final name = (doc.data()['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        classNameToId.putIfAbsent(name, () => doc.id);
      }
      classIdToName[doc.id] = name;
    }

    final q = await studentsCol
        .where('academicYear', isEqualTo: fromAcademicYear)
        .get();

    var willPromote = 0;
    var willGraduate = 0;
    var willSkip = 0;
    final missing = <String, int>{};

    for (final studentDoc in q.docs) {
      final data = studentDoc.data();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      if (status == 'graduated') {
        willSkip++;
        continue;
      }

      final currentClassId = (data['classId'] ?? '').toString();
      final currentClassName = (classIdToName[currentClassId] ?? '').trim();
      final nextClassName = _nextClassName(currentClassName);

      if (nextClassName == null) {
        willGraduate++;
        continue;
      }

      final nextClassId = classNameToId[nextClassName];
      if (nextClassId == null) {
        willSkip++;
        missing[nextClassName] = (missing[nextClassName] ?? 0) + 1;
        continue;
      }

      willPromote++;
    }

    return PromotionPrecheckResult(
      totalStudents: q.size,
      willPromote: willPromote,
      willGraduate: willGraduate,
      willSkip: willSkip,
      missingTargetClassNames: missing,
    );
  }

  /// Promote all students from [fromAcademicYear] to [toAcademicYear].
  ///
  /// Safety:
  /// - Does NOT delete students.
  /// - Writes a snapshot into `students/{id}/academicHistory/{fromAcademicYear}`
  ///   before updating the student's current class/year.
  ///
  /// Performance:
  /// - Uses batched writes.
  /// - Each student uses 2 write operations (history + update). We chunk batches
  ///   to stay within Firestore's 500 ops/batch limit.
  Future<PromotionResult> promoteAll({
    required String schoolId,
    required String fromAcademicYear,
    required String toAcademicYear,
  }) async {
    final studentsCol = _db.collection('schools').doc(schoolId).collection('students');
    final classesCol = _db.collection('schools').doc(schoolId).collection('classes');

    // Preload classes so we can map class "name" -> class docId.
    final classesSnap = await classesCol.get();
    final classNameToId = <String, String>{};
    final classIdToName = <String, String>{};
    for (final doc in classesSnap.docs) {
      final name = (doc.data()['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        // If duplicates exist, keep the first one deterministically.
        classNameToId.putIfAbsent(name, () => doc.id);
      }
      classIdToName[doc.id] = name;
    }

    // Query current students for the fromAcademicYear.
    final q = await studentsCol
        .where('academicYear', isEqualTo: fromAcademicYear)
        .get();

    var promoted = 0;
    var graduated = 0;
    var skipped = 0;
    var batches = 0;

    // 2 operations per student. Keep a safety margin.
    const maxOpsPerBatch = 450;
    final maxStudentsPerBatch = math.max(1, maxOpsPerBatch ~/ 2);

    final docs = q.docs;
    for (var start = 0; start < docs.length; start += maxStudentsPerBatch) {
      final end = math.min(docs.length, start + maxStudentsPerBatch);
      final chunk = docs.sublist(start, end);
      final batch = _db.batch();

      for (final studentDoc in chunk) {
        final data = studentDoc.data();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        if (status == 'graduated') {
          skipped++;
          continue;
        }

        final currentClassId = (data['classId'] ?? '').toString();
        final section = (data['section'] ?? '').toString();

        final currentClassName = (classIdToName[currentClassId] ?? '').trim();
        final nextClassName = _nextClassName(currentClassName);

        // Write history snapshot for the FROM year.
        final historyRef = studentDoc.reference
            .collection('academicHistory')
            .doc(fromAcademicYear);

        batch.set(historyRef, {
          'academicYear': fromAcademicYear,
          'classId': currentClassId,
          'className': currentClassName,
          'section': section,
          'snapshotAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (nextClassName == null) {
          // Graduate.
          graduated++;
          batch.update(studentDoc.reference, {
            'status': 'graduated',
            'academicYear': toAcademicYear,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          continue;
        }

        final nextClassId = classNameToId[nextClassName];
        if (nextClassId == null) {
          // Missing class setup (e.g. Class 6 not created). Skip to be safe.
          skipped++;
          // Still record a promotion attempt marker in history doc.
          batch.set(historyRef, {
            'promotionError': 'Missing target class: $nextClassName',
          }, SetOptions(merge: true));
          continue;
        }

        promoted++;
        batch.update(studentDoc.reference, {
          'classId': nextClassId,
          'section': section,
          'classKey': classKeyFrom(nextClassId, section),
          'academicYear': toAcademicYear,
          'status': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      batches++;
    }

    return PromotionResult(
      promoted: promoted,
      graduated: graduated,
      skipped: skipped,
      batches: batches,
    );
  }
}

String? _nextClassName(String currentClassName) {
  final c = currentClassName.trim().toUpperCase();
  if (c.isEmpty) return null;

  // Special cases.
  if (c == 'LKG') return 'UKG';
  if (c == 'UKG') return '1';

  final n = int.tryParse(c);
  if (n == null) return null;
  if (n >= 10) return null; // 10 -> graduated
  return '${n + 1}';
}
