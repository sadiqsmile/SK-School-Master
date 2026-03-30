// features/school_admin/students/screens/students_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/students/providers/students_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/parent_account_service.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

// ✅ FIX: CLOSED CLASS HERE
class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String searchQuery = '';
  String selectedClass = 'All';
  String selectedSection = 'All';

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
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return AdminLayout(
      title: 'Students',
      body: studentsAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text('No students added'));
          }

          final filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data();

            final name = (data['name'] ?? '').toString().toLowerCase();
            final className = (data['className'] ?? '').toString();
            final section = (data['sectionName'] ?? data['section'] ?? '').toString();

            final matchesSearch =
                name.contains(searchQuery.toLowerCase());

            final matchesClass =
                selectedClass == 'All' || className == selectedClass;

            final matchesSection =
                selectedSection == 'All' || section == selectedSection;

            return matchesSearch && matchesClass && matchesSection;
          }).toList();

          return Column(
            children: [
              // 🏷️ CLASS & SECTION FILTERS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    // CLASS FILTER
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedClass,
                        items: ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('Class $e'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedClass = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // SECTION FILTER
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSection,
                        items: ['All', 'A', 'B', 'C', 'D']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('Section $e'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSection = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search student...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),

              // 📋 LIST
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, i) {
                    final data = filteredDocs[i].data();
                    final docId = filteredDocs[i].id;

                    final name = (data['name'] ?? '').toString();
                    final className = (data['className'] ?? '').toString();
                    final section =
                        (data['sectionName'] ?? data['section'] ?? '').toString();

                    final parentName =
                        (data['parentName'] ?? '').toString();
                    final parentPhone =
                        (data['parentPhone'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // 👤 Avatar
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 20, color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 📄 Student Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$className - Section $section',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 4),
                                  if (parentName.isNotEmpty)
                                    Text(
                                      'Parent: $parentName',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            // 🎯 ACTIONS
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.payment, color: Colors.green),
                                  onPressed: () {
                                    context.push('/fees', extra: docId);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    context.push('/edit-student', extra: {
                                      'studentId': docId,
                                      'data': data,
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(context, ref, docId);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
          content:
              const Text('Are you sure you want to delete this student?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final school =
                      await ref.read(currentSchoolProvider.future);

                  await FirebaseFirestore.instance
                      .collection('schools')
                      .doc(school.id)
                      .collection('students')
                      .doc(studentId)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Student deleted successfully')),
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