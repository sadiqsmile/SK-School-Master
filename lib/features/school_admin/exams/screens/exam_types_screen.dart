import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/exam_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/exam_service.dart';

class ExamTypesScreen extends ConsumerWidget {
  const ExamTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolIdAsync = ref.watch(schoolIdProvider);

    return schoolIdAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Exam Types')),
        body: Center(child: Text(e.toString())),
      ),
      data: (schoolId) {
        final typesAsync = ref.watch(examTypesProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Exam Types'),
          ),
          body: typesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (snapshot) {
              final types = snapshot.docs
                  .map((d) {
                    final data = d.data();
                    final name = (data['name'] ?? '').toString();
                    return (id: d.id, name: name);
                  })
                  .where((t) => t.name.trim().isNotEmpty)
                  .toList(growable: false)
                ..sort((a, b) => a.name.compareTo(b.name));

              if (types.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No Exam Types yet.\n\nTap + to add your first (e.g. Unit Test, Mid Term).',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: types.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = types[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.category_rounded),
                      title: Text(t.name),
                      subtitle: Text('Key: ${t.id}'),
                      trailing: PopupMenuButton<_TypeAction>(
                        onSelected: (action) async {
                          if (action == _TypeAction.edit) {
                            await _showUpsertDialog(
                              context: context,
                              schoolId: schoolId,
                              existingId: t.id,
                              initialName: t.name,
                            );
                          } else if (action == _TypeAction.delete) {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Delete Exam Type?'),
                                  content: Text(
                                    'Delete "${t.name}"?\n\nThis will not delete existing exams that already used this type.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (ok != true) return;

                            try {
                              await ExamService().deleteExamType(
                                schoolId: schoolId,
                                examTypeId: t.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Deleted')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _TypeAction.edit,
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: _TypeAction.delete,
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showUpsertDialog(
              context: context,
              schoolId: schoolId,
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

enum _TypeAction { edit, delete }

Future<void> _showUpsertDialog({
  required BuildContext context,
  required String schoolId,
  String? existingId,
  String initialName = '',
}) async {
  final controller = TextEditingController(text: initialName);

  try {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existingId == null ? 'Add Exam Type' : 'Edit Exam Type'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Unit Test',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await ExamService().upsertExamType(
        schoolId: schoolId,
        name: controller.text,
        existingId: existingId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingId == null ? 'Added' : 'Updated'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  } finally {
    controller.dispose();
  }
}
