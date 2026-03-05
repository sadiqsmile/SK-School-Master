// features/school_admin/screens/school_admin_dashboard.dart
// features/school_admin/screens/school_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/school_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(schoolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Admin Dashboard'),
      ),
      body: schoolAsync.when(
        data: (doc) {
          final school = doc.data();

          if (school == null) {
            return const Center(
              child: Text("School data not found"),
            );
          }

          final schoolData = school as Map<String, dynamic>;

          final name = schoolData['name'] ?? 'School';
          final schoolId = schoolData['schoolId'] ?? '';
          final plan = schoolData['subscriptionPlan'] ?? '';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(height: 10),
                Text("School ID: $schoolId"),
                const SizedBox(height: 20),
                Text("Plan: $plan"),
              ],
            ),
          );
        },

        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (e, _) => Center(
          child: Text("Error: $e"),
        ),
      ),
    );
  }
}