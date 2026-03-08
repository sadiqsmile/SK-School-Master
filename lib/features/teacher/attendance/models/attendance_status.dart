// features/teacher/attendance/models/attendance_status.dart

enum AttendanceStatus {
  present,
  absent,
  late,
  leave,
}

extension AttendanceStatusX on AttendanceStatus {
  String get code {
    return switch (this) {
      AttendanceStatus.present => 'present',
      AttendanceStatus.absent => 'absent',
      AttendanceStatus.late => 'late',
      AttendanceStatus.leave => 'leave',
    };
  }

  String get label {
    return switch (this) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.late => 'Late',
      AttendanceStatus.leave => 'Leave',
    };
  }

  static AttendanceStatus fromCode(String raw) {
    final code = raw.trim().toLowerCase();
    return switch (code) {
      'present' => AttendanceStatus.present,
      'absent' => AttendanceStatus.absent,
      'late' => AttendanceStatus.late,
      'leave' => AttendanceStatus.leave,
      _ => AttendanceStatus.present,
    };
  }
}
