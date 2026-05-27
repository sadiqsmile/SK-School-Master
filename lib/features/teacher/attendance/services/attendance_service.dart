import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

class AttendanceService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _docId({
    required String classId,
    required String section,
  }) {

    return "${classId}_$section";
  }

  String _dateKey(DateTime date) {

    return
        "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // =========================
  // SAVE ATTENDANCE
  // =========================

  Future<void> saveAttendance({

    required AttendanceModel
        attendance,
  }) async {

    final docId = _docId(

      classId:
          attendance.classId,

      section:
          attendance.section,
    );




final attendanceDateDoc =

    _firestore

        .collection('schools')

        .doc(attendance.schoolId)

        .collection('attendance')

        .doc(attendance.date);

await attendanceDateDoc.set({

  'date': attendance.date,

  'createdAt':
      FieldValue.serverTimestamp(),
});

await attendanceDateDoc

    .collection('classes')

    .doc(docId)

    .set(
      attendance.toMap(),
    );





  }





  // =========================
  // GET TODAY ATTENDANCE
  // =========================

  Stream<DocumentSnapshot>
      getAttendance({

    required String schoolId,

    required String classId,

    required String section,

    required DateTime date,
  }) {

    final dateKey =
        _dateKey(date);

    final docId =
        _docId(

      classId: classId,

      section: section,
    );


    return _firestore

        .collection('schools')

        .doc(schoolId)

        .collection('attendance')

        .doc(dateKey)

        .collection('classes')

        .doc(docId)

        .snapshots();
  }

  // =========================
  // CHECK ALREADY SUBMITTED
  // =========================

  Future<bool>
      attendanceExists({

    required String schoolId,

    required String classId,

    required String section,

    required DateTime date,
  }) async {

    final dateKey =
        _dateKey(date);

    final docId =
        _docId(

      classId: classId,

      section: section,
    );


    final doc = await _firestore

        .collection('schools')

        .doc(schoolId)

        .collection('attendance')

        .doc(dateKey)

        .collection('classes')

        .doc(docId)

        .get();

    return doc.exists;
  }

  // =========================
  // MONTHLY ATTENDANCE %
  // =========================

  Future<double>
      monthlyPercentage({

    required String schoolId,

    required String classId,

    required String section,

    required int year,

    required int month,
  }) async {

    int totalPresent = 0;

    int totalStudents = 0;

    for (int day = 1;
        day <= 31;
        day++) {

      try {

        final date =
            DateTime(
          year,
          month,
          day,
        );

        final dateKey =
            _dateKey(date);

        final docId =
            _docId(

          classId: classId,

          section: section,
        );

        final doc =
            await _firestore

                .collection('schools')

                .doc(schoolId)

                .collection(
                    'attendance')

                .doc(dateKey)

                .collection(
                    'classes')

                .doc(docId)

                .get();

        if (!doc.exists) {
          continue;
        }

        final data =
            doc.data()!;

        totalPresent +=
            (data['presentCount']
                    ?? 0)
                as int;

        totalStudents +=
            (data['totalStudents']
                    ?? 0)
                as int;

      } catch (e) {
        continue;
      }
    }

    if (totalStudents == 0) {
      return 0;
    }

    return
        (totalPresent /
                totalStudents) *
            100;
  }
}