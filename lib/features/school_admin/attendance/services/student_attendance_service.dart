import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentAttendanceService {
  /// Monthly summary: Present / Absent / Holiday counts + percentage
  Future<Map<String, dynamic>> getStudentMonthlyAttendance({
    required String schoolId,
    required String studentId,
    required String className,
    required String section,
    required DateTime selectedMonth,
  }) async {
    int present = 0;
    int absent = 0;
    int holiday = 0;
    List<DateTime> absentDates = [];
    int totalDaysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );
    int enteredAttendanceDays = 0;

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .get();

    for (var doc in snapshot.docs) {
      final docId = doc.id;

      // Format: 7_A_2026-04-01
      final parts = docId.split('_');
      if (parts.length < 3) continue;

      // Filter class + section
      if (parts[0] != className || parts[1] != section) continue;

      // Parse date
      final dateString = parts[2];
      DateTime docDate;
      try {
        docDate = DateTime.parse(dateString);
      } catch (_) {
        continue;
      }

      // Filter month
      if (docDate.year != selectedMonth.year ||
          docDate.month != selectedMonth.month) {
        continue;
      }

      enteredAttendanceDays++;

      final data = doc.data();
      final students = data['students'] ?? {};

      if (students.containsKey(studentId)) {
        final status = students[studentId];
        if (status == 'P') present++;
        if (status == 'A') {
          absent++;
          absentDates.add(docDate);
        }
        if (status == 'H') holiday++;
      }
    }

    final percentage =
        totalDaysInMonth == 0 ? 0 : ((present / totalDaysInMonth) * 100).round();

    final bool shouldShowWarning = enteredAttendanceDays >= 20;

    absentDates.sort();

    return {
      'present': present,
      'absent': absent,
      'holiday': holiday,
      'percentage': percentage,
      'absentDates': absentDates,
      'totalDays': totalDaysInMonth,
      'enteredDays': enteredAttendanceDays,
      'showWarning': shouldShowWarning,
    };
  }

  /// Daily map: day number → status string (for calendar view)
  Future<Map<int, String>> getStudentDailyAttendance({
    required String schoolId,
    required String studentId,
    required String className,
    required String section,
    required DateTime selectedMonth,
  }) async {
    final Map<int, String> result = {};

    final monthPrefix =
        '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
    final docPrefix = '${className}_${section}_$monthPrefix';

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .get();

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (!docId.startsWith(docPrefix)) continue;

      final data = doc.data();
      final students = data['students'] as Map<String, dynamic>?;

      if (students != null && students.containsKey(studentId)) {
        final rawStatus = students[studentId];

        String status;
        switch (rawStatus) {
          case 'P':
            status = 'present';
            break;
          case 'A':
            status = 'absent';
            break;
          case 'H':
            status = 'holiday';
            break;
          default:
            status = 'absent';
        }

        // Extract day from end of docId: e.g. "7_A_2026-04-15" → 15
        final day = int.tryParse(docId.split('-').last);
        if (day != null) {
          result[day] = status;
        }
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAttendanceAnalytics({
    required String schoolId,
    required String studentId,
    required String className,
    required String section,
  }) async {
    List<Map<String, dynamic>> result = [];

    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(
        now.year,
        now.month - i,
      );

      final summary = await getStudentMonthlyAttendance(
        schoolId: schoolId,
        studentId: studentId,
        className: className,
        section: section,
        selectedMonth: targetMonth,
      );

      result.add({
        'monthName': _monthShort(targetMonth.month),
        'percentage': summary['percentage'] ?? 0,
      });
    }

    return result;
  }

  String _monthShort(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }
}
   