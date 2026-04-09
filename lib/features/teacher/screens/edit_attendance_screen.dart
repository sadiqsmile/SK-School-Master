import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String docId;
  final String className;
  final String section;
  final String schoolId;

  const EditAttendanceScreen({
    super.key,
    required this.docId,
    required this.className,
    required this.section,
    required this.schoolId,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  Map<String, bool> attendance = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(widget.docId)
        .get();

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      attendance = Map<String, bool>.from(data['students']);
      loading = false;
    });
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(widget.docId)
        .update({
      'students': attendance,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated ✅")),
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
      appBar: AppBar(title: const Text("Edit Attendance")),
      body: ListView(
        children: attendance.keys.map((id) {
          return ListTile(
            title: Text(id),
            trailing: Switch(
              value: attendance[id]!,
              onChanged: (val) {
                setState(() {
                  attendance[id] = val;
                });
              },
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String docId;
  final String className;
  final String section;

  const EditAttendanceScreen({
    super.key,
    required this.docId,
    required this.className,
    required this.section,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  Map<String, bool> attendance = {};

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final doc = await FirebaseFirestore.instance
        .collectionGroup('attendance')
        .get();

    final data = doc.docs
        .firstWhere((d) => d.id == widget.docId)
        .data();

    setState(() {
      attendance = Map<String, bool>.from(data['students']);
    });
  }

  Future<void> _save() async {
    // Find the correct attendance doc and update it
    final query = await FirebaseFirestore.instance
        .collectionGroup('attendance')
        .where(FieldPath.documentId, isEqualTo: widget.docId)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'students': attendance,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Attendance")),
      body: ListView(
        children: attendance.keys.map((id) {
          return ListTile(
            title: Text(id),
            trailing: Switch(
              value: attendance[id]!,
              onChanged: (val) {
                setState(() {
                  attendance[id] = val;
                });
              },
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
    );
  }
}
