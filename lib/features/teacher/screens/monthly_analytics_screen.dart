import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyAnalyticsScreen extends StatelessWidget {
  final String schoolId;
  final String className;
  final String section;

  const MonthlyAnalyticsScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Analytics")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .where('className', isEqualTo: className)
            .where('section', isEqualTo: section)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          int totalDays = 0;
          int present = 0;
          int absent = 0;
          int holiday = 0;

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final students =
                Map<String, dynamic>.from(data['students'] ?? {});
            final isHolidayDay = data['isHoliday'] ?? false;

            if (isHolidayDay) {
              holiday++;
              continue;
            }

            totalDays++;

            students.forEach((key, value) {
              if (value == 'P' || value == true) present++;
              if (value == 'A' || value == false) absent++;
            });
          }

          double percent =
              totalDays == 0 ? 0 : (present / (present + absent)) * 100;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card("Attendance %", "${percent.toStringAsFixed(1)}%"),
                _card("Present", "$present"),
                _card("Absent", "$absent"),
                _card("Holidays", "$holiday"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}