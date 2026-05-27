import 'package:cloud_firestore/cloud_firestore.dart';

class StudentLiveAnalyticsService {

  final FirebaseFirestore
      _firestore =
          FirebaseFirestore
              .instance;

  Future<Map<String, dynamic>>
      getStudentAnalytics({

    required String schoolId,

    required String studentId,

    required String classId,

    required String section,
  }) async {

    int present = 0;

    int absent = 0;

    final attendanceSnapshot =

        await _firestore

            .collection('schools')

            .doc(schoolId)

            .collection('attendance')

            .get();

    for (final dateDoc
        in attendanceSnapshot.docs) {

      final classDoc =
          await dateDoc.reference

              .collection(
                  'classes')

              .doc(
                '${classId}_$section',
              )

              .get();

      if (!classDoc.exists) {
        continue;
      }

      final data =
          classDoc.data();

      if (data == null) {
        continue;
      }

      final students =

          (data['students']
                  ?? {})
              as Map;

      final value =
          students[
                  studentId]
              ?.toString()
              .trim()
              .toLowerCase();

      if (value == 'p') {

        present++;

      } else if (
          value == 'a') {

        absent++;
      }
    }

    final total =
        present + absent;

    double percentage = 0;

    if (total > 0) {

      percentage =
          (present / total) *
              100;
    }

    return {

      'present': present,

      'absent': absent,

      'percentage':
          percentage,
    };
  }
}