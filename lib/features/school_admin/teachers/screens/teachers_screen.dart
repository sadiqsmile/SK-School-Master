import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);

    return AdminLayout(
      title: 'Teachers',
      body: teachersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (snapshot) {
          final teachers = snapshot.docs;

          if (teachers.isEmpty) {
            return const Center(child: Text("No teachers added"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final doc = teachers[index];
              final data = doc.data() as Map<String, dynamic>;

              final teacherId = doc.id;
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? '';
              final assignmentKeys = data['assignmentKeys'] ?? [];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 👤 TOP INFO
                    Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// 📱 PHONE
                    Text("📱 $phone",
                        style: const TextStyle(fontSize: 12)),

                    const SizedBox(height: 6),

                    /// 📚 ASSIGNMENT
                    Text(
                      "Assigned: ${assignmentKeys.isEmpty ? "Not Assigned" : assignmentKeys.join(", ")}",
                      style: const TextStyle(fontSize: 12),
                    ),

                    const SizedBox(height: 10),

                    /// 🔥 ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.push('/assign-class',
                                  extra: teacherId);
                            },
                            child: const Text("Assign"),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: reset password
                            },
                            child: const Text("Reset"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),

      /// ➕ ADD TEACHER BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-teacher'),
        icon: const Icon(Icons.person_add),
        label: const Text("Add Teacher"),
      ),
    );
  }
}