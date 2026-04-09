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
  bool loading = true;
  String schoolId = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    schoolId = userDoc['schoolId'];

    await _loadExistingAttendance();

    setState(() {
      loading = false;
    });
  }

  Future<void> _loadExistingAttendance() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final docId =
        "${widget.className}_${widget.section}_$today";

    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(docId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      attendance = Map<String, bool>.from(data['students']);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);

    final today = DateTime.now().toIso8601String().split('T')[0];

    final docId =
        "${widget.className}_${widget.section}_$today";

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

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Saved ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - ${widget.section}"),
      ),
      body: StreamBuilder<QuerySnapshot>(
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

                    // ✅ Default = ABSENT (false)
                    attendance.putIfAbsent(doc.id, () => false);

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
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("Save Attendance"),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}