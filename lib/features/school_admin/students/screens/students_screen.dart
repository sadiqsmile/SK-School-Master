import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String searchQuery = '';
  String selectedClassName = 'All';
  String selectedSection = 'All';

  List<String> availableSections = [];

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return AdminLayout(
      title: 'Students',
      body: schoolAsync.when(
        data: (school) {
          final schoolId = school.id;

          return Column(
            children: [
              /// 🔽 FILTERS
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    /// 📚 CLASS DROPDOWN
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('schools')
                            .doc(schoolId)
                            .collection('classes')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];

                          return DropdownButtonFormField<String>(
                            value: selectedClassName,
                            items: [
                              const DropdownMenuItem(
                                value: 'All',
                                child: Text('Class All'),
                              ),
                              ...docs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;

                                return DropdownMenuItem(
                                  value: data['name'],
                                  child: Text(data['name']),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              if (value == null) return;

                              if (value == 'All') {
                                setState(() {
                                  selectedClassName = 'All';
                                  availableSections = [];
                                  selectedSection = 'All';
                                });
                                return;
                              }

                              final selectedDoc = docs.firstWhere(
                                (doc) =>
                                    (doc.data()
                                            as Map<String, dynamic>)['name'] ==
                                    value,
                              );

                              final data = selectedDoc.data()
                                  as Map<String, dynamic>;

                              setState(() {
                                selectedClassName = value;
                                availableSections =
                                    List<String>.from(data['sections'] ?? []);
                                selectedSection = 'All';
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// 🅰️ SECTION DROPDOWN
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSection,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('Section All'),
                          ),
                          ...availableSections.map((s) =>
                              DropdownMenuItem(
                                value: s,
                                child: Text('Section $s'),
                              )),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedSection = value);
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

              /// 🔍 SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search student...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// 📋 STUDENT LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('students')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final allDocs = snapshot.data!.docs;

                    /// 🔥 FILTER LOGIC (FINAL SAFE)
                    final docs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final studentClass =
                          (data['className'] ?? '').toString().trim();
                      final studentSection =
                          (data['section'] ?? '').toString().trim();
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();

                      final classMatch = selectedClassName == 'All' ||
                          studentClass == selectedClassName;

                      final sectionMatch = selectedSection == 'All' ||
                          studentSection == selectedSection;

                      final searchMatch =
                          name.contains(searchQuery.toLowerCase());

                      return classMatch && sectionMatch && searchMatch;
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text("No students added"));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        final docId = docs[index].id;

                        final name = data['name'] ?? '';
                        final className = data['className'] ?? '';
                        final section = data['section'] ?? '';
                        final parentName = data['parentName'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                name.isNotEmpty ? name[0] : '?',
                              ),
                            ),
                            title: Text(name),
                            subtitle:
                                Text('$className - Section $section'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    context.push('/edit-student',
                                        extra: {
                                          'studentId': docId,
                                          'data': data,
                                        });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(
                                        context, ref, docId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

      /// ➕ ADD STUDENT
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-student'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 🔴 DELETE
  void _confirmDelete(
      BuildContext context, WidgetRef ref, String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content:
            const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final school =
                  await ref.read(currentSchoolProvider.future);

              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(school.id)
                  .collection('students')
                  .doc(studentId)
                  .delete();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}