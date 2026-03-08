// features/school_admin/students/services/student_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/core/utils/firestore_keys.dart';

class DuplicateAdmissionNumberException implements Exception {
  DuplicateAdmissionNumberException(this.admissionNo);

  final String admissionNo;

  @override
  String toString() => 'DuplicateAdmissionNumberException(admissionNo: $admissionNo)';
}

class StudentService {
  StudentService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String> _resolveActiveAcademicYearId(String schoolId) async {
    final schoolSnap = await _db.collection('schools').doc(schoolId).get();
    final raw = (schoolSnap.data()?['activeAcademicYearId'] ?? '').toString().trim();
    if (raw.isNotEmpty) return raw;

    final now = DateTime.now();
    final start = now.year;
    return '$start-${start + 1}';
  }

  Future<DocumentReference<Map<String, dynamic>>> addStudent({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _db.collection('schools').doc(schoolId).collection('students');

    // Academic year foundation:
    // If not provided by the UI/import, default to the school's active year.
    // This keeps promotion + reports consistent without breaking legacy data.
    final academicYearRaw = (data['academicYear'] ?? '').toString().trim();
    final defaultAcademicYear = academicYearRaw.isNotEmpty
        ? academicYearRaw
      : await _resolveActiveAcademicYearId(schoolId);

    final admissionNoRaw = (data['admissionNo'] ?? '').toString();
    final admissionKey = admissionNoRaw.trim().toUpperCase();
    if (admissionKey.isEmpty) {
      throw ArgumentError('admissionNo is required');
    }

    // Enforce uniqueness by using admission no as the document id.
    final docRef = ref.doc(admissionKey);

    // Also check for legacy records that may have used auto-generated doc IDs.
    final legacy =
        await ref.where('admissionNo', isEqualTo: admissionKey).limit(1).get();
    if (legacy.docs.isNotEmpty) {
      throw DuplicateAdmissionNumberException(admissionKey);
    }

    return _db.runTransaction((tx) async {
      final existing = await tx.get(docRef);
      if (existing.exists) {
        throw DuplicateAdmissionNumberException(admissionKey);
      }

      final normalized = <String, dynamic>{
        ...data,
        'admissionNo': admissionKey,
        if (academicYearRaw.trim().isEmpty) 'academicYear': defaultAcademicYear,
      };

      // Derived key used across attendance + rules.
      final classId = (normalized['classId'] ?? '').toString();
      final sectionId = (normalized['section'] ?? '').toString();
      final ck = classKeyFrom(classId, sectionId);
      if (ck != 'class__') {
        normalized['classKey'] = ck;
      }

      // Normalize names (ALL CAPS) at write-time to cover imports too.
      if (normalized['name'] != null) {
        normalized['name'] = normalized['name'].toString().trim().toUpperCase();
        normalized['nameLower'] = normalized['name'].toString().toLowerCase();
      }
      if (normalized['parentName'] != null) {
        normalized['parentName'] =
            normalized['parentName'].toString().trim().toUpperCase();
        normalized['parentNameLower'] = normalized['parentName'].toString().toLowerCase();
      }

      // Admission number is the document id; keep a normalized copy for querying too.
      normalized['admissionNoLower'] = admissionKey.toLowerCase();

      tx.set(docRef, {
        ...normalized,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef;
    });
  }
}

