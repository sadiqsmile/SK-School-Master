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
  String? selectedSection;
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

    if (selectedClassId == null || selectedSection == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select class and section')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final school = await ref.read(currentSchoolProvider.future);

      /// ✅ GET CLASS NAME
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClassId)
          .get();

      final className = classDoc.data()?['name'] ?? '';

      /// ✅ GET SECTION NAME
      final sectionDoc = await FirebaseFirestore.instance
          .collection('sections')
          .doc(selectedSection)
          .get();

      final sectionName = sectionDoc.data()?['name'] ?? '';

      /// ✅ SAVE STUDENT
      await StudentService().addStudent(
        schoolId: school.id,
        data: {
          'name': name,
          'admissionNo': admissionNo,
          'classId': selectedClassId,
          'className': className,
          'section': selectedSection,
          'sectionName': sectionName,
          if (parentName.isNotEmpty) 'parentName': parentName,
          if (parentPhone.isNotEmpty) 'parentPhone': parentPhone,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              inputFormatters: const [UpperCaseTextFormatter()],
              decoration: const InputDecoration(labelText: 'Student Name'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: admissionController,
              decoration: const InputDecoration(labelText: 'Admission No'),
            ),
            const SizedBox(height: 10),

            /// CLASS
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedClassId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClassId = value;
                      selectedSection = null;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            /// SECTION
            if (selectedClassId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sections')
                    .where('classId', isEqualTo: selectedClassId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSection = value;
                      });
                    },
                  );
                },
              ),

            const SizedBox(height: 10),

            TextField(
              controller: parentNameController,
              inputFormatters: const [UpperCaseTextFormatter()],
              decoration: const InputDecoration(labelText: 'Parent Name'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: parentPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Parent Phone'),
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
      ),
    );
  }
}