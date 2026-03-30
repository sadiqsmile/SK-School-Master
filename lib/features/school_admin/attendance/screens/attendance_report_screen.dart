import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:school_app/providers/current_school_provider.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Report')),

      body: schoolAsync.when(
        data: (school) {
          final stream = FirebaseFirestore.instance
              .collection('schools')
              .doc(school.id)
              .collection('attendance')
              .doc(dateString)
              .collection('records')
              .snapshots();

          return Column(
            children: [
              // 📅 DATE PICKER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: _pickDate,
                      child: const Text('Select Date'),
                    )
                  ],
                ),
              ),

              // 📊 DATA
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text('No attendance found'));
                    }

                    int present = 0;
                    int absent = 0;

                    for (var doc in docs) {
                      if (doc['status'] == 'present') {
                        present++;
                      } else {
                        absent++;
                      }
                    }

                    return Column(
                      children: [
                        // SUMMARY
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _card('Present', present, Colors.green),
                            _card('Absent', absent, Colors.red),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final data = docs[i];
                              final status = data['status'];

                              return ListTile(
                                title: Text(docs[i].id),
                                trailing: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'present'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _card(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 5),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
