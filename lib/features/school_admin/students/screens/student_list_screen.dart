import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_screen.dart';
import 'package:school_app/providers/current_school_provider.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      data: (school) {
        final schoolId = school.id;

        return Scaffold(
          appBar: AppBar(title: const Text("Students")),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddStudentScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .where('schoolId', isEqualTo: schoolId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final students = snapshot.data!.docs;

              if (students.isEmpty) {
                return const Center(child: Text("No Students Found"));
              }

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data =
                      students[index].data() as Map<String, dynamic>;

                  /// 🔥 FORCE CLASS NAME
                  final className = data['className'] ?? 'N/A';
                  final section = data['section'] ?? '';

                return ListTile(
  title: Text(data['name'] ?? ''),

  subtitle: Text(
    "Class: ${data.containsKey('className') ? data['className'] : data['classId']} | Section: ${data['section']}",
  ),
);
                },
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }
}