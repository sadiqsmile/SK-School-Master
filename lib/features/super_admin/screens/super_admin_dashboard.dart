// features/super_admin/screens/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:school_app/providers/super_admin_provider.dart';
import 'create_school_screen.dart';
import 'schools_screen.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformData = ref.watch(platformProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                // Keep navigation within GoRouter; pushing LoginScreen via
                // Navigator can leave the app outside the router context on web.
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: platformData.when(
        data: (doc) {
          final data = doc.data() ?? <String, dynamic>{};

          final totalSchools = data['totalSchools'] ?? 0;
          final totalStudents = data['totalStudents'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Total Schools: $totalSchools",
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 20),
                Text(
                  "Total Students: $totalStudents",
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const SafeArea(
                        child: CreateSchoolScreen(),
                      ),
                    );
                  },
                  child: const Text('Add School'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text("Schools", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 320,
                  child: SchoolsScreen(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
