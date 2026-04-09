import 'edit_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final String className;
  final String section;

  const AttendanceHistoryScreen({
    super.key,
    required this.className,
    required this.section,
  });

  Future<String> _getSchoolId() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc['schoolId'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance History")),
      body: FutureBuilder(
        future: _getSchoolId(),
        builder: (context, schoolSnap) {
          if (!schoolSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final schoolId = schoolSnap.data;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('attendance')
                .where('className', isEqualTo: className)
                .where('section', isEqualTo: section)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No records"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index];

                  final students =
                      Map<String, dynamic>.from(data['students']);

                  final present =
                      students.values.where((v) => v == true).length;
                  final total = students.length;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("Date: ${data['date']}"),
                      subtitle: Text(
                          "Present: $present / $total"),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditAttendanceScreen(
                              docId: data.id,
                              className: className,
                              section: section,
                              schoolId: schoolId, // 🔥 IMPORTANT
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
