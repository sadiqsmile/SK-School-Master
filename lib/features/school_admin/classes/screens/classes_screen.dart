import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Classes"),
      ),
      body: classesAsync.when(
        data: (snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No classes yet. Tap + to add one.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final classId = docs[index].id;
              final data = docs[index].data();
              final name = (data['name'] ?? data['className'] ?? 'Class')
                  .toString();
              final section = (data['sectionType'] ?? data['section'] ?? '')
                  .toString();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.class_rounded),
                  title: Text(name),
                  subtitle: section.isEmpty ? null : Text(section),
                  onTap: () {
                    context.push('/sections/${Uri.encodeComponent(classId)}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading classes: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Using GoRouter because the app is configured with MaterialApp.router.
          context.push("/add-class");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
