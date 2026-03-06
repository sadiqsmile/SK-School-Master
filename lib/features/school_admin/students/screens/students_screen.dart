// features/school_admin/students/screens/students_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

import 'package:school_app/features/school_admin/students/providers/students_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/parent_account_service.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  Future<void> _resetParentPassword(
    BuildContext context,
    WidgetRef ref, {
    required String parentName,
    required String parentPhone,
    required String studentId,
  }) async {
    final phoneDigits = ParentAccountService().normalizePhone(parentPhone);
    final defaultPassword = ParentAccountService().last4OfPhone(phoneDigits);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset parent password?'),
        content: Text(
          'Reset password to last 4 digits ($defaultPassword) and force change on next login?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final school = await ref.read(currentSchoolProvider.future);
      await ParentAccountService().resetParentPassword(
        schoolId: school.id,
        phone: parentPhone,
        parentName: parentName,
        studentId: studentId,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Parent password reset. Default password: $defaultPassword',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset password: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return AdminLayout(
      title: 'Students',
      body: studentsAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text('No students added'));
          }

          return ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, i) {
              final data = snapshot.docs[i].data();
              final docId = snapshot.docs[i].id;
              final name = (data['name'] ?? '').toString();
              final classId = (data['classId'] ?? '').toString();
              final section = (data['section'] ?? '').toString();
              final parentName = (data['parentName'] ?? '').toString();
              final parentPhone = (data['parentPhone'] ?? '').toString();

              return ListTile(
                title: Text(name.isEmpty ? 'Student' : name),
                subtitle: Text(
                  '${classId.isEmpty ? 'Class N/A' : classId}${section.isEmpty ? '' : ' - Section $section'}',
                ),
                trailing: parentPhone.trim().isEmpty
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'reset_parent') {
                            _resetParentPassword(
                              context,
                              ref,
                              parentName: parentName,
                              parentPhone: parentPhone,
                              studentId: docId,
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'reset_parent',
                            child: Text('Reset Parent Password'),
                          ),
                        ],
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-student'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
