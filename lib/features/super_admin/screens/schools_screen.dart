import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/providers/super_admin_provider.dart';

class SchoolsScreen extends ConsumerWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsData = ref.watch(schoolsProvider);

    return schoolsData.when(
      data: (snapshot) {
        final docs = snapshot.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No schools created yet'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name = (data['name'] ?? data['schoolName'] ?? '').toString();
            final schoolId = (data['schoolId'] ?? docs[index].id).toString();
            final plan = (data['subscriptionPlan'] ?? '').toString();

            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text('School ID: $schoolId'),
                trailing: Text(plan),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
