// features/school_admin/students/services/student_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/core/utils/firestore_keys.dart';

class DuplicateAdmissionNumberException implements Exception {
  DuplicateAdmissionNumberException(this.admissionNo);

  final String admissionNo;

  @override
  String toString() =>
      'DuplicateAdmissionNumberException(admissionNo: $admissionNo)';
}

class StudentService {
  StudentService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String> _resolveActiveAcademicYearId(
    String schoolId,
  ) async {
    final schoolSnap =
        await _db.collection('schools').doc(schoolId).get();

    final raw = (schoolSnap.data()?[
              'activeAcademicYearId'] ??
          '')
        .toString()
        .trim();

    if (raw.isNotEmpty) return raw;

    final now = DateTime.now();
    final start = now.year;

    return '$start-${start + 1}';
  }

  // ==========================================================
  // NORMAL ADD STUDENT (keeps duplicate protection)
  // ==========================================================
  Future<DocumentReference<Map<String, dynamic>>> addStudent({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _db
        .collection('schools')
        .doc(schoolId)
        .collection('students');

    final academicYearRaw =
        (data['academicYear'] ?? '').toString().trim();

    final defaultAcademicYear =
        academicYearRaw.isNotEmpty
            ? academicYearRaw
            : await _resolveActiveAcademicYearId(
                schoolId,
              );

    final admissionNoRaw =
        (data['admissionNo'] ?? '').toString();

    final admissionKey =
        admissionNoRaw.trim().toUpperCase();

    if (admissionKey.isEmpty) {
      throw ArgumentError(
        'admissionNo is required',
      );
    }

    final docRef = ref.doc(admissionKey);

    final legacy = await ref
        .where(
          'admissionNo',
          isEqualTo: admissionKey,
        )
        .limit(1)
        .get();

    if (legacy.docs.isNotEmpty) {
      throw DuplicateAdmissionNumberException(
        admissionKey,
      );
    }

    return _db.runTransaction((tx) async {
      final existing = await tx.get(docRef);

      if (existing.exists) {
        throw DuplicateAdmissionNumberException(
          admissionKey,
        );
      }

      final normalized = await _normalizeStudent(
        schoolId: schoolId,
        data: data,
        academicYearRaw: academicYearRaw,
        defaultAcademicYear:
            defaultAcademicYear,
      );

      tx.set(docRef, {
        ...normalized,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      return docRef;
    });
  }

  // ==========================================================
  // NEW UPSERT METHOD
  // Used for Excel import bulk update/add
  // ==========================================================
  Future<DocumentReference<Map<String, dynamic>>>
      upsertStudent({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _db
        .collection('schools')
        .doc(schoolId)
        .collection('students');

    final academicYearRaw =
        (data['academicYear'] ?? '').toString().trim();

    final defaultAcademicYear =
        academicYearRaw.isNotEmpty
            ? academicYearRaw
            : await _resolveActiveAcademicYearId(
                schoolId,
              );

    final admissionNoRaw =
        (data['admissionNo'] ?? '').toString();

    final admissionKey =
        admissionNoRaw.trim().toUpperCase();

    if (admissionKey.isEmpty) {
      throw ArgumentError(
        'admissionNo is required',
      );
    }

    final docRef = ref.doc(admissionKey);

    final normalized = await _normalizeStudent(
      schoolId: schoolId,
      data: data,
      academicYearRaw: academicYearRaw,
      defaultAcademicYear:
          defaultAcademicYear,
    );

    await docRef.set(
      {
        ...normalized,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return docRef;
  }

  // ==========================================================
  // SHARED NORMALIZER
  // ==========================================================
  Future<Map<String, dynamic>>
      _normalizeStudent({
    required String schoolId,
    required Map<String, dynamic> data,
    required String academicYearRaw,
    required String defaultAcademicYear,
  }) async {
    final normalized =
        <String, dynamic>{...data};

    final admissionKey =
        (data['admissionNo'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

    normalized['admissionNo'] =
        admissionKey;

    if (academicYearRaw.isEmpty) {
      normalized['academicYear'] =
          defaultAcademicYear;
    }

    final classId =
        (normalized['classId'] ?? '')
            .toString();

    final sectionId =
        (normalized['section'] ?? '')
            .toString();

    final ck = classKeyFrom(
      classId,
      sectionId,
    );

    if (ck != 'class__') {
      normalized['classKey'] = ck;
    }

    if (normalized['name'] != null) {
      normalized['name'] =
          normalized['name']
              .toString()
              .trim()
              .toUpperCase();

      normalized['nameLower'] =
          normalized['name']
              .toString()
              .toLowerCase();
    }

    if (normalized['parentName'] !=
        null) {
      normalized['parentName'] =
          normalized['parentName']
              .toString()
              .trim()
              .toUpperCase();

      normalized['parentNameLower'] =
          normalized['parentName']
              .toString()
              .toLowerCase();
    }

    normalized['admissionNoLower'] =
        admissionKey.toLowerCase();

    return normalized;
  }
}