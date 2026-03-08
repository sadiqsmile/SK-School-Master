import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart' as admin_classes;
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/announcement_service.dart';

enum _TargetMode { all, teachers, parents, classSpecific }

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  _TargetMode _mode = _TargetMode.all;
  String? _selectedClassId;
  String? _selectedSectionId;

  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _targetValue() {
    switch (_mode) {
      case _TargetMode.all:
        return 'all';
      case _TargetMode.teachers:
        return 'teachers';
      case _TargetMode.parents:
        return 'parents';
      case _TargetMode.classSpecific:
        final c = (_selectedClassId ?? '').trim();
        final s = (_selectedSectionId ?? '').trim();
        if (c.isEmpty || s.isEmpty) return '';
        return 'class_${c}_$s';
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final msg = _messageController.text.trim();
    final target = _targetValue();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message is required')),
      );
      return;
    }

    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a target audience')),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final schoolDoc = await ref.read(currentSchoolProvider.future);
      await AnnouncementService().createAnnouncement(
        schoolId: schoolDoc.id,
        title: title,
        message: msg,
        target: target,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement published')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(admin_classes.classesProvider);
    final sectionsAsync = _selectedClassId == null
        ? const AsyncValue.data(null)
        : ref.watch(sectionsProvider(_selectedClassId!)).whenData((snap) => snap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g., School Holiday',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Write the announcement message...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_TargetMode>(
            initialValue: _mode,
            decoration: const InputDecoration(
              labelText: 'Target audience',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: _TargetMode.all,
                child: Text('All'),
              ),
              DropdownMenuItem(
                value: _TargetMode.teachers,
                child: Text('Teachers only'),
              ),
              DropdownMenuItem(
                value: _TargetMode.parents,
                child: Text('Parents only'),
              ),
              DropdownMenuItem(
                value: _TargetMode.classSpecific,
                child: Text('Class specific'),
              ),
            ],
            onChanged: _isPublishing
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _mode = value;
                      if (_mode != _TargetMode.classSpecific) {
                        _selectedClassId = null;
                        _selectedSectionId = null;
                      }
                    });
                  },
          ),
          if (_mode == _TargetMode.classSpecific) ...[
            const SizedBox(height: 12),
            classesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Failed to load classes: $e'),
              data: (snap) {
                final docs = snap.docs;
                if (docs.isEmpty) {
                  return const Text('No classes available. Create classes first.');
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final d in docs)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(
                          (d.data()['name'] ?? d.data()['className'] ?? d.id)
                              .toString(),
                        ),
                      ),
                  ],
                  onChanged: _isPublishing
                      ? null
                      : (value) {
                          setState(() {
                            _selectedClassId = value;
                            _selectedSectionId = null;
                          });
                        },
                );
              },
            ),
            const SizedBox(height: 12),
            if (_selectedClassId != null)
              sectionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Failed to load sections: $e'),
                data: (snap) {
                  final docs = snap?.docs ?? const <dynamic>[];
                  if (docs.isEmpty) {
                    return const Text(
                      'No sections for this class. Create sections (A/B/C) first.',
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedSectionId,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final d in docs)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            (d.data()['name'] ?? d.id).toString(),
                          ),
                        ),
                    ],
                    onChanged: _isPublishing
                        ? null
                        : (value) => setState(() => _selectedSectionId = value),
                  );
                },
              ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isPublishing ? null : _publish,
            icon: _isPublishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(_isPublishing ? 'Publishing...' : 'Publish'),
          ),
        ],
      ),
    );
  }
}
