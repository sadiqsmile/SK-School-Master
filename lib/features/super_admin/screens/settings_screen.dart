import 'package:flutter/material.dart';
import 'archived_schools_screen.dart'; // ✅ IMPORTANT IMPORT

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [

          const ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
          ),

          const ListTile(
            leading: Icon(Icons.security),
            title: Text("Security"),
          ),

          const ListTile(
            leading: Icon(Icons.info),
            title: Text("About App"),
          ),

          /// 🔥 ARCHIVED SCHOOLS (FIXED)
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text("Archived Schools"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedSchoolsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}