class AttendanceModel {

  final String schoolId;

  final String classId;

  final String section;

  final String teacherId;

  final String date;

  final bool isHoliday;

  final Map<String, String>
      students;

  final int totalStudents;

  final int presentCount;

  final int absentCount;

  const AttendanceModel({

    required this.schoolId,

    required this.classId,

    required this.section,

    required this.teacherId,

    required this.date,

    required this.isHoliday,

    required this.students,

    required this.totalStudents,

    required this.presentCount,

    required this.absentCount,
  });

  factory AttendanceModel.fromMap(
    Map<String, dynamic> map,
  ) {

    return AttendanceModel(

      schoolId:
          map['schoolId'] ?? '',

      classId:
          map['classId'] ?? '',

      section:
          map['section'] ?? '',

      teacherId:
          map['teacherId'] ?? '',

      date:
          map['date'] ?? '',

      isHoliday:
          map['isHoliday'] ?? false,

      students:
          Map<String, String>.from(
        map['students'] ?? {},
      ),

      totalStudents:
          map['totalStudents'] ?? 0,

      presentCount:
          map['presentCount'] ?? 0,

      absentCount:
          map['absentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {

    return {

      'schoolId': schoolId,

      'classId': classId,

      'section': section,

      'teacherId': teacherId,

      'date': date,

      'isHoliday': isHoliday,

      'students': students,

      'totalStudents':
          totalStudents,

      'presentCount':
          presentCount,

      'absentCount':
          absentCount,
    };
  }

  double get percentage {

    if (totalStudents == 0) {
      return 0;
    }

    return
        (presentCount /
                totalStudents) *
            100;
  }
}