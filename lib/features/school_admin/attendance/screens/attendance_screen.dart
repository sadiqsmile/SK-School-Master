import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/attendance/services/save_attendance.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/students/providers/students_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart' as classes_stream;
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() =>
      _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? selectedClassId;
  String? selectedSectionId;

  List<Map<String, dynamic>> studentList = [];

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classes_stream.classesProvider);

    return AdminLayout(
      title: "Mark Attendance",
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// CLASS
          classesAsync.when(
            data: (snap) => DropdownButtonFormField<String>(
              value: selectedClassId,
              hint: const Text("Select Class"),
              items: snap.docs.map((d) {
                final data = d.data() as Map<String, dynamic>?;
                final name = (data?['name'] ?? d.id).toString();

                return DropdownMenuItem(
                  value: d.id,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedClassId = v;
                  selectedSectionId = null;
                  studentList = [];
                });
              },
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text("$e"),
          ),

          const SizedBox(height: 10),

          /// SECTION
          if (selectedClassId != null)
            ref.watch(sectionsProvider(selectedClassId!)).when(
              data: (snap) => DropdownButtonFormField<String>(
                value: selectedSectionId,
                hint: const Text("Select Section"),
                items: snap.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>?;
                  final name = (data?['name'] ?? d.id).toString();

                  return DropdownMenuItem(
                    value: d.id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedSectionId = v;
                    studentList = [];
                  });
                },
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text("$e"),
            ),

          const SizedBox(height: 20),

          /// STUDENTS
          if (selectedClassId != null && selectedSectionId != null)
            _StudentList(
              classId: selectedClassId!,
              sectionId: selectedSectionId!,
              onInit: (list) {
                setState(() {
                  studentList = list;
                });
              },
              onStatusChanged: (i, status) {
                setState(() {
                  studentList[i]['status'] = status;
                });
              },
              studentList: studentList,
            ),
        ],
      ),

      /// SAVE BUTTON
      floatingActionButton: (selectedClassId != null &&
              selectedSectionId != null &&
              studentList.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () async {
                final school =
                    ref.read(currentSchoolProvider).value;

                if (school == null) return;

                await saveAttendance(
                  schoolId: school.id,
                  classId: selectedClassId!,
                  sectionId: selectedSectionId!,
                  date: DateTime.now(),
                  students: studentList,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Saved ✅")),
                  );
                }
              },
              child: const Icon(Icons.save),
            )
          : null,
    );
  }
}

/// 🔥 CLEAN STUDENT LIST
class _StudentList extends ConsumerWidget {
  final String classId;
  final String sectionId;
  final List<Map<String, dynamic>> studentList;
  final Function(List<Map<String, dynamic>>) onInit;
  final Function(int, String) onStatusChanged;

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
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("$e"),
      data: (snapshot) {
        /// 🔥 FILTER
        final filtered = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['classId'] == classId &&
                 data['sectionId'] == sectionId;
        }).toList();

        /// INIT ONLY ONCE
        if (studentList.isEmpty) {
          final list = filtered.map((doc) {
            final data = doc.data();
            return {
              "name": data['name'] ?? 'No Name',
              "status": "Present",
            };
          }).toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            onInit(list);
          });
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: studentList.length,
          itemBuilder: (context, i) {
            final s = studentList[i];

            return Card(
              child: ListTile(
                title: Text(s['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s['status'] == "Present"
                          ? "Present"
                          : "Absent",
                      style: TextStyle(
                        color: s['status'] == "Present"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    Switch(
                      value: s['status'] == "Present",
                      onChanged: (val) {
                        onStatusChanged(
                            i, val ? "Present" : "Absent");
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}