import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignSubjectScreen extends StatefulWidget {

  final String schoolId;
  final String teacherId;

  const AssignSubjectScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
  });

  @override
  State<AssignSubjectScreen> createState() =>
      _AssignSubjectScreenState();
}

class _AssignSubjectScreenState
    extends State<AssignSubjectScreen> {

  String? selectedClass;
  String? selectedSection;
  String? selectedSubject;

  bool isSaving = false;

  final List<String> subjects = [
    "Mathematics",
    "Science",
    "Physics",
    "Chemistry",
    "Biology",
    "English",
    "Social",
    "Computer",
    "Kannada",
    "Hindi",
  ];

  Future<void> _save() async {

    if (selectedClass == null ||
        selectedSection == null ||
        selectedSubject == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select all fields"),
        ),
      );

      return;
    }

    setState(() => isSaving = true);

    try {

      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId);

      final doc = await docRef.get();

      final data =
          doc.data() as Map<String, dynamic>;

      final current =
          List<Map<String, dynamic>>.from(
        data['subjectAssignments'] ?? [],
      );

      final alreadyExists = current.any((e) {

        return e['classId'] == selectedClass &&
            e['sectionId'] == selectedSection &&
            e['subject'] == selectedSubject;

      });

      if (alreadyExists) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Assignment already exists",
            ),
          ),
        );

        setState(() => isSaving = false);

        return;
      }

      current.add({

        "classId": selectedClass,
        "sectionId": selectedSection,
        "subject": selectedSubject,
      });

      await docRef.update({

        "subjectAssignments": current,

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Subject Assigned Successfully ✅",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Subject"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 500),

            child: Column(
              children: [

                DropdownButtonFormField<String>(
                  value: selectedClass,

                  decoration: InputDecoration(
                    labelText: "Class",

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  items: List.generate(12, (i) {

                    final c = (i + 1).toString();

                    return DropdownMenuItem(
                      value: c,
                      child: Text("Class $c"),
                    );

                  }),

                  onChanged: (v) {
                    setState(() => selectedClass = v);
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  value: selectedSection,

                  decoration: InputDecoration(
                    labelText: "Section",

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  items: ["A", "B", "C", "D"]
                      .map((e) {

                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );

                  }).toList(),

                  onChanged: (v) {
                    setState(() => selectedSection = v);
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  value: selectedSubject,

                  decoration: InputDecoration(
                    labelText: "Subject",

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  items: subjects.map((e) {

                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );

                  }).toList(),

                  onChanged: (v) {
                    setState(() => selectedSubject = v);
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed:
                        isSaving ? null : _save,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff5B5FEF),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child:
                        isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Assign Subject",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
