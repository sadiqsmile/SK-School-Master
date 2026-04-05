import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class ClassStudentsScreen extends ConsumerStatefulWidget {
  final String className;

  const ClassStudentsScreen({super.key, required this.className});

  @override
  ConsumerState<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends ConsumerState<ClassStudentsScreen> {
  String selectedSection = "All";

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return AdminLayout(
      title: widget.className,
      body: schoolAsync.when(
        data: (school) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(school.id)
                .collection('students')
                .where('className', isEqualTo: widget.className)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data!.docs;
              final docs = selectedSection == "All"
                  ? allDocs
                  : allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['section'] == selectedSection;
                    }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No students found"));
              }

              return Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ["All", "A", "B", "C"].map((section) {
                        final isSelected = selectedSection == section;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(section),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => selectedSection = section);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(data['name'] ?? ''),
                          subtitle: Text("Section {data['section'] ?? ''}"),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}