// features/school_admin/students/screens/add_student_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart';
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/academic/providers/academic_years_provider.dart';
import 'package:school_app/features/school_admin/students/services/student_service.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/providers/school_modules_provider.dart';
import 'package:school_app/services/parent_account_service.dart';
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
    final parentService = ParentAccountService();
    final phoneDigits = parentService.normalizePhone(parentPhone);

    final modules = await ref.read(schoolModulesProvider.future);
    final parentsEnabled = modules.parents;

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
    if (parentsEnabled) {
      if (parentName.isEmpty || parentPhone.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter parent name and phone')),
        );
        return;
      }

      if (phoneDigits.length < 10) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a valid parent phone number')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final school = await ref.read(currentSchoolProvider.future);
      final academicYear = ref.read(currentAcademicYearIdProvider);

      final studentRef = await StudentService().addStudent(
        schoolId: school.id,
        data: {
          'name': name,
          'admissionNo': admissionNo,
          'classId': selectedClassId,
          'section': selectedSection,
          'academicYear': academicYear,
          if (parentName.isNotEmpty) 'parentName': parentName,
          if (parentPhone.isNotEmpty) 'parentPhone': parentPhone,
        },
      );

      // Create parent login (default password = last 4 digits) and link it.
      String? parentUid;
      String? initialPin;
      if (parentsEnabled && parentName.isNotEmpty && parentPhone.isNotEmpty) {
        try {
          final result = await parentService.createParentLogin(
            schoolId: school.id,
            phone: parentPhone,
            parentName: parentName,
            studentId: studentRef.id,
          );
          parentUid = result.uid;

          // Prefer server-generated PIN; fall back to legacy last-4 for older deployments.
          initialPin = result.initialPin ?? parentService.last4OfPhone(phoneDigits);
        } catch (e) {
          // Don't block student creation if functions aren't deployed yet.
          messenger.showSnackBar(
            SnackBar(content: Text('Student saved, but parent login failed: $e')),
          );
        }
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Student "$name" added')),
      );

      if (parentUid != null && initialPin != null && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Parent login created'),
              content: SelectableText(
                'Phone: $phoneDigits\n'
                'Initial PIN: $initialPin',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

      navigator.pop();
    } on DuplicateAdmissionNumberException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Admission number already exists. Check admission number.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to save student: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UpperCaseTextFormatter()],
              decoration: const InputDecoration(labelText: 'Student Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: admissionController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Admission No'),
            ),
            const SizedBox(height: 10),
            classesAsync.when(
              data: (snapshot) {
                final docs = snapshot.docs;
                return DropdownButtonFormField<String>(
                  key: ValueKey<String?>('class_$selectedClassId'),
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [
                    for (final doc in docs)
                      DropdownMenuItem(
                        value: doc.id,
                        child: Text((doc.data()['name'] ?? doc.id).toString()),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            selectedClassId = value;
                            // reset section when class changes
                            selectedSection = null;
                          });
                        },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load classes: $e'),
            ),
            const SizedBox(height: 10),
            if (selectedClassId == null)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select a class to pick a section'),
              )
            else
              ref.watch(sectionsProvider(selectedClassId!)).when(
                data: (snapshot) {
                  final docs = snapshot.docs;
                  return DropdownButtonFormField<String>(
                    key: ValueKey<String?>('section_$selectedClassId:$selectedSection'),
                    initialValue: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: [
                      for (final doc in docs)
                        DropdownMenuItem(
                          value: doc.id,
                          child: Text((doc.data()['name'] ?? doc.id).toString()),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => selectedSection = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load sections: $e'),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: parentNameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UpperCaseTextFormatter()],
              decoration: const InputDecoration(labelText: 'Parent Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: parentPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              ],
              decoration: const InputDecoration(labelText: 'Parent Phone'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Student'),
            ),
          ],
        ),
      ),
    );
  }
}
