import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/section_in_use_provider.dart';
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/classes/services/section_service.dart';
import 'package:school_app/providers/current_school_provider.dart';

class SectionsScreen extends ConsumerStatefulWidget {
  const SectionsScreen({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends ConsumerState<SectionsScreen> {
  bool _isMutating = false;

  static const _fixedSections = <String>['A', 'B', 'C', 'D', 'E', 'F'];

  Future<void> _ensureDefaults() async {
    setState(() => _isMutating = true);
    try {
      final school = await ref.read(currentSchoolProvider.future);
      await SectionService().ensureDefaultSections(
        schoolId: school.id,
        classId: widget.classId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default sections created (A, B, C)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create default sections: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _addSection({required Set<String> existingSectionIds}) async {
    try {
      final available = _fixedSections
          .where((s) => !existingSectionIds.contains(s))
          .toList(growable: false);

      if (available.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All sections (A-F) already exist.')),
        );
        return;
      }

      String selected = available.first;
      final name = await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add section'),
                content: DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Select section',
                  ),
                  items: [
                    for (final s in available)
                      DropdownMenuItem(
                        value: s,
                        child: Text('Section $s'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selected = value);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
      );

      final trimmed = (name ?? '').trim();
      if (trimmed.isEmpty) return;

      setState(() => _isMutating = true);
      final school = await ref.read(currentSchoolProvider.future);
      await SectionService().createSection(
        schoolId: school.id,
        classId: widget.classId,
        sectionName: trimmed,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Section ${trimmed.toUpperCase()} added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add section: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteSection({
    required String sectionId,
    required String sectionName,
  }) async {
    // Extra safety: re-check before showing confirmation.
    final inUse = await ref.read(
      sectionInUseProvider(
        SectionUsageKey(classId: widget.classId, sectionId: sectionId),
      ).future,
    );
    if (inUse) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete section: students are assigned to this section.',
          ),
        ),
      );
      return;
    }

    // We're about to use `context` in a dialog after an await.
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete section?'),
          content: Text('Delete Section $sectionName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _isMutating = true);
    try {
      final school = await ref.read(currentSchoolProvider.future);
      await SectionService().deleteSection(
        schoolId: school.id,
        classId: widget.classId,
        sectionId: sectionId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Section $sectionName deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete section: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(sectionsProvider(widget.classId));
    final existingSectionIds = <String>{
      for (final doc in sectionsAsync.asData?.value.docs ?? const [])
        doc.id.trim().toUpperCase(),
    };

    return Scaffold(
      appBar: AppBar(title: Text('Sections - ${widget.classId}')),
      body: sectionsAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No sections'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isMutating ? null : _ensureDefaults,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: const Text('Create default sections (A, B, C)'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.docs[i];
              final data = doc.data();
              final name = (data['name'] ?? '').toString();

              final inUseAsync = ref.watch(
                sectionInUseProvider(
                  SectionUsageKey(
                    classId: widget.classId,
                    sectionId: doc.id,
                  ),
                ),
              );

              final isInUse = inUseAsync.value == true;
              final isChecking = inUseAsync.isLoading;

              return ListTile(
                title: Text('Section $name'),
                trailing: IconButton(
                  tooltip: isInUse
                      ? 'Cannot delete: students assigned'
                      : (isChecking ? 'Checking...' : 'Delete section'),
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: (_isMutating || isChecking || isInUse)
                      ? null
                      : () => _deleteSection(
                            sectionId: doc.id,
                            sectionName: name.isEmpty ? doc.id : name,
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
        onPressed: _isMutating
          ? null
          : () => _addSection(existingSectionIds: existingSectionIds),
        child: _isMutating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
      ),
    );
  }
}
