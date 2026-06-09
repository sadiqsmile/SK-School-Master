import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final studentsCountProvider =
    FutureProvider.family<int, String>((ref, schoolId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('students')
      .get();

  return snapshot.docs.length;
});

final teachersCountProvider =
    FutureProvider.family<int, String>((ref, schoolId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('teachers')
      .get();

  return snapshot.docs.length;
});

final todayAttendanceProvider =
    FutureProvider.family<Map<String, int>, String>((ref, schoolId) async {
  int present = 0;
  int absent = 0;

  final today = DateTime.now();

  final todayDate =
      '${today.year}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  final snapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('attendance')
      .where('date', isEqualTo: todayDate)
      .get();

  for (final doc in snapshot.docs) {
    final students =
        doc.data()['students'] as Map<String, dynamic>?;

    if (students == null) continue;

    students.forEach((key, value) {
      if (value == 'P') present++;
      if (value == 'A') absent++;
    });
  }

  return {
    'present': present,
    'absent': absent,
  };
});
