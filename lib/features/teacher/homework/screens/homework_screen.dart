import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/homework/providers/homework_provider.dart';
import 'package:school_app/features/teacher/homework/screens/add_homework_screen.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/core/offline/firestore_sync_status_action.dart';

class TeacherHomeworkScreen extends ConsumerWidget {
  const TeacherHomeworkScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

  DateTime? _readDueDate(Map<String, dynamic> data) {
    final raw = data['dueDate'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolIdAsync = ref.watch(schoolIdProvider);

    return schoolIdAsync.when(
      data: (schoolId) {
        final homeworkAsync = ref.watch(
          teacherHomeworkProvider((schoolId, classId, sectionId)),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Homework $classId-$sectionId'),
            actions: const [
              FirestoreSyncStatusAction(),
            ],
          ),
          body: homeworkAsync.when(
            data: (snapshot) {
              if (snapshot.docs.isEmpty) {
                return const Center(child: Text('No homework assigned'));
              }

              final docs = snapshot.docs.toList();
              docs.sort((a, b) {
                final aDue = _readDueDate(a.data());
                final bDue = _readDueDate(b.data());

                if (aDue == null && bDue == null) return 0;
                if (aDue == null) return 1;
                if (bDue == null) return -1;
                return aDue.compareTo(bDue);
              });

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final due = _readDueDate(data);

                  final subject = (data['subject'] ?? '').toString();
                  final description = (data['description'] ?? '').toString();

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: Text(subject.isEmpty ? '(No subject)' : subject),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty) Text(description),
                          if (due != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Due: ${_formatDate(due)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddHomeworkScreen(
                    schoolId: schoolId,
                    classId: classId,
                    sectionId: sectionId,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Homework')),
        body: Center(child: Text(e.toString())),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
