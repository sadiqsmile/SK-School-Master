import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/announcements/screens/announcement_detail_screen.dart';
import 'package:school_app/features/parent/providers/parent_children_provider.dart';
import 'package:school_app/features/parent/providers/parent_dashboard_providers.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/models/student.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key, required this.onOpenAnnouncements});

  final VoidCallback onOpenAnnouncements;

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(selectedChildIdProvider.notifier).state = children.first.id;
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);

    final greeting = _greeting();

    return childrenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load children: $e'),
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
        final effectiveId = selectedId ?? children.first.id;
        final child = selectedChild ?? children.first;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              greeting: greeting,
              child: child,
              children: children,
              selectedChildId: effectiveId,
              onSelectedChildId: (value) {
                ref.read(selectedChildIdProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 14),
            _AttendanceCard(child: child),
            const SizedBox(height: 14),
            _HomeworkCard(child: child),
            const SizedBox(height: 14),
            _FeesCard(child: child),
            const SizedBox(height: 14),
            _AnnouncementCard(
              child: child,
              onOpenAnnouncements: widget.onOpenAnnouncements,
            ),
          ],
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.greeting,
    required this.child,
    required this.children,
    required this.selectedChildId,
    required this.onSelectedChildId,
  });

  final String greeting;
  final Student child;
  final List<Student> children;
  final String selectedChildId;
  final ValueChanged<String?> onSelectedChildId;

  @override
  Widget build(BuildContext context) {
    final name = child.name.trim().isEmpty ? child.id : child.name.trim();
    final classLabel = _classLabel(child);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$name's Dashboard",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classLabel,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedChildId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0B5FA8),
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  items: [
                    for (final s in children)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.name.trim().isEmpty ? s.id : s.name.trim()} • ${_classLabel(s)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onSelectedChildId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.child});

  final Student child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(parentAttendanceTodayProvider(child));

    return _DashboardCard(
      title: 'Attendance',
      icon: Icons.fact_check_rounded,
      tint: const Color(0xFF16A34A),
      child: summaryAsync.when(
        loading: () => const _CardLoadingRow(),
        error: (e, _) => Text('Failed to load attendance: $e'),
        data: (s) {
          if (!s.isMarked) {
            return const Text(
              'Today: Not marked yet',
              style: TextStyle(color: Color(0xFF6B7280)),
            );
          }

          final status = _prettyStatus(s.studentStatus);
          final counts = 'Present: ${s.present}  •  Absent: ${s.absent}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today: $status',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                counts,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeworkCard extends ConsumerWidget {
  const _HomeworkCard({required this.child});

  final Student child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(parentPendingHomeworkCountProvider(child));

    return _DashboardCard(
      title: 'Homework',
      icon: Icons.menu_book_rounded,
      tint: const Color(0xFF7C3AED),
      child: pendingAsync.when(
        loading: () => const _CardLoadingRow(),
        error: (e, _) => Text('Failed to load homework: $e'),
        data: (count) {
          return Text(
            count == 1 ? '1 pending homework' : '$count pending homework',
            style: const TextStyle(fontWeight: FontWeight.w800),
          );
        },
      ),
    );
  }
}

class _FeesCard extends ConsumerWidget {
  const _FeesCard({required this.child});

  final Student child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(parentFeesSummaryProvider(child));

    return _DashboardCard(
      title: 'Fees',
      icon: Icons.currency_rupee_rounded,
      tint: const Color(0xFFF59E0B),
      child: feesAsync.when(
        loading: () => const _CardLoadingRow(),
        error: (_, _) => const Text(
          'Fees: not available yet',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        data: (summary) {
          final pending = summary.pendingAmount;
          if (pending <= 0) {
            return const Text(
              'No pending balance',
              style: TextStyle(fontWeight: FontWeight.w800),
            );
          }
          return Text(
            'Pending ₹$pending',
            style: const TextStyle(fontWeight: FontWeight.w800),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  const _AnnouncementCard({required this.child, required this.onOpenAnnouncements});

  final Student child;
  final VoidCallback onOpenAnnouncements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(parentLatestAnnouncementProvider(child));

    return _DashboardCard(
      title: 'Announcements',
      icon: Icons.campaign_rounded,
      tint: const Color(0xFF0EA5E9),
      trailing: TextButton(
        onPressed: onOpenAnnouncements,
        child: const Text('See all'),
      ),
      child: latest == null
          ? const Text(
              'No announcements yet.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : _AnnouncementPreview(announcement: latest),
    );
  }
}

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final title = announcement.title.trim().isEmpty
        ? '(Untitled)'
        : announcement.title.trim();
    final msg = announcement.message.trim().isEmpty
        ? '(No message)'
        : announcement.message.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(announcement: announcement),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              msg,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tint.withAlpha(25),
                  child: Icon(icon, color: tint),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                ...(trailing == null
                    ? const <Widget>[]
                    : <Widget>[trailing!]),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CardLoadingRow extends StatelessWidget {
  const _CardLoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 2),
      child: LinearProgressIndicator(),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String _classLabel(Student s) {
  final c = s.classId.trim();
  final sec = s.section.trim();
  if (c.isEmpty && sec.isEmpty) return 'Class';
  if (sec.isEmpty) return 'Class $c';
  return 'Class $c$sec';
}

String _prettyStatus(String? code) {
  final c = (code ?? '').trim().toLowerCase();
  if (c.isEmpty) return 'Unknown';
  if (c == 'p' || c == 'present') return 'Present';
  if (c == 'a' || c == 'absent') return 'Absent';
  if (c == 'l' || c == 'late') return 'Late';
  if (c == 'lv' || c == 'leave') return 'On leave';
  return c;
}
