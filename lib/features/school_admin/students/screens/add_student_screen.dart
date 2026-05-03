// features/school_admin/students/screens/add_student_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/students/services/student_service.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/core/utils/text_formatters.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final nameController = TextEditingController();
  final admissionController = TextEditingController();
  final parentNameController = TextEditingController();
  final parentPhoneController = TextEditingController();

  String? selectedClassId;
  String? selectedClassName;
  List<String> sections = [];
  String? selectedSection;

  bool isHostel = false;
  bool isMess = false;
  bool isBus = false;

  bool _isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    admissionController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = nameController.text.trim().toUpperCase();
    final admissionNo = admissionController.text.trim().toUpperCase();
    final parentName = parentNameController.text.trim().toUpperCase();
    final parentPhone = parentPhoneController.text.trim();

    if (name.isEmpty || admissionNo.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter student name and admission no')),
      );
      return;
    }

    if (selectedClassId == null ||
        selectedClassName == null ||
        selectedSection == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select class and section')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final school = await ref.read(currentSchoolProvider.future);

      await StudentService().addStudent(
        schoolId: school.id,
        data: {
          'name': name,
          'admissionNo': admissionNo,
          'classId': selectedClassId,
          'className': selectedClassName!.trim(),
          'section': selectedSection!.trim(),
          'classKey': "${selectedClassName!.trim()}_${selectedSection!.trim()}",
          if (parentName.isNotEmpty) 'parentName': parentName,
          if (parentPhone.isNotEmpty) 'parentPhone': parentPhone,
          'type': isHostel ? 'hostel' : 'day',
          'mess': (isHostel ? true : isMess) ? 'yes' : 'no',
          'transport': (isHostel ? false : isBus) ? 'yes' : 'no',
        },
      );

      messenger.showSnackBar(
        SnackBar(content: Text('Student "$name" added')),
      );

      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: schoolAsync.when(
        data: (school) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  inputFormatters: const [UpperCaseTextFormatter()],
                  decoration:
                      const InputDecoration(labelText: 'Student Name'),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: admissionController,
                  decoration:
                      const InputDecoration(labelText: 'Admission No'),
                ),
                const SizedBox(height: 10),

                /// ✅ CLASS DROPDOWN (FIXED)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(school.id)
                      .collection('classes')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }

                    final docs = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedClassId,
                      hint: const Text("Select Class"),
                      decoration:
                          const InputDecoration(labelText: 'Class'),
                      items: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selectedDoc =
                            docs.firstWhere((doc) => doc.id == value);
                        final data =
                            selectedDoc.data() as Map<String, dynamic>;

                        setState(() {
                          selectedClassId = value;
                          selectedClassName = data['name'];
                          sections =
                              List<String>.from(data['sections'] ?? []);
                          selectedSection = null;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),

                /// ✅ SECTION DROPDOWN
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  hint: const Text("Select Section"),
                  decoration:
                      const InputDecoration(labelText: 'Section'),
                  items: sections
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedSection = value);
                  },
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: parentNameController,
                  inputFormatters: const [UpperCaseTextFormatter()],
                  decoration:
                      const InputDecoration(labelText: 'Parent Name'),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: parentPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Parent Phone'),
                ),

                const SizedBox(height: 16),

                // ── Hostel / Mess / Bus ──────────────────────────────
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Hostel'),
                          value: isHostel,
                          onChanged: (v) {
                            setState(() {
                              isHostel = v!;
                              if (isHostel) {
                                isMess = true;
                                isBus = false;
                              }
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Mess'),
                          value: isMess,
                          onChanged: isHostel
                              ? null
                              : (v) => setState(() => isMess = v!),
                        ),
                        CheckboxListTile(
                          title: const Text('Bus / Transport'),
                          value: isBus,
                          onChanged: isHostel
                              ? null
                              : (v) => setState(() => isBus = v!),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Student'),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}