import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/core/widgets/app_button.dart';
import 'package:school_app/services/firestore_service.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _schoolName = TextEditingController(text: 'Test School 2');
  final _adminEmail = TextEditingController(text: 'testadmin2@school.com');
  final _adminPassword = TextEditingController(text: '12345678');
  bool _saving = false;

  @override
  void dispose() {
    _schoolName.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await FirestoreService(FirebaseFirestore.instance).createSchoolWithAdmin(
        schoolName: _schoolName.text.trim(),
        adminEmail: _adminEmail.text.trim(),
        adminPassword: _adminPassword.text.trim(),
        themeColor: '#1976D2',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating school: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _schoolName,
            decoration: const InputDecoration(labelText: 'School Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminEmail,
            decoration: const InputDecoration(labelText: 'Admin Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Admin Password'),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Create School', onPressed: _submit, isLoading: _saving),
        ],
      ),
    );
  }
}
