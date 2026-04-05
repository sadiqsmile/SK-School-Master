import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


Stream<QuerySnapshot> getClasses(String schoolId) {
  return FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .snapshots();
}


class AssignTeacherScreen extends StatefulWidget {
  final String teacherId;

  const AssignTeacherScreen({super.key, required this.teacherId});

  @override
  State<AssignTeacherScreen> createState() =>
      _AssignTeacherScreenState();
}

class _AssignTeacherScreenState
    extends State<AssignTeacherScreen> {
  String? selectedClassId;
  String? selectedClassName;
  List<String> sections = [];
  String? selectedSection;

  bool isSaving = false;

  Future<String> getSchoolId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc['schoolId'];
  }

  Future<void> assign() async {
    if (selectedClassId == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select class & section")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final schoolId = await getSchoolId();
      final className = selectedClassName;
      final classKey = "${className}_${selectedSection}";
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .update({
        "assignmentKeys": FieldValue.arrayUnion([classKey])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assigned Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getSchoolId(),
      builder: (context, schoolSnap) {
        if (!schoolSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final schoolId = schoolSnap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text("Assign Class")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: getClasses(schoolId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final docs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedClassId,
                      hint: const Text("Select Class"),
                      items: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selectedDoc = docs.firstWhere((doc) => doc.id == value);
                        final data = selectedDoc.data() as Map<String, dynamic>;
                        setState(() {
                          selectedClassId = value;
                          selectedClassName = data['name'];
                          sections = List<String>.from(data['sections']);
                          selectedSection = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  hint: const Text("Select Section"),
                  items: sections
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedSection = value);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : assign,
                    child: Text(isSaving ? "Assigning..." : "Assign"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}