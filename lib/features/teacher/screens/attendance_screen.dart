import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fl_chart/fl_chart.dart';

class AttendanceScreen extends StatefulWidget {
  final String className;
  final String section;

  const AttendanceScreen({
    super.key,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {

  Widget _legend(String title, int value, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text("$title ($value)"),
      ],
    );
  }

  Widget _buildPieChart(int present, int absent) {
    final total = present + absent;
    if (total == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Attendance Overview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: present.toDouble(),
                        color: Colors.green,
                        title: '',
                      ),
                      PieChartSectionData(
                        value: absent.toDouble(),
                        color: Colors.red,
                        title: '',
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${((present / total) * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("Present"),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legend("Present", present, Colors.green),
              _legend("Absent", absent, Colors.red),
            ],
          )
        ],
      ),
    );
  }

    Color _getColor(String? status) {
      if (isHoliday) return Colors.orange;
      switch (status) {
        case 'P':
          return Colors.green;
        case 'A':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
  Map<String, String?> attendance = {};
  bool isHoliday = false;
  bool isSaving = false;

  Future<String> _getSchoolId() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc['schoolId'];
  }

  Future<void> _confirmSave() async {
    final total = attendance.length;
    final present = attendance.values.where((e) => e == 'P').length;

    if (isHoliday || present == total) {
      final result = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Warning"),
          content: Text(
            isHoliday
                ? "You marked this day as Holiday"
                : "All students are Present",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Return"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save"),
            ),
          ],
        ),
      );

      if (result != true) return;
    }

    await _saveAttendance();
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);

    final schoolId = await _getSchoolId();
    final today = DateTime.now().toIso8601String().split('T')[0];

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .add({
      'className': widget.className,
      'section': widget.section,
      'date': today,
      'students': attendance,
      'isHoliday': isHoliday,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Saved ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - ${widget.section}"),
      ),
      body: FutureBuilder(
        future: _getSchoolId(),
        builder: (context, schoolSnapshot) {
          if (!schoolSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final schoolId = schoolSnapshot.data as String;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('students')
                .where('className', isEqualTo: widget.className)
                .where('section', isEqualTo: widget.section)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final students = snapshot.data!.docs;

              if (students.isEmpty) {
                return const Center(child: Text("No students found"));
              }

              int present = attendance.values.where((e) => e == 'P').length;
              int absent = attendance.values.where((e) => e == 'A').length;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isHoliday = false;
                                for (var key in attendance.keys) {
                                  attendance[key] = 'P';
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("Present All"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isHoliday = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text("Holiday"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pie chart
                  _buildPieChart(present, absent),
                  // Show counts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("P = $present", style: const TextStyle(color: Colors.green)),
                        Text("A = $absent", style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final doc = students[index];
                        final name = doc['name'];

                        attendance.putIfAbsent(doc.id, () => null);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(name),
                            trailing: GestureDetector(
                              onTap: () {
                                if (isHoliday) return;
                                setState(() {
                                  final current = attendance[doc.id];
                                  if (current == null) {
                                    attendance[doc.id] = 'P';
                                  } else if (current == 'P') {
                                    attendance[doc.id] = 'A';
                                  } else {
                                    attendance[doc.id] = null;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getColor(attendance[doc.id]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  attendance[doc.id] ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _confirmSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xff6366F1),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Save Attendance"),
                      ),
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}