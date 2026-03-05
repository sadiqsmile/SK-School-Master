import 'package:flutter/material.dart';

class SchoolAdminDashboard extends StatelessWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("School Admin Dashboard"),
      ),
      body: const Center(
        child: Text(
          "Welcome School Admin",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}