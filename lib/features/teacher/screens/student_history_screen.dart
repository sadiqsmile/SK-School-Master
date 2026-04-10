import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentHistoryScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String schoolId;

  const StudentHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(studentName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .orderBy('date', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          int totalDays = 0;
          int present = 0;
          int absent = 0;
          int holiday = 0;

          List<Map<String, dynamic>> records = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final students =
                Map<String, dynamic>.from(data['students'] ?? {});
            final raw = students[studentId];

            String? status;

            if (raw == true) {
              status = 'P';
            } else if (raw == false) {
              status = 'A';
            } else {
              status = raw?.toString();
            }

            final isHoliday = data['isHoliday'] ?? false;

            if (isHoliday) {
              holiday++;
              records.add({
                'date': data['date'],
                'status': 'H'
              });
              continue;
            }

            if (status == null) continue;

            totalDays++;

            if (status == 'P') present++;
            if (status == 'A') absent++;

            records.add({
              'date': data['date'],
              'status': status,
            });
          }

          double percent =
              totalDays == 0 ? 0 : (present / totalDays) * 100;

          return Column(
            children: [

              /// 🔥 SUMMARY CARD
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "${percent.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Attendance",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _stat("P", present, Colors.green),
                        _stat("A", absent, Colors.red),
                        _stat("H", holiday, Colors.orange),
                      ],
                    )
                  ],
                ),
              ),

              /// 🔥 LIST
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(item['date']),
                          ),

                          CircleAvatar(
                            backgroundColor:
                                _getColor(item['status']),
                            child: Text(
                              item['status'],
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }

  /// 🔥 small stat widget
  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Text("$value",
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Color _getColor(String status) {
    switch (status) {
      case 'P':
        return Colors.green;
      case 'A':
        return Colors.red;
      case 'H':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
