import 'package:flutter/material.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class GradeTemplatesScreen extends StatelessWidget {
  const GradeTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Grade Templates',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.grade),
              ),
              title: const Text(
                'No Grade Templates Yet',
              ),
              subtitle: const Text(
                'Create your first grading template',
              ),
              trailing: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ),
          ),

        ],
      ),
    );
  }
}