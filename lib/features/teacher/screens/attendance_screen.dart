import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/attendance/screens/teacher_attendance_screen.dart';

/// Backward-compatible wrapper for the Teacher Attendance feature.
///
/// This matches the tutorial-style API: (classId, section) and internally
/// forwards to the Smart Attendance implementation.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.section,
  });

  final String classId;
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TeacherAttendanceScreen(
      classId: classId,
      sectionId: section,
    );
  }
}
