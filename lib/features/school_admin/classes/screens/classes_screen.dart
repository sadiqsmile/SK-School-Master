import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return AdminLayout(
      title: 'Classes',

      body: schoolAsync.when(
        data: (school) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(school.id)
                .collection('classes')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No classes added"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  final name = data['name'] ?? '';
                  final group = data['group'] ?? '';
                  final sections =
                      List<String>.from(data['sections'] ?? []);

                  return GestureDetector(
                    onTap: () {
                      context.push('/class-students', extra: {
                        'className': name,
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          /// 🎓 ICON
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.class_, color: Colors.blue),
                          ),

                          const SizedBox(width: 12),

                          /// 📚 DETAILS
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
                                  group,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Wrap(
                                  spacing: 6,
                                  children: sections
                                      .map(
                                        (s) => Chip(
                                          label: Text(s),
                                          backgroundColor:
                                              Colors.deepPurple.shade50,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),

      /// ➕ ADD BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-class'),
        icon: const Icon(Icons.add),
        label: const Text("Add Class"),
      ),
    );
  }
}