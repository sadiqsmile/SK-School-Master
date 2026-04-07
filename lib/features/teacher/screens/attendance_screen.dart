import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Map<String, bool> attendance = {};
  bool isSaving = false;

  Future<String> _getSchoolId() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc['schoolId'];
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);

    final schoolId = await _getSchoolId();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final docId = "${widget.className}_${widget.section}_$today";

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(docId)
        .set({
      'className': widget.className,
      'section': widget.section,
      'date': today,
      'students': attendance,
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

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final doc = students[index];
                        final name = doc['name'];

                        attendance.putIfAbsent(doc.id, () => true);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(name),
                            trailing: Switch(
                              value: attendance[doc.id]!,
                              onChanged: (val) {
                                setState(() {
                                  attendance[doc.id] = val;
                                });
                              },
                              activeColor: Colors.green,
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
                        onPressed: isSaving ? null : _saveAttendance,
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