import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/subject_import_service.dart';

class ImportSubjectScreen extends StatefulWidget {
  final String schoolId;

  const ImportSubjectScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<ImportSubjectScreen> createState() => _ImportSubjectScreenState();
}

class _ImportSubjectScreenState extends State<ImportSubjectScreen> {
  List<Map<String, dynamic>> subjects = [];
  bool loading = false;
  int importedCount = 0;
  List<String> duplicates = [];
  List<String> invalidRows = [];

  Future<void> pickExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    final Uint8List bytes = result.files.first.bytes!;

    setState(() {
      loading = true;
    });

    subjects = await SubjectImportService().parseExcel(bytes);

    setState(() {
      loading = false;
    });
  }

  Future<void> saveSubjects() async {
    setState(() {
      loading = true;
      importedCount = 0;
      duplicates = [];
      invalidRows = [];
    });

    final subjectRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('subjects');

    for (final subject in subjects) {
      final name = subject['name'].toString().trim();
      final code = subject['code'].toString().trim();
      final groups = List<String>.from(subject['groups'] ?? []);

      // Validation
      if (name.isEmpty || code.isEmpty) {
        invalidRows.add(name.isEmpty ? code : name);
        continue;
      }

      // Duplicate check
      final existing =
          await subjectRef.where('code', isEqualTo: code).limit(1).get();

      if (existing.docs.isNotEmpty) {
        duplicates.add(name);
        continue;
      }

      // Save
      await subjectRef.add({
        "name": name,
        "code": code,
        "groups": groups,
        "createdAt": FieldValue.serverTimestamp(),
      });

      importedCount++;
    }

    setState(() {
      loading = false;
    });

    _showResultDialog();
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Import Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imported: $importedCount',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (duplicates.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duplicates:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  ...duplicates.map((e) => Text('• $e')),
                ],
              ),
            const SizedBox(height: 12),
            if (invalidRows.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invalid Rows:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  ...invalidRows.map((e) => Text('• $e')),
                ],
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Subjects'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pickExcel,
        label: const Text('Pick Excel'),
        icon: const Icon(Icons.upload_file),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(subject['name']),
                  subtitle: Text(subject['code']),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: subjects.isEmpty || loading ? null : saveSubjects,
            icon: const Icon(Icons.save),
            label: const Text('Import Subjects'),
          ),
        ),
      ),
    );
  }
}
