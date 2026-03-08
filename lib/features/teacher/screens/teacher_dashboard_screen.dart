import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/features/teacher/providers/teacher_profile_provider.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const deepBlue = Color(0xFF1E40AF);
    const accentCyan = Color(0xFF06B6D4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [deepBlue, accentCyan],
          ),
        ),
        child: SafeArea(
          child: ref.watch(teacherProfileProvider).when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Teacher profile not ready: $e',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (doc) {
                  final data = doc.data() ?? const <String, dynamic>{};
                  final name = (data['name'] ?? 'Teacher').toString();
                  final assignments = ref.watch(teacherAssignmentsProvider);

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(18),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Select a class to mark attendance. This is locked to your assigned classes.',
                              style: TextStyle(
                                color: Color(0xFF4B5563),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Classes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (assignments.isEmpty)
                                const Text(
                                  'No classes assigned yet. Ask admin to assign classes/sections.',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                )
                              else
                                ...assignments.map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0xFFEFF6FF),
                                        child: Icon(
                                          Icons.fact_check_rounded,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      title: Text(
                                        a.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      subtitle: const Text('Tap to mark today\'s attendance'),
                                      trailing: const Icon(Icons.chevron_right_rounded),
                                      onTap: () {
                                        final classId = Uri.encodeComponent(a.classId);
                                        final sectionId = Uri.encodeComponent(a.sectionId);
                                        context.go('/teacher/attendance/$classId/$sectionId');
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}
