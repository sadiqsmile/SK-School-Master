import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYearBackfillResult {
  const AcademicYearBackfillResult({
    required this.updated,
    required this.skipped,
    required this.batches,
  });

  final int updated;
  final int skipped;
  final int batches;
}

/// Utilities to migrate older student records into the new academic-year model.
class StudentAcademicYearBackfillService {
  StudentAcademicYearBackfillService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Backfills missing `academicYear` on student docs.
  ///
  /// Notes:
  /// - Firestore can't query "field missing" directly, but `isNull: true`
  ///   matches missing or explicit null.
  /// - We do NOT overwrite existing academicYear.
  Future<AcademicYearBackfillResult> backfillMissingAcademicYear({
    required String schoolId,
    required String academicYearId,
  }) async {
    final studentsCol =
        _db.collection('schools').doc(schoolId).collection('students');

    // This matches both missing and null fields.
    final snap = await studentsCol.where('academicYear', isNull: true).get();

    var updated = 0;
    var skipped = 0;
    var batches = 0;

    const maxOpsPerBatch = 450;
    final maxDocsPerBatch = math.max(1, maxOpsPerBatch);
    final docs = snap.docs;

    for (var start = 0; start < docs.length; start += maxDocsPerBatch) {
      final end = math.min(docs.length, start + maxDocsPerBatch);
      final chunk = docs.sublist(start, end);
      final batch = _db.batch();

      for (final doc in chunk) {
        final data = doc.data();
        final existing = (data['academicYear'] ?? '').toString().trim();
        if (existing.isNotEmpty) {
          skipped++;
          continue;
        }

        updated++;
        batch.update(doc.reference, {
          'academicYear': academicYearId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      batches++;
    }

    return AcademicYearBackfillResult(
      updated: updated,
      skipped: skipped,
      batches: batches,
    );
  }
}
