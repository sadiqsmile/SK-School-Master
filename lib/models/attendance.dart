// models/attendance.dart
class Attendance {
  const Attendance({
    required this.studentId,
    required this.date,
    required this.present,
  });

  final String studentId;
  final String date;
  final bool present;
}
