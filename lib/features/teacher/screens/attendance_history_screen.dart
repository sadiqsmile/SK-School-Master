import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String className;
  final String section;

  const AttendanceHistoryScreen({
    super.key,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
  String? schoolId;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      schoolId = doc['schoolId'];
    });
  }

  Color getColor(bool? present, DateTime date) {
    if (date.weekday == DateTime.sunday) {
      return Colors.orange; // Sunday
    }

    if (present == true) return Colors.green;
    if (present == false) return Colors.red;

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (schoolId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                initialDate: DateTime.now(),
              );

              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .where('className', isEqualTo: widget.className)
            .where('section', isEqualTo: widget.section)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No attendance records"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final dateStr = data['date'];
              final date = DateTime.parse(dateStr);

              if (selectedDate != null &&
                  selectedDate!.day != date.day) {
                return const SizedBox();
              }

              final students =
                  Map<String, dynamic>.from(data['students']);

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text("Date: $dateStr"),
                  children: students.entries.map((entry) {
                    final color =
                        getColor(entry.value, date);

                    return ListTile(
                      title: Text(entry.key),
                      trailing: Icon(
                        Icons.circle,
                        color: color,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}