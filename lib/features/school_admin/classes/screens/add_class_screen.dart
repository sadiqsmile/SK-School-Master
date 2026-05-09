import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Map<String, List<String>> classGroups = {
  "Primary Section": [
    "Class 1",
    "Class 2",
    "Class 3",
    "Class 4",
    "Class 5",
  ],
  "Middle Section": [
    "Class 6",
    "Class 7",
    "Class 8",
  ],
  "High School": [
    "Class 9",
    "Class 10",
  ],
  "PU College": [
    "1st PUC",
    "2nd PUC",
  ],
};

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  String? selectedClass;
  String? selectedGroup;
  List<String> sections = [];
  final sectionController = TextEditingController();
  bool isSaving = false;

  Future<String> getSchoolId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc['schoolId'];
  }

  @override
  void initState() {
    super.initState();
    _cleanupDuplicateClasses();
  }

  Future<void> _cleanupDuplicateClasses() async {
    final schoolId = await getSchoolId();
    final classRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes');

    final snapshot = await classRef.get();
    final docs = snapshot.docs;

    final Map<String, QueryDocumentSnapshot> uniqueClasses = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final className = data['name'];

      if (className == null) continue;

      if (!uniqueClasses.containsKey(className)) {
        uniqueClasses[className] = doc;
      } else {
        // ✅ DUPLICATE FOUND — merge sections
        final existingDoc = uniqueClasses[className]!;
        final existingData = existingDoc.data() as Map<String, dynamic>;

        final existingSections = List<String>.from(existingData['sections'] ?? []);
        final newSections = List<String>.from(data['sections'] ?? []);
        final mergedSections = [...existingSections, ...newSections].toSet().toList();

        await existingDoc.reference.update({"sections": mergedSections});
        await doc.reference.delete();
      }
    }
  }
  Future<void> _saveClass() async {
    if (selectedClass == null || selectedGroup == null || sections.isEmpty) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final schoolId = await getSchoolId();

      final classRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes');

      final existingClass = await classRef
          .where('name', isEqualTo: selectedClass)
          .limit(1)
          .get();

      if (existingClass.docs.isNotEmpty) {
        // ✅ MERGE EXISTING
        final doc = existingClass.docs.first;
        final data = doc.data();
        final existingSections = List<String>.from(data['sections'] ?? []);
        final mergedSections = [
          ...existingSections,
          ...sections,
        ].toSet().toList();

        await doc.reference.update({
          "sections": mergedSections,
          "group": selectedGroup,
        });
      } else {
        // ✅ CREATE NEW
        await classRef.add({
          "name": selectedClass,
          "group": selectedGroup,
          "sections": sections,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Add Class"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Group dropdown ──────────────────────────────
            DropdownButtonFormField<String>(
              value: selectedGroup,
              decoration: _inputDecoration("Group"),
              items: classGroups.keys.map((group) {
                return DropdownMenuItem(value: group, child: Text(group));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedGroup = v;
                  selectedClass = null;
                });
              },
            ),

            const SizedBox(height: 18),

            // ── Class dropdown (depends on group) ───────────
            if (selectedGroup != null)
              DropdownButtonFormField<String>(
                value: selectedClass,
                decoration: _inputDecoration("Class"),
                items: classGroups[selectedGroup]!.map((cls) {
                  return DropdownMenuItem(value: cls, child: Text(cls));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedClass = v;
                  });
                },
              ),

            const SizedBox(height: 18),

            // ── Section chips ───────────────────────────────
            if (sections.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: sections.map((section) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          section,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff5B5FEF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              sections.remove(section);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xff5B5FEF),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],

            // ── Add section row ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sectionController,
                    decoration: _inputDecoration("Add Section"),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (sectionController.text.trim().isEmpty) return;
                    setState(() {
                      sections.add(sectionController.text.trim());
                      sectionController.clear();
                    });
                  },
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xff5B5FEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Save button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5B5FEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: isSaving ? null : _saveClass,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Class",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff5B5FEF)),
      ),
    );
  }
}
