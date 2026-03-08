import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYearService {
  AcademicYearService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> ensureAcademicYear({
    required String schoolId,
    required String academicYearId,
  }) async {
    final startYear = _parseStartYear(academicYearId);
    final endYear = _parseEndYear(academicYearId);

    final ref = _db
        .collection('schools')
        .doc(schoolId)
        .collection('academicYears')
        .doc(academicYearId);

    // Use merge so re-running doesn't overwrite any custom fields.
    await ref.set({
      'id': academicYearId,
      ...?((startYear == null) ? null : <String, dynamic>{'startYear': startYear}),
      ...?((endYear == null) ? null : <String, dynamic>{'endYear': endYear}),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

int? _parseStartYear(String academicYearId) {
  final parts = academicYearId.split('-');
  if (parts.length != 2) return null;
  return int.tryParse(parts[0]);
}

int? _parseEndYear(String academicYearId) {
  final parts = academicYearId.split('-');
  if (parts.length != 2) return null;
  return int.tryParse(parts[1]);
}
