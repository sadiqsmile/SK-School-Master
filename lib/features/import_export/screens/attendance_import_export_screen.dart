import 'package:flutter/material.dart';

class AttendanceImportExportScreen extends StatelessWidget {
  const AttendanceImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const Center(
        child: Text('Attendance Import Export Screen'),
      ),
    );
  }
}