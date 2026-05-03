// features/school_admin/students/screens/edit_student_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';

class EditStudentScreen extends ConsumerStatefulWidget {
  final String studentId;
  final Map<String, dynamic> data;

  const EditStudentScreen({
    super.key,
    required this.studentId,
    required this.data,
  });

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController parentNameController;
  late TextEditingController parentPhoneController;

  late bool isHostel;
  late bool isMess;
  late bool isBus;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.data['name'] ?? '');
    parentNameController =
        TextEditingController(text: widget.data['parentName'] ?? '');
    parentPhoneController =
        TextEditingController(text: widget.data['parentPhone'] ?? '');

    final hostelVal = (widget.data['type'] ?? widget.data['residence'] ?? '')
        .toString().trim().toLowerCase();
    isHostel = hostelVal == 'hostel' || hostelVal == 'h';

    final messVal = (widget.data['mess'] ?? '').toString().trim().toLowerCase();
    isMess = messVal == 'yes' || messVal == 'y' || messVal == '1' || messVal == 'true';

    final transVal = (widget.data['transport'] ?? '').toString().trim().toLowerCase();
    isBus = transVal == 'yes' || transVal == 'y' || transVal == '1' || transVal == 'true';

    // Enforce rule on load: if hostel, mess must be true and bus false
    if (isHostel) {
      isMess = true;
      isBus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Parent Name',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: parentPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Parent Phone',
                ),
                keyboardType: TextInputType.phone,
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
              ElevatedButton(
                onPressed: _updateStudent,
                child: const Text('Update Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final school = await ref.read(currentSchoolProvider.future);

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(school.id)
          .collection('students')
          .doc(widget.studentId)
          .update({
        'name': nameController.text.trim(),
        'parentName': parentNameController.text.trim(),
        'parentPhone': parentPhoneController.text.trim(),
        'type': isHostel ? 'hostel' : 'day',
        'mess': (isHostel ? true : isMess) ? 'yes' : 'no',
        'transport': (isHostel ? false : isBus) ? 'yes' : 'no',
      });

      if (!context.mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
