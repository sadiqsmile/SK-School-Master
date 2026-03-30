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

  return {
    'students': totalStudents,
    'totalFees': totalFees,
    'paidFees': paidFees,
    'pendingFees': pendingFees,
  };
});
