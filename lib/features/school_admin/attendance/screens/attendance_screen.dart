// 🔴 SAME IMPORTS (unchanged)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/students/providers/students_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? classId;
  String? sectionId;

  List<Map<String, dynamic>> studentList = [];

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Mark Attendance',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// CLASS
            DropdownButtonFormField<String>(
              hint: const Text("Select Class"),
              value: classId,
              items: ['1','2','3','4','5','6','7','8','9','10']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text("Class $e"),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  classId = v;
                  sectionId = null;
                  studentList = [];
                });
              },
            ),

            const SizedBox(height: 10),

            /// SECTION
            DropdownButtonFormField<String>(
              hint: const Text("Select Section"),
              value: sectionId,
              items: ['A','B','C','D']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text("Section $e"),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  sectionId = v;
                  studentList = [];
                });
              },
            ),

            const SizedBox(height: 15),

            /// DATE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            if (classId != null && sectionId != null)
              Expanded(
                child: _StudentList(
                  classId: classId!,
                  sectionId: sectionId!,
                  studentList: studentList,
                  onInit: (list) => setState(() => studentList = list),
                  onStatusChanged: (i, status) =>
                      setState(() => studentList[i]['status'] = status),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _handleSave, // ✅ FIXED
        child: const Icon(Icons.save),
      ),
    );
  }

  /// ================= SAVE LOGIC =================

  void _handleSave() {
    if (studentList.isEmpty) return;

    int present =
        studentList.where((e) => e['status'] == "Present").length;

    if (present == studentList.length) {
      /// ⚠️ WARNING
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("⚠️ Verify Attendance"),
          content: const Text(
            "All students are marked Present.\nDid you verify attendance?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Review"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmSave();
              },
              child: const Text("Save Anyway"),
            ),
          ],
        ),
      );
    } else {
      _confirmSave();
    }
  }

  void _confirmSave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Save"),
        content: const Text("Are you sure you want to save attendance?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveAttendance();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final school = await ref.read(currentSchoolProvider.future);

    final today = DateTime.now().toString().split(' ')[0];

    final refDoc = FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id)
        .collection('attendance')
        .doc(today)
        .collection('meta');

    final docId = "class_${classId}_${sectionId}";

    int present = studentList.where((e) => e['status'] == "Present").length;
    int absent = studentList.where((e) => e['status'] == "Absent").length;
    int holiday = studentList.where((e) => e['status'] == "Holiday").length;

    await refDoc.doc(docId).set({
      "counts": {
        "present": present,
        "absent": absent,
        "holiday": holiday,
        "total": studentList.length,
      },
      "date": today,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Saved")),
    );
  }
}

/// ================= STUDENT LIST =================

class _StudentList extends ConsumerWidget {
        Widget _buildPieChart(int present, int absent, int total) {
          if (total == 0) return const SizedBox();
          return Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: present.toDouble(),
                    color: Colors.green,
                    title: 'P',
                  ),
                  PieChartSectionData(
                    value: absent.toDouble(),
                    color: Colors.red,
                    title: 'A',
                  ),
                ],
              ),
            ),
          );
        }
      Color _getToggleColor(String? status) {
        // You can add _isHoliday logic if needed
        switch (status) {
          case 'P':
            return Colors.green;
          case 'A':
            return Colors.red;
          case 'Holiday':
            return Colors.orange;
          default:
            return Colors.grey;
        }
      }
    void _toggleStudent(int i) {
      final current = studentList[i]['status'];
      if (current == null) {
        onStatusChanged(i, 'P');
      } else if (current == 'P') {
        onStatusChanged(i, 'A');
      } else {
        onStatusChanged(i, null);
      }
    }
  final String classId;
  final String sectionId;
  final List<Map<String, dynamic>> studentList;
  final Function(List<Map<String, dynamic>>) onInit;
  final Function(int, String?) onStatusChanged;

  const _StudentList({
    required this.classId,
    required this.sectionId,
    required this.studentList,
    required this.onInit,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("$e"),
      data: (snapshot) {

        final filtered = snapshot.docs.where((doc) {
          final d = doc.data();
          return d['classId'] == classId &&
                 d['sectionId'] == sectionId;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No students found"));
        }

        if (studentList.isEmpty) {
          final list = filtered.map((doc) {
            final d = doc.data();
              return {
                "name": d['name'] ?? 'No Name',
                "status": null, // Default to unmarked (grey)
              };
          }).toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            onInit(list);
          });
        }

        int present = studentList.where((e) => e['status'] == "Present").length;
        int absent = studentList.where((e) => e['status'] == "Absent").length;
        int holiday = studentList.where((e) => e['status'] == "Holiday").length;

        int totalPA = present + absent;

        double presentPercent =
            totalPA == 0 ? 0 : (present / totalPA) * 100;

        double absentPercent =
            totalPA == 0 ? 0 : (absent / totalPA) * 100;

        return Column(
          children: [
            // TOP ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        for (int i = 0; i < studentList.length; i++) {
                          onStatusChanged(i, "Present");
                        }
                      },
                      child: const Text("All Present"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        for (int i = 0; i < studentList.length; i++) {
                          onStatusChanged(i, "Holiday");
                        }
                      },
                      child: const Text("Holiday"),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _count("P", present, Colors.green),
                    _count("A", absent, Colors.red),
                    _count("H", holiday, Colors.blue),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Modern Pie Chart
            _buildPieChart(present, absent, studentList.length),
            const SizedBox(height: 10),
            // Present/Absent counts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("P = $present", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(width: 16),
                Text("A = $absent", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 10),
            // LIST
            Expanded(
              child: ListView.builder(
                itemCount: studentList.length,
                itemBuilder: (context, i) {
                  final s = studentList[i];
                  return Card(
                    child: ListTile(
                      title: Text(s['name']),
                      trailing: GestureDetector(
                        onTap: () => _toggleStudent(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _getToggleColor(s['status']),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            s['status'] ?? '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _count(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}