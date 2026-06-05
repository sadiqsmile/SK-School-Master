import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup Data'),
          ),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('Restore Data'),
          ),
          ListTile(
            leading: Icon(Icons.build),
            title: Text('Fix Student Data'),
          ),
        ],
      ),
    );
  }
}