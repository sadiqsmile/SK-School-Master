import 'package:flutter/material.dart';

class StudentImportScreen extends StatelessWidget {
  final String schoolId;

  const StudentImportScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Students')),
      body: const Center(
        child: Text('Import Students Screen'),
      ),
    );
  }
}

