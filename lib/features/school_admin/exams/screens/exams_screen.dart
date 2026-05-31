import 'package:flutter/material.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import '../widgets/create_exam_dialog_v2.dart';
import 'exam_settings_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Exams',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [



Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [

    ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ExamSettingsScreen(),
          ),
        );
      },
      icon: const Icon(Icons.settings),
      label: const Text('Settings'),
    ),

    const SizedBox(width: 12),

    ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) {
            return const CreateExamDialogV2();
          },
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Create Exam'),
    ),
  ],
),

          const SizedBox(height: 16),

          const Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.description),
              ),
              title: Text('No Exams Created Yet'),
              subtitle: Text(
                'Click Create Exam to get started',
              ),
            ),
          ),
        ],
      ),
    );
  }
}