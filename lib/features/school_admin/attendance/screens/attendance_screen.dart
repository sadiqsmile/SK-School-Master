import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/students/providers/students_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Map<String, bool> attendance = {};

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),

      body: studentsAsync.when(
        data: (snapshot) {
          final docs = snapshot.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No students found'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final id = docs[i].id;

              final name = data['name'] ?? 'No Name';
              final isPresent = attendance[id] ?? true;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: isPresent,
                        onChanged: (val) {
                          setState(() {
                            attendance[id] = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },

        loading: () =>
            const Center(child: CircularProgressIndicator()),

        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _saveAttendance,
        child: const Icon(Icons.save),
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
        .doc(today);

    for (var entry in attendance.entries) {
      await refDoc.collection('records').doc(entry.key).set({
        'status': entry.value ? 'present' : 'absent',
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved')),
      );
    }
  }
}