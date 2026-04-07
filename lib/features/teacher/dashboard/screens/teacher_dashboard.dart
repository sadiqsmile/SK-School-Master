import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    print("🔥 CORRECT DASHBOARD RUNNING");
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

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

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("UID: ${user.uid}"),
              Text("SchoolID: $schoolId"),
              Text("TeacherID: $teacherId"),

              const SizedBox(height: 20),

              FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('schools')
                    .doc(schoolId)
                    .collection('teachers')
                    .doc(teacherId)
                    .get(),
                builder: (context, teacherSnapshot) {
                  if (!teacherSnapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  if (!teacherSnapshot.data!.exists) {
                    return const Text("❌ Teacher doc NOT FOUND");
                  }

                  final data =
                      teacherSnapshot.data!.data() as Map<String, dynamic>;

                  return Column(
                    children: [
                      Text("Assignments: ${data['assignmentKeys']}")
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
