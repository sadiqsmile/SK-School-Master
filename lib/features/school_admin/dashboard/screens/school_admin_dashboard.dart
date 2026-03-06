import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(schoolProvider);

    return AdminLayout(
      title: 'School Admin Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              context.go('/');
            }
          },
        ),
      ],
      body: schoolAsync.when(
        data: (doc) {
          final schoolData = doc.data();
          if (schoolData == null) {
            return const Center(child: Text('School data not found'));
          }

          final name = (schoolData['name'] ?? 'School').toString();
          final schoolId = (schoolData['schoolId'] ?? '').toString();
          final plan = (schoolData['subscriptionPlan'] ?? '').toString();

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 10),
                Text('School ID: $schoolId'),
                const SizedBox(height: 20),
                Text('Plan: $plan'),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
