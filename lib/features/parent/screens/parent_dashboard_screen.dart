// features/parent/screens/parent_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/parent/screens/parent_announcements_screen.dart';

import 'package:school_app/models/student.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/features/parent/providers/parent_children_provider.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/providers/announcement_provider.dart';
import 'package:school_app/features/announcements/screens/announcement_detail_screen.dart';
import 'package:school_app/core/widgets/web_dashboard_footer.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-select the first child when the list loads.
    ref.listen<AsyncValue<List<Student>>>(parentChildrenProvider, (prev, next) {
      next.whenOrNull(
        data: (children) {
          final selected = ref.read(selectedChildIdProvider);
          if (children.isEmpty) return;
          if (selected != null) return;
          // Post-frame to avoid set-state during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(selectedChildIdProvider.notifier).state =
                children.first.id;
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load your children: $e'),
          ),
        ),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No students are linked to this parent account yet.\n\nPlease contact the school admin.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final selectedId = ref.watch(selectedChildIdProvider);
          final effectiveSelectedId = selectedId ?? children.first.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AnnouncementsPreviewCard(
                children: children,
                announcementsAsync: announcementsAsync,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(effectiveSelectedId),
                initialValue: effectiveSelectedId,
                decoration: const InputDecoration(
                  labelText: 'Select child',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in children)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name.isEmpty ? s.id : s.name),
                    ),
                ],
                onChanged: (value) {
                  ref.read(selectedChildIdProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),
              if (selectedChild != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedChild.name.isEmpty
                              ? 'Student: ${selectedChild.id}'
                              : selectedChild.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Admission No: ${selectedChild.admissionNo}'),
                        Text('Class: ${selectedChild.classId}'),
                        Text('Section: ${selectedChild.section}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'More features coming next:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Announcements'),
                subtitle: const Text('Read messages from school'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ParentAnnouncementsScreen(),
                    ),
                  );
                },
              ),
              const ListTile(
                leading: Icon(Icons.fact_check_outlined),
                title: Text('Attendance'),
                subtitle: Text('Read-only view (to be implemented)'),
              ),
              const ListTile(
                leading: Icon(Icons.menu_book_outlined),
                title: Text('Homework'),
                subtitle: Text('Read-only view (to be implemented)'),
              ),
              const ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Fees'),
                subtitle: Text('Read-only view (to be implemented)'),
              ),
              const WebDashboardFooter(),
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementsPreviewCard extends StatelessWidget {
  const _AnnouncementsPreviewCard({
    required this.children,
    required this.announcementsAsync,
  });

  final List<Student> children;
  final AsyncValue announcementsAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Announcements',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ParentAnnouncementsScreen(),
                      ),
                    );
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            announcementsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text(
                'Failed to load announcements: $e',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              data: (snapshot) {
                final visible = snapshot.docs
                    .map(Announcement.fromDoc)
                    .where((a) => _isVisibleForParent(a.target, children))
                    .take(3)
                    .toList(growable: false);

                if (visible.isEmpty) {
                  return const Text(
                    'No announcements yet.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  );
                }

                return Column(
                  children: [
                    for (final a in visible)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.campaign_rounded),
                        title: Text(
                          a.title.trim().isEmpty
                              ? '(Untitled)'
                              : a.title.trim(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          a.message.trim().isEmpty
                              ? '(No message)'
                              : a.message.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnnouncementDetailScreen(announcement: a),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
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
    if (c.classId.trim() == classId && c.section.trim() == sectionId) {
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
