import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  String? selectedClass;

  String selectedGroup = "Primary";
  List<String> sections = [];
  final sectionController = TextEditingController();

  bool isSaving = false;

  Future<String> getSchoolId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc['schoolId'];
  }



  Future<void> saveClass() async {
    final name = selectedClass;
    if (selectedClass == null || selectedGroup == null || sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter class, group & at least 1 section")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final schoolId = await getSchoolId();

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .add({
        "name": name,
        "group": selectedGroup,
        "sections": sections,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Class Added Successfully")),
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
  void dispose() {
    sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Class")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 📚 CLASS NAME (Dropdown)
            DropdownButtonFormField<String>(
              value: selectedClass,
              hint: const Text("Select Class"),
              items: [
                "LKG",
                "UKG",
                "Class 1",
                "Class 2",
                "Class 3",
                "Class 4",
                "Class 5",
                "Class 6",
                "Class 7",
                "Class 8",
                "Class 9",
                "Class 10",
                "I-PU",
                "II-PU",
              ]
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedClass = value);
              },
              decoration: const InputDecoration(labelText: "Class"),
            ),

            const SizedBox(height: 12),

            /// 🏫 GROUP
            DropdownButtonFormField<String>(
              value: selectedGroup,
              hint: const Text("Select Group"),
              items: const [
                DropdownMenuItem(value: "Primary", child: Text("Primary Section")),
                DropdownMenuItem(value: "Middle", child: Text("Middle Section")),
                DropdownMenuItem(value: "High School", child: Text("High School")),
                DropdownMenuItem(value: "College", child: Text("College")),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedGroup = v);
                }
              },
              decoration: const InputDecoration(labelText: "Group"),
            ),

            const SizedBox(height: 12),

            /// SECTION SELECTOR (Dialog)
            GestureDetector(
              onTap: () async {
                final result = await showDialog<List<String>>(
                  context: context,
                  builder: (context) {
                    List<String> tempSelected = List.from(sections);
                    return AlertDialog(
                      title: const Text("Select Sections"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ["A", "B", "C", "D"].map((section) {
                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
                              return CheckboxListTile(
                                value: tempSelected.contains(section),
                                title: Text("Section $section"),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    if (val == true) {
                                      tempSelected.add(section);
                                    } else {
                                      tempSelected.remove(section);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, tempSelected),
                          child: const Text("Done"),
                        ),
                      ],
                    );
                  },
                );
                if (result != null) {
                  setState(() => sections = result);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Section",
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  sections.isEmpty ? "Select Section" : sections.join(", "),
                  style: TextStyle(
                    color: sections.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),

            const Spacer(),

            /// 💾 SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveClass,
                child: Text(isSaving ? "Saving..." : "Save Class"),
              ),
            )
          ],
        ),
      ),
    );
  }
}