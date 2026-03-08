// features/school_admin/homework/screens/homework_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFFFF3F6);
    const accent = Color(0xFFF43F5E);
    final homeworkAsync = ref.watch(homeworkProvider);

    return AdminLayout(
      title: 'Homework',
      body: _HomeworkBody(
        lightBg: lightBg,
        accent: accent,
        homeworkAsync: homeworkAsync,
      ),
    );
  }
}

class _HomeworkBody extends StatelessWidget {
  const _HomeworkBody({
    required this.lightBg,
    required this.accent,
    required this.homeworkAsync,
  });

  final Color lightBg;
  final Color accent;
  final AsyncValue homeworkAsync;

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
                border: Border.all(color: accent.withAlpha(64)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withAlpha(41),
                    child: Icon(Icons.menu_book_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Homework board for assignment flow and submission health.',
                      style: TextStyle(height: 1.4, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            homeworkAsync.when(
              data: (snapshot) {
                final homework = snapshot.docs;
                final totalCount = homework.length;
                final openCount = homework
                    .where((doc) => doc.data()['status'] != 'completed')
                    .length;
                final recentHomework = homework.take(3).toList();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Open Tasks',
                            '$openCount',
                            Icons.assignment_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Total',
                            '$totalCount',
                            Icons.task_alt_rounded,
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
                            'Latest Homework Updates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recentHomework.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No homework assignments yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...recentHomework.map((doc) {
                              final data = doc.data();
                              final title =
                                  data['title'] ??
                                  data['subject'] ??
                                  'Assignment';
                              final info =
                                  data['description'] ??
                                  data['info'] ??
                                  'Homework task';
                              return _listRow(
                                title,
                                info,
                                Icons.science_rounded,
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
                  child: CircularProgressIndicator(color: Color(0xFFF43F5E)),
                ),
              ),
              error: (e, _) =>
                  Center(child: Text('Error loading homework: $e')),
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
          color: accent.withAlpha(20),
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
