import 'attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnapshot.data!.data() as Map<String, dynamic>;

          final schoolId = userData['schoolId'];
          final teacherId = userData['teacherId'];

          return FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('teachers')
                .doc(teacherId)
                .get(),
            builder: (context, teacherSnapshot) {
              if (!teacherSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!teacherSnapshot.data!.exists) {
                return const Center(child: Text("Teacher not found"));
              }

              final data =
                  teacherSnapshot.data!.data() as Map<String, dynamic>;

              final assignments =
                  List<String>.from(data['assignmentKeys'] ?? []);

              if (assignments.isEmpty) {
                return const Center(
                  child: Text("No classes assigned"),
                );
              }

              return ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final key = assignments[index];
                  final parts = key.split('_');

                  final className = parts[0];
                  final section = parts.length > 1 ? parts[1] : '';

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.class_),
                      title: Text(className),
                      subtitle: Text("Section $section"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              className: className,
                              section: section,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}