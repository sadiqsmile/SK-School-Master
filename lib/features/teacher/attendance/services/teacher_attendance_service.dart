// features/teacher/attendance/services/teacher_attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/teacher/attendance/models/attendance_status.dart';
import 'package:school_app/core/utils/firestore_keys.dart';

class AttendanceAlreadyMarkedException implements Exception {
  AttendanceAlreadyMarkedException();

  @override
  String toString() =>
      'AttendanceAlreadyMarkedException(Attendance already marked for this date/class/section)';
}

class TeacherAttendanceService {
  TeacherAttendanceService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Submits attendance for a date+class+section.
  ///
  /// Data layout (final):
  /// `schools/{schoolId}/attendance/{dateKey}` (doc)
  ///   - `meta/{classKey}` (doc) : lock + summary counts (duplicate protection)
  ///   - `{classKey}/{studentId}` (docs) : per-student attendance
  ///
  /// Where `classKey` looks like: `class_5_A`.
  Future<void> submitAttendance({
    required String schoolId,
    required String teacherUid,
    required String dateKey,
    required String classId,
    required String sectionId,
    required Map<String, AttendanceStatus> statuses,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('schoolId cannot be empty');
    }
    if (teacherUid.trim().isEmpty) {
      throw ArgumentError('teacherUid cannot be empty');
    }
    if (dateKey.trim().isEmpty) {
      throw ArgumentError('dateKey cannot be empty');
    }
    if (classId.trim().isEmpty) {
      throw ArgumentError('classId cannot be empty');
    }
    if (sectionId.trim().isEmpty) {
      throw ArgumentError('sectionId cannot be empty');
    }
    if (statuses.isEmpty) {
      throw ArgumentError('No students to submit');
    }

    final classKey = classKeyFrom(classId, sectionId);
    if (classKey == 'class__') {
      throw ArgumentError('Invalid classId/sectionId');
    }

    final dateDoc = _db
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(dateKey);

    final lockDoc = dateDoc.collection('meta').doc(classKey);
    final recordsCol = dateDoc.collection(classKey);

    // Quick local duplicate protection:
    // - Works even offline if the lock doc was created earlier on this device.
    // - If another device already submitted and we're offline, Firestore rules
    //   will reject the write when sync happens.
    try {
      final cached = await lockDoc.get(const GetOptions(source: Source.cache));
      if (cached.exists) {
        throw AttendanceAlreadyMarkedException();
      }
    } catch (_) {
      // Ignore cache read failures.
    }

    int present = 0;
    int absent = 0;
    int late = 0;
    int leave = 0;
    for (final s in statuses.values) {
      switch (s) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.leave:
          leave++;
      }
    }

    // Offline-friendly approach:
    // We create the lock + per-student docs in a single batch.
    // If the lock already exists, this becomes an update and is denied for
    // teachers by Firestore rules, preventing duplicates.
    final batch = _db.batch();

    batch.set(lockDoc, {
      'date': dateKey,
      'classId': classId,
      'sectionId': sectionId,
      'classKey': classKey,
      'markedBy': teacherUid,
      'markedAt': FieldValue.serverTimestamp(),
      // Local timestamp helps sorting/visibility while offline.
      'markedAtLocal': Timestamp.now(),
      'counts': {
        'present': present,
        'absent': absent,
        'late': late,
        'leave': leave,
        'total': statuses.length,
      },
    });

    // Helpful for browsing/reporting.
    batch.set(
      dateDoc,
      {
        'date': dateKey,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtLocal': Timestamp.now(),
      },
      SetOptions(merge: true),
    );

    for (final entry in statuses.entries) {
      final studentId = entry.key;
      final status = entry.value;
      final recordDoc = recordsCol.doc(studentId);

      batch.set(recordDoc, {
        'studentId': studentId,
        'status': status.code,
        'date': dateKey,
        'classId': classId,
        'sectionId': sectionId,
        'classKey': classKey,
        'markedBy': teacherUid,
        'markedAt': FieldValue.serverTimestamp(),
        'markedAtLocal': Timestamp.now(),
      });
    }

    await batch.commit();
  }
}
