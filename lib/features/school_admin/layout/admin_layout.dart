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
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: const Sidebar(),
      body: body,
    );
  }
}
