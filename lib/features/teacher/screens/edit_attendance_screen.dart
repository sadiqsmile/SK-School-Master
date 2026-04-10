import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;
  final String date;

  const EditAttendanceScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.date,
  });

  @override
  State<EditAttendanceScreen> createState() =>
      _EditAttendanceScreenState();
}

class _EditAttendanceScreenState
    extends State<EditAttendanceScreen> {

  Map<String, String?> attendance = {};
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 🔥 LOAD STUDENTS + ATTENDANCE
  Future<void> _loadData() async {

    /// students
    final studentSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .get();

    students = studentSnap.docs.map((e) {
      return {
        'id': e.id,
        'name': e['name'],
      };
    }).toList();

    /// attendance
    final attSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .where('date', isEqualTo: widget.date)
        .get();

    if (attSnap.docs.isNotEmpty) {
      final data = attSnap.docs.first.data();
      final saved =
          Map<String, dynamic>.from(data['students'] ?? {});

      saved.forEach((key, value) {
        if (value == true) {
          attendance[key] = 'P';
        } else if (value == false) {
          attendance[key] = 'A';
        } else {
          attendance[key] = value;
        }
      });
    }

    // Ensure all students have an entry in attendance
    students.forEach((s) {
      attendance.putIfAbsent(s['id'], () => null);
    });

    setState(() => isLoading = false);
  }

  /// 🔥 SAVE UPDATED
  Future<void> _updateAttendance() async {

    final docId =
        "${widget.className}_${widget.section}_${widget.date}";

    Map<String, String?> finalAttendance = {};
    for (var s in students) {
      final id = s['id'];
      finalAttendance[id] = attendance[id] ?? 'A';
    }

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(docId)
        .set({
      'className': widget.className,
      'section': widget.section,
      'date': widget.date,
      'students': finalAttendance,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated Successfully ✅")),
    );

    Navigator.pop(context, true);
  }

  /// 🔥 TOGGLE
  void _toggle(String id) {
    final current = attendance[id];

    setState(() {
      if (current == null) {
        attendance[id] = 'P';
      } else if (current == 'P') {
        attendance[id] = 'A';
      } else {
        attendance[id] = null;
      }
    });
  }

  Widget _switch(String? status) {
    final isPresent = status == 'P';

    return Container(
      width: 70,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: status == null
              ? [Colors.grey, Colors.grey]
              : isPresent
                  ? [Colors.green, Colors.greenAccent]
                  : [Colors.red, Colors.redAccent],
        ),
      ),
      alignment:
          isPresent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit ${widget.date}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, i) {
                      final s = students[i];

                      return ListTile(
                        title: Text(s['name']),
                        trailing: GestureDetector(
                          onTap: () => _toggle(s['id']),
                          child: _switch(attendance[s['id']]),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: _updateAttendance,
                    child: const Text("Update Attendance"),
                  ),
                )
              ],
            ),
    );
  }
}