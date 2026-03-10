import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/utils/school_storage.dart';

class EnterSchoolScreen extends StatefulWidget {
  const EnterSchoolScreen({super.key});

  @override
  State<EnterSchoolScreen> createState() => _EnterSchoolScreenState();
}

class _EnterSchoolScreenState extends State<EnterSchoolScreen> {
  final controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> saveSchool() async {
    final schoolId = controller.text.trim();

    setState(() {
      _error = null;
    });

    if (schoolId.isEmpty) {
      setState(() {
        _error = 'Please enter your School ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Optional safety: validate school exists.
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .get();

      if (!schoolDoc.exists) {
        setState(() {
          _error = 'Invalid School ID. Please check and try again.';
          _isLoading = false;
        });
        return;
      }

      await SchoolStorage.saveSchoolId(schoolId);

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() {
        _error = 'Failed to save School ID. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter School ID')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'School ID',
                errorText: _error,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => saveSchool(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : saveSchool,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Your School Admin can provide the School ID.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
