import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherClassHomeScreen extends StatelessWidget {
  const TeacherClassHomeScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

  String get _label {
    final c = classId.trim();
    final s = sectionId.trim();
    if (c.isEmpty && s.isEmpty) return 'Class';
    if (s.isEmpty) return 'Class $c';
    return 'Class $c$s';
  }

  @override
  Widget build(BuildContext context) {
    final encodedClass = Uri.encodeComponent(classId);
    final encodedSection = Uri.encodeComponent(sectionId);

    return Scaffold(
      appBar: AppBar(title: Text(_label)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: const Text('Students List'),
              subtitle: const Text('View students in this class/section'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/teacher/class/$encodedClass/$encodedSection/students',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_rounded),
              title: const Text('Mark Attendance'),
              subtitle: const Text("Mark today's attendance"),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/teacher/attendance/$encodedClass/$encodedSection',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Add Homework'),
              subtitle: const Text('Create and view homework for this class'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/teacher/homework/$encodedClass/$encodedSection',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.grading_rounded),
              title: const Text('Enter Marks'),
              subtitle: const Text('Coming next'),
              trailing: const Icon(Icons.lock_clock_rounded),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exams module: coming next')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: const Text('Class Risk List'),
              subtitle: const Text('See students who need attention early'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/teacher/risk/$encodedClass/$encodedSection',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
