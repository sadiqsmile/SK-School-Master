// features/school_admin/students/screens/students_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFF2FCF7);
    const accent = Color(0xFF10B981);
    final studentsAsync = ref.watch(studentsProvider);

    return AdminLayout(
      title: 'Students',
      body: _StudentsBody(
        lightBg: lightBg,
        accent: accent,
        studentsAsync: studentsAsync,
      ),
    );
  }
}

class _StudentsBody extends StatelessWidget {
  const _StudentsBody({
    required this.lightBg,
    required this.accent,
    required this.studentsAsync,
  });

  final Color lightBg;
  final Color accent;
  final AsyncValue studentsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.28)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withOpacity(0.16),
                    child: Icon(Icons.groups_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Students dashboard with enrollment and activity snapshot.',
                      style: TextStyle(height: 1.4, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            studentsAsync.when(
              data: (snapshot) {
                final students = snapshot.docs;
                final totalCount = students.length;
                final recentStudents = students.take(3).toList();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total Students',
                            '$totalCount',
                            Icons.badge_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'New This Week',
                            '0',
                            Icons.person_add_alt_1_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Admissions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recentStudents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No students enrolled yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...recentStudents.map((doc) {
                              final data = doc.data();
                              final name = data['name'] ?? 'Student';
                              final grade = data['grade'] ?? '';
                              final section = data['section'] ?? '';
                              return _listRow(
                                name,
                                '${grade.isNotEmpty ? 'Grade $grade' : 'Grade N/A'}${section.isNotEmpty ? ' - Section $section' : ''}',
                                Icons.person_rounded,
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              ),
              error: (e, _) =>
                  Center(child: Text('Error loading students: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _listRow(String name, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
