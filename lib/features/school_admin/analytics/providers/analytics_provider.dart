import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';

final analyticsProvider = FutureProvider((ref) async {
  final school = await ref.read(currentSchoolProvider.future);

  final studentsSnapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(school.id)
      .collection('students')
      .get();

  final teachersSnapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(school.id)
      .collection('teachers')
      .get();

  final teachersCount = teachersSnapshot.docs.length;

  int totalStudents = studentsSnapshot.docs.length;

  double totalFees = 0;
  double paidFees = 0;

  for (var student in studentsSnapshot.docs) {
    final feesSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id)
        .collection('students')
        .doc(student.id)
        .collection('fees')
        .get();

    for (var fee in feesSnapshot.docs) {
      final amount = (fee['amount'] ?? 0).toDouble();
      final status = fee['status'];

      totalFees += amount;

      if (status == 'paid') {
        paidFees += amount;
      }
    }
  }

  final pendingFees = totalFees - paidFees;

  final today = DateTime.now();
  final todayDate =
      '${today.year}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  final attendanceSnapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(school.id)
      .collection('attendance')
      .where('date', isEqualTo: todayDate)
      .get();

  int todayPresent = 0;
  int todayAbsent = 0;

  for (final doc in attendanceSnapshot.docs) {
    final data = doc.data();
    final students = data['students'] as Map<String, dynamic>?;
    if (students == null) continue;
    for (final value in students.values) {
      if (value == 'P') todayPresent++;
      if (value == 'A') todayAbsent++;
    }
  }

  final totalAttendance = todayPresent + todayAbsent;
  final attendancePercentage = totalAttendance == 0
      ? 0
      : ((todayPresent / totalAttendance) * 100).round();
  final attendanceSubmitted = attendanceSnapshot.docs.isNotEmpty;

  return {
    'students': totalStudents,
    'teachers': teachersCount,
    'totalFees': totalFees,
    'paidFees': paidFees,
    'pendingFees': pendingFees,
    'todayPresent': todayPresent,
    'todayAbsent': todayAbsent,
    'attendancePercentage': attendancePercentage,
    'attendanceSubmitted': attendanceSubmitted,
  };
});
