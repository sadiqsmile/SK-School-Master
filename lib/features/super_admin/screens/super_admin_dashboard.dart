// features/super_admin/screens/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/platform_provider.dart';
import '../data/school_service.dart';
import 'package:school_app/features/super_admin/providers/schools_provider.dart'
    as schools;

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformData = ref.watch(platformProvider);
    final schoolsData = ref.watch(schools.schoolsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Super Admin Dashboard")),
      body: platformData.when(
        data: (doc) {
          final data = (doc.data() as Map<String, dynamic>?) ?? {};

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
                  onPressed: () async {
                    final schoolService = SchoolService();

                    await schoolService.createSchool(
                      schoolName: "Test School",
                      adminEmail: "testadmin@school.com",
                      adminPassword: "12345678",
                      themeColor: "#1976D2",
                    );
                  },
                  child: const Text("Add School"),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text("Schools", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                schoolsData.when(
                  data: (snapshot) {
                    final docs = snapshot.docs;

                    if (docs.isEmpty) {
                      return const Text("No schools created yet");
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final school = docs[index].data();

                        final name =
                            (school['name'] ?? school['schoolName'] ?? '')
                                .toString();
                        final schoolId = (school['schoolId'] ?? docs[index].id)
                            .toString();
                        final subscriptionPlan =
                            (school['subscriptionPlan'] ?? '').toString();

                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text("School ID: $schoolId"),
                            trailing: Text(subscriptionPlan),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text("Error: $e"),
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
