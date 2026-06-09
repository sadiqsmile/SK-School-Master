import 'package:flutter/material.dart';

class ImportClassesScreen extends StatelessWidget {
  final String schoolId;

  const ImportClassesScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Classes')),
      body: const Center(
        child: Text('Import Classes Screen'),
      ),
    );
  }
}