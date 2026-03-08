import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/announcements/screens/announcement_detail_screen.dart';
import 'package:school_app/features/parent/providers/parent_children_provider.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/providers/announcement_provider.dart';

class ParentAnnouncementsScreen extends ConsumerWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load children: $e')),
        data: (children) {
          return announcementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (snapshot) {
              final docs = snapshot.docs;
              final visible = docs
                  .map(Announcement.fromDoc)
                  .where((a) => _isVisibleForParent(a.target, children))
                  .toList(growable: false);

              if (visible.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No announcements for you yet.',
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
                        a.message.trim().isEmpty
                            ? '(No message)'
                            : a.message.trim(),
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
          );
        },
      ),
    );
  }
}

bool _isVisibleForParent(String target, List<Student> children) {
  final t = target.trim();
  if (t == 'all') return true;
  if (t == 'parents') return true;

  if (!t.startsWith('class_')) return false;

  final parsed = _parseClassTarget(t);
  if (parsed == null) return false;

  final (classId, sectionId) = parsed;

  for (final c in children) {
    final sClass = c.classId.trim();
    final sSection = c.section.trim();
    if (sClass == classId && sSection == sectionId) {
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
