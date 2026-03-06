// features/school_admin/layout/admin_layout.dart
import 'package:flutter/material.dart';

import 'sidebar.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    required this.body,
    this.title = 'School Admin Dashboard',
    this.actions,
  });

  final Widget body;
  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: actions,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
      ),
      drawer: const Sidebar(),
      body: body,
    );
  }
}
