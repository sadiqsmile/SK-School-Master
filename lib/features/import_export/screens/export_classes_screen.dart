import 'package:flutter/material.dart';

class ExportClassesScreen extends StatelessWidget {
  final String schoolId;

  const ExportClassesScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Classes')),
      body: const Center(
        child: Text('Export Classes Screen'),
      ),
    );
  }
}