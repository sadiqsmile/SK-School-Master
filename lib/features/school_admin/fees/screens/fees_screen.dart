// features/school_admin/fees/screens/fees_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

import 'package:school_app/features/school_admin/fees/providers/fee_types_provider.dart';
import 'package:school_app/features/school_admin/fees/services/fee_type_service.dart';
import 'package:school_app/providers/current_school_provider.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFF1FCFB);
    const accent = Color(0xFF14B8A6);

    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      data: (schoolDoc) {
        return AdminLayout(
          title: 'Fee Types',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addOrEditFeeType(
              context,
              ref,
              schoolId: schoolDoc.id,
            ),
            backgroundColor: accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Fee Type'),
          ),
          body: _FeeTypesBody(
            lightBg: lightBg,
            accent: accent,
            schoolId: schoolDoc.id,
          ),
        );
      },
      loading: () => const AdminLayout(
        title: 'Fee Types',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
          ),
        ),
      ),
      error: (e, _) => AdminLayout(
        title: 'Fee Types',
        body: Center(child: Text('Error loading school: $e')),
      ),
    );
  }
}

class _FeeTypesBody extends ConsumerWidget {
  const _FeeTypesBody({
    required this.lightBg,
    required this.accent,
    required this.schoolId,
  });

  final Color lightBg;
  final Color accent;
  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeTypesAsync = ref.watch(feeTypesProvider);

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
                    child: Icon(Icons.category_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Manage your fee types (e.g., Tuition, Transport, Exam).',
                      style: TextStyle(height: 1.4, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            feeTypesAsync.when(
              data: (snapshot) {
                final feeTypes = snapshot.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Fee Types',
                            '${feeTypes.length}',
                            Icons.category_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'School',
                            schoolId,
                            Icons.apartment_rounded,
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
                            'Fee Types',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (feeTypes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No fee types yet. Use “Add Fee Type” to create your first one.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...feeTypes.map((doc) {
                              final data = doc.data();
                              final name = (data['name'] ?? '').toString();

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
                                      Icon(Icons.label_rounded, color: accent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name.isEmpty ? '(Unnamed)' : name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => _addOrEditFeeType(
                                          context,
                                          ref,
                                          schoolId: schoolId,
                                          feeTypeId: doc.id,
                                          initialName: name,
                                        ),
                                        icon: Icon(
                                          Icons.edit_rounded,
                                          color: accent,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteFeeType(
                                          context,
                                          ref,
                                          schoolId: schoolId,
                                          feeTypeId: doc.id,
                                          name: name,
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                  child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
                ),
              ),
              error: (e, _) => Center(child: Text('Error loading fee types: $e')),
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

}

Future<void> _addOrEditFeeType(
  BuildContext context,
  WidgetRef ref, {
  required String schoolId,
  String? feeTypeId,
  String? initialName,
}) async {
  final controller = TextEditingController(text: initialName ?? '');
  try {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(feeTypeId == null ? 'Add Fee Type' : 'Edit Fee Type'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Fee type name',
              hintText: 'e.g., Tuition',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final name = (result ?? '').trim();
    if (name.isEmpty) return;

    final service = ref.read(feeTypeServiceProvider);

    if (feeTypeId == null) {
      await service.addFeeType(schoolId: schoolId, name: name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fee type added')),
      );
    } else {
      await service.updateFeeType(
        schoolId: schoolId,
        feeTypeId: feeTypeId,
        name: name,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fee type updated')),
      );
    }
  } on DuplicateFeeTypeException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${e.name}” already exists.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save fee type: $e')),
    );
  } finally {
    controller.dispose();
  }
}

Future<void> _deleteFeeType(
  BuildContext context,
  WidgetRef ref, {
  required String schoolId,
  required String feeTypeId,
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Delete fee type?'),
        content: Text(
          'This will delete “${name.isEmpty ? 'this fee type' : name}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    final service = ref.read(feeTypeServiceProvider);
    await service.deleteFeeType(schoolId: schoolId, feeTypeId: feeTypeId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fee type deleted')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete fee type: $e')),
    );
  }
}

