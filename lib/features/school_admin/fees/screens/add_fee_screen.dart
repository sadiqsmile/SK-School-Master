import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';

class AddFeeScreen extends ConsumerStatefulWidget {
  final String studentId;

  const AddFeeScreen({super.key, required this.studentId});

  @override
  ConsumerState<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends ConsumerState<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Fee')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (v) =>
                    v!.isEmpty ? 'Enter amount' : null,
              ),

              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveFee,
                child: const Text('Save Fee'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFee() async {
    if (!_formKey.currentState!.validate()) return;

    final school = await ref.read(currentSchoolProvider.future);

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id)
        .collection('students')
        .doc(widget.studentId)
        .collection('fees')
        .add({
      'amount': double.parse(amountController.text),
      'description': descriptionController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'unpaid',
    });

    if (context.mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fee added successfully')),
      );
    }
  }
}
