import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceAnalyticsService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<Map<String, dynamic>>
      monthlyAnalytics({

    required String schoolId,

    required String classId,

    required String section,

    required int year,

    required int month,
  }) async {


    int classStrength = 0;

    int workingDays = 0;

    int holidayDays = 0;


    int totalPresent = 0;

    final attendanceMap =
      <String, dynamic>{};

      final Map<String, int>
    studentPresentCount = {};

final Map<String, int>
    studentWorkingDays = {};

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

      if (date.month !=
        month) {
        continue;
      }

      final dateKey =
        "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

      final docId =
        "${classId}_$section";

      final classDoc =
        await _firestore
          .collection(
            'schools')
          .doc(schoolId)
          .collection(
            'attendance')
          .doc(dateKey)
          .collection(
            'classes')
          .doc(docId)
          .get();

      if (!classDoc.exists) {
        continue;
      }

      final data =
        classDoc.data()!;

      final holiday =
        data['isHoliday']
          ?? false;

      int present =
        (data['presentCount']
            ?? 0)
          .toInt();

      int total =
        (data['totalStudents']
            ?? 0)
          .toInt();

      classStrength =
        total;

     
     
      if (holiday) {

        holidayDays++;

        attendanceMap[
          dateKey] = {

        'holiday': true,

        'percentage': 0,

        'present': 0,

        'absent': 0,
        };

      } else {

        workingDays++;

        final dayPercentage =

          total > 0

            ? (present /
                total) *
              100

            : 0;

        attendanceMap[
          dateKey] = {

        'holiday': false,

        'percentage':
          dayPercentage,

        'present':
          present,

        'absent':
          total - present,
        };

        totalPresent +=
          present;
      }

final students =
    Map<String, dynamic>.from(
  data['students'] ?? {},
);

students.forEach(
  (studentId, status) {

    studentWorkingDays[
        studentId] =
        (studentWorkingDays[
                studentId] ??
            0) +
        1;

    if (status == 'P') {

      studentPresentCount[
          studentId] =
          (studentPresentCount[
                  studentId] ??
              0) +
          1;
    }
  },
);





      } catch (e) {

      continue;
      }
    }

    double percentage = 0;

    if (workingDays > 0 &&
      classStrength > 0) {

      percentage =

        (totalPresent /

            (classStrength *
              workingDays)) *

          100;
    }

final List<Map<String, dynamic>>
    studentAttendance = [];

studentWorkingDays.forEach(
  (studentId, days) {




    final present =
        studentPresentCount[
            studentId] ??
        0;




final percentage =
    days > 0
        ? (present / days) * 100
        : 0;

String studentName =
    studentId;

String photoUrl = '';

studentAttendance.add({

  'studentId': studentId,

  'studentName': studentName,

  'photoUrl': photoUrl,

  'present': present,

  'workingDays': days,

  'percentage': percentage,
});





  },
);

studentAttendance.sort(
  (a, b) =>
      a['percentage']
          .compareTo(
    b['percentage'],
  ),
);


    return {

'studentAttendance':
    studentAttendance,


        'percentage': percentage,
        'workingDays': workingDays,
        'holidayDays': holidayDays,
        'classStrength': classStrength,
        'totalPresent': totalPresent,
        'totalAbsent': (classStrength * workingDays) - totalPresent,
        'calendar': attendanceMap,
      };
  }
}