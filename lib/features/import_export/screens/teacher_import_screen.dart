import 'package:flutter/material.dart';

class TeacherImportScreen extends StatelessWidget {
  final String schoolId;

  const TeacherImportScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Teachers')),
      body: const Center(
        child: Text('Import Teachers Screen'),
      ),
    );
  }
}