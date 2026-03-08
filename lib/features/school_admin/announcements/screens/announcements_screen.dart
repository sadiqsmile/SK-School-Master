import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/announcements/screens/create_announcement_screen.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/providers/announcement_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/announcement_service.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFF1FCFB);
    const accent = Color(0xFF14B8A6);

    final schoolIdAsync = ref.watch(schoolIdProvider);

    return schoolIdAsync.when(
      data: (schoolId) {
        final announcementsAsync = ref.watch(announcementsProvider);

        return AdminLayout(
          title: 'Announcements',
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateAnnouncementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Announcement'),
          ),
          body: Container(
            color: lightBg,
            child: Padding(
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
                          child: Icon(Icons.campaign_rounded, color: accent),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Create quick messages for parents and teachers. They will see them instantly in the app.',
                            style: TextStyle(
                              height: 1.4,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: announcementsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading announcements: $e'),
                      ),
                      data: (snapshot) {
                        final docs = snapshot.docs;
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No announcements yet. Tap “Create Announcement”.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final a = Announcement.fromDoc(doc);
                            final dateLabel = _formatDate(a.createdAt);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accent.withAlpha(40),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: accent.withAlpha(30),
                                  child: Icon(
                                    Icons.campaign_rounded,
                                    color: accent,
                                  ),
                                ),
                                title: Text(
                                  a.title.trim().isEmpty
                                      ? '(Untitled)'
                                      : a.title.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_targetLabel(a.target)}${dateLabel == null ? '' : ' • $dateLabel'}',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFDC2626),
                                  ),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    ref,
                                    schoolId: schoolId,
                                    announcementId: a.id,
                                    title: a.title,
                                  ),
                                ),
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (_) => _AnnouncementDetailDialog(
                                      announcement: a,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const AdminLayout(
        title: 'Announcements',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
          ),
        ),
      ),
      error: (e, _) => AdminLayout(
        title: 'Announcements',
        body: Center(child: Text('Failed to load school: $e')),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref, {
  required String schoolId,
  required String announcementId,
  required String title,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text(
          'Delete “${title.trim().isEmpty ? 'this announcement' : title.trim()}”?',
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
    await AnnouncementService().deleteAnnouncement(
      schoolId: schoolId,
      announcementId: announcementId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement deleted')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete: $e')),
    );
  }
}

String _targetLabel(String target) {
  final t = target.trim();
  if (t == 'all') return 'All';
  if (t == 'teachers') return 'Teachers only';
  if (t == 'parents') return 'Parents only';
  if (t.startsWith('class_')) {
    final parts = t.split('_');
    if (parts.length >= 3) {
      final classId = parts[1];
      final sectionId = parts.sublist(2).join('_');
      return 'Class specific: $classId-$sectionId';
    }
    return 'Class specific';
  }
  return t.isEmpty ? 'Target: (unknown)' : 'Target: $t';
}

String? _formatDate(DateTime? dt) {
  if (dt == null) return null;
  return '${dt.day.toString().padLeft(2, '0')} '
      '${_month(dt.month)} '
      '${dt.year}';
}

String _month(int m) {
  const months = <int, String>{
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };
  return months[m] ?? '';
}

class _AnnouncementDetailDialog extends StatelessWidget {
  const _AnnouncementDetailDialog({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final title = announcement.title.trim().isEmpty
        ? 'Announcement'
        : announcement.title.trim();

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.message.trim().isEmpty
                  ? '(No message)'
                  : announcement.message.trim(),
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              _targetLabel(announcement.target),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
