// features/school_admin/students/services/student_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/core/utils/firestore_keys.dart';
import '../../../parent/services/parent_service.dart';

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
  final ParentService _parentService = ParentService();

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

    // Auto-create or link parent after student is persisted
    final fatherName =
        (data['fatherName'] ?? data['parentName'] ?? '').toString().trim();
    final parentPhone =
        (data['parentPhone'] ?? '').toString().trim();
    final studentName =
        (data['name'] ?? '').toString().trim();

    if (fatherName.isNotEmpty && parentPhone.isNotEmpty) {
      await _parentService.createOrLinkParent(
        schoolId: schoolId,
        studentId: docRef.id,
        studentName: studentName,
        parentName: fatherName,
        phone: parentPhone,
      );
    }

    return docRef;
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



final className =
    (normalized['className'] ?? '')
        .toString()
        .trim();

final sectionId =
    (normalized['section'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

if (className.isNotEmpty &&
    sectionId.isNotEmpty) {

  normalized['classKey'] =
      '${className.toLowerCase().replaceAll(' ', '_')}_$sectionId';
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

  // ==========================================================
  // ONE-TIME DATA MIGRATION
  // Fixes old boolean-format records (hostel: true, bus: true)
  // to the current string-format (type:'hostel', mess:'yes', transport:'no')
  // Safe to run multiple times – only updates docs that need it.
  // ==========================================================
  Future<int> migrateOldStudentData({required String schoolId}) async {
    final ref = _db
        .collection('schools')
        .doc(schoolId)
        .collection('students');

    final snapshot = await ref.get();
    int fixed = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      final hostelBool = data['hostel'];
      final busBool = data['bus'];

      // Only migrate docs that still use the old boolean fields
      if (hostelBool == true) {
        updates['type'] = 'hostel';
        updates['mess'] = 'yes';
        updates['transport'] = 'no'; // hostel students don't take bus
        updates['hostel'] = FieldValue.delete(); // remove legacy field
        if (busBool != null) updates['bus'] = FieldValue.delete();
      } else if (hostelBool == false) {
        // Day scholar with old boolean fields
        updates['type'] = 'day';
        updates['hostel'] = FieldValue.delete();
        // Preserve bus value, convert to string
        if (busBool == true) {
          updates['transport'] = 'yes';
        } else if (busBool == false) {
          updates['transport'] = 'no';
        }
        if (busBool != null) updates['bus'] = FieldValue.delete();
      }

      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
        fixed++;
      }
    }

    return fixed; // returns count of updated docs
  }
}