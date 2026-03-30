// features/school_admin/students/screens/students_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/students/providers/students_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/parent_account_service.dart';
import 'package:school_app/services/student_service.dart'; // ✅ IMPORTANT

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  // 🔹 RESET PARENT PASSWORD
  Future<void> _resetParentPassword(
    BuildContext context,
    WidgetRef ref, {
    required String parentName,
    required String parentPhone,
    required String studentId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset parent password?'),
        content: const Text('This will generate a new PIN for the parent.'),
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

      final result = await ParentAccountService().resetParentPassword(
        schoolId: school.id,
        phone: parentPhone,
        parentName: parentName,
        studentId: studentId,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.initialPin == null
                ? 'Parent PIN reset'
                : 'New PIN: ${result.initialPin}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
              final className = (data['className'] ?? '').toString();
              final section =
                  (data['sectionName'] ?? data['section'] ?? '').toString();
              final academicYear =
                  (data['academicYear'] ?? '').toString();
              final status = (data['status'] ?? '').toString();

              final parentName =
                  (data['parentName'] ?? '').toString();
              final parentPhone =
                  (data['parentPhone'] ?? '').toString();

              return ListTile(
                title: Text(name.isEmpty ? 'Student' : name),
                subtitle: Text(
                  '${className.isEmpty ? 'Class N/A' : className}'
                  '${section.isEmpty ? '' : ' - Section $section'}'
                  '${academicYear.isEmpty ? '' : '  •  $academicYear'}'
                  '${status.toLowerCase() == 'graduated' ? '  •  Graduated' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (parentPhone.trim().isNotEmpty)
                      PopupMenuButton<String>(
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

                  
                  
                   IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () {
    _confirmDelete(context, ref, docId); // ✅ NEW
  },
),





                  ],
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-student'),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🔴 DELETE FUNCTION
 void _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String studentId,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // 🔥 GET SCHOOL ID
                final school = await ref.read(currentSchoolProvider.future);

                // ✅ CORRECT DELETE PATH
                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(school.id)
                    .collection('students')
                    .doc(studentId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}
} 