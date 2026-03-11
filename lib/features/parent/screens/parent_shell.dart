import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/announcements/screens/announcement_detail_screen.dart';
import 'package:school_app/features/parent/providers/parent_children_provider.dart';
import 'package:school_app/features/parent/providers/parent_notifications_provider.dart';
import 'package:school_app/features/parent/screens/parent_dashboard.dart';
import 'package:school_app/features/parent/screens/parent_notifications_screen.dart';
import 'package:school_app/features/parent/screens/parent_result_screen.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/providers/announcement_provider.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/models/school_branding.dart';
import 'package:school_app/providers/current_user_doc_provider.dart';
import 'package:school_app/providers/school_branding_provider.dart';
import 'package:school_app/providers/school_provider.dart';

class ParentShell extends ConsumerStatefulWidget {
  const ParentShell({super.key});

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  int _index = 0;

  String get _title {
    switch (_index) {
      case 0:
        return 'Home';
      case 1:
        return 'Announcements';
      case 3:
        return 'Attendance';
      case 2:
        return 'Results';
      case 4:
        return 'Homework';
      case 5:
        return 'Fees';
      default:
        return 'Parent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(parentUnreadNotificationsCountProvider);

    final schoolName = ref.watch(schoolProvider).maybeWhen(
          data: (doc) => (doc.data()?['name'] ?? '').toString().trim(),
          orElse: () => '',
        );

    final branding = ref.watch(schoolBrandingProvider).maybeWhen(
          data: (b) => b,
          orElse: () => SchoolBranding.defaults(),
        );

    final logoUrl = ref.watch(schoolBrandingLogoUrlProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );

    final parentName = ref.watch(currentUserDisplayNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              schoolName.isEmpty ? 'School' : schoolName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            Text(
              parentName.trim().isEmpty ? _title : '$_title • ${parentName.trim()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: (logoUrl ?? '').trim().isEmpty
                ? const Icon(Icons.school_rounded, color: Color(0xFF0F172A))
                : Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported_rounded);
                    },
                  ),
          ),
        ),
        leadingWidth: 56,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [branding.primaryColor, branding.secondaryColor],
            ),
          ),
        ),
        actions: [
          unreadAsync.when(
            loading: () => IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ParentNotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_rounded),
            ),
            error: (e, _) => IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ParentNotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_rounded),
            ),
            data: (count) {
              final c = count.clamp(0, 99);
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ParentNotificationsScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_rounded),
                    if (c > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            c >= 99 ? '99+' : '$c',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            ParentDashboard(
              onOpenAnnouncements: () => setState(() => _index = 1),
            ),
            const _ParentAnnouncementsTab(),
            const ParentResultScreen(),
            const _ComingSoonTab(
              title: 'Attendance',
              subtitle: 'A detailed attendance view is coming next.',
              icon: Icons.fact_check_rounded,
            ),
            const _ComingSoonTab(
              title: 'Homework',
              subtitle: 'A dedicated homework list is coming next.',
              icon: Icons.menu_book_rounded,
            ),
            const _ComingSoonTab(
              title: 'Fees',
              subtitle: 'A full fees module is coming next.',
              icon: Icons.currency_rupee_rounded,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_rounded),
            label: 'Announcements',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_rounded),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_rupee_rounded),
            label: 'Fees',
          ),
        ],
      ),
    );
  }
}

class _ParentAnnouncementsTab extends ConsumerWidget {
  const _ParentAnnouncementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);

    return childrenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load children: $e'),
        ),
      ),
      data: (children) {
        return announcementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load announcements: $e'),
            ),
          ),
          data: (snapshot) {
            final visible = snapshot.docs
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
        );
      },
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
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
