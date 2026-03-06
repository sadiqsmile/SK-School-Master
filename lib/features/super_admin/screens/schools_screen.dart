// features/super_admin/screens/schools_screen.dart
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No schools created yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name = (data['name'] ?? data['schoolName'] ?? '').toString();
            final schoolId = (data['schoolId'] ?? docs[index].id).toString();
            final plan = (data['subscriptionPlan'] ?? '').toString();

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A00A876),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF00A876),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'School ID: $schoolId',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1A00A876),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    plan.isEmpty ? 'Standard' : plan,
                    style: const TextStyle(
                      color: Color(0xFF00A876),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A876)),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
