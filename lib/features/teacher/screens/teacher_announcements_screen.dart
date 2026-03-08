import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/announcements/screens/announcement_detail_screen.dart';
import 'package:school_app/features/teacher/providers/teacher_profile_provider.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/providers/announcement_provider.dart';

class TeacherAnnouncementsScreen extends ConsumerWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final assignments = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (snapshot) {
          final visible = snapshot.docs
              .map(Announcement.fromDoc)
              .where((a) => _isVisibleForTeacher(a.target, assignments))
              .toList(growable: false);

          if (visible.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No announcements yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = visible[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign_rounded),
                  title: Text(
                    a.title.trim().isEmpty ? '(Untitled)' : a.title.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    a.message.trim().isEmpty ? '(No message)' : a.message.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AnnouncementDetailScreen(
                          announcement: a,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

bool _isVisibleForTeacher(String target, List<TeacherAssignment> assignments) {
  final t = target.trim();
  if (t == 'all') return true;
  if (t == 'teachers') return true;

  if (!t.startsWith('class_')) return false;
  final parsed = _parseClassTarget(t);
  if (parsed == null) return false;

  final (classId, sectionId) = parsed;
  for (final a in assignments) {
    if (a.classId.trim() == classId && a.sectionId.trim() == sectionId) {
      return true;
    }
  }

  return false;
}

(String, String)? _parseClassTarget(String target) {
  final parts = target.split('_');
  if (parts.length < 3) return null;
  final classId = parts[1].trim();
  final sectionId = parts.sublist(2).join('_').trim();
  if (classId.isEmpty || sectionId.isEmpty) return null;
  return (classId, sectionId);
}
