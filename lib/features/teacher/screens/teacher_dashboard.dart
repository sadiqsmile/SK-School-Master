import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attendance_screen.dart';
import '../providers/teacher_provider.dart';
import 'package:school_app/features/teacher/screens/teacher_announcements_screen.dart';
import 'package:school_app/features/teacher/homework/screens/homework_screen.dart';
import 'package:school_app/features/teacher/exams/screens/exams_screen.dart';
import 'package:school_app/models/announcement.dart';
import 'package:school_app/providers/announcement_provider.dart';
import 'package:school_app/features/announcements/screens/announcement_detail_screen.dart';
import 'package:school_app/core/offline/firestore_sync_status_action.dart';
import 'package:school_app/core/widgets/school_brand_banner.dart';
import 'package:school_app/models/school_branding.dart';
import 'package:school_app/providers/school_branding_provider.dart';
import 'package:school_app/providers/school_provider.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherData = ref.watch(teacherProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: const [
          FirestoreSyncStatusAction(),
        ],
      ),
      body: teacherData.when(
        data: (doc) {
          final data = doc.data();

          if (data == null) {
            return const Center(
              child: Text('Teacher profile not found'),
            );
          }

          final rawClasses = data['classes'];
          final classes = rawClasses is List ? rawClasses : const [];

          final teacherName = (data['name'] ?? data['fullName'] ?? '').toString().trim();

          if (classes.isEmpty) {
            return const Center(
              child: Text('No classes assigned'),
            );
          }

          final visibleAnnouncements = announcementsAsync.maybeWhen(
            data: (snapshot) {
              return snapshot.docs
                  .map(Announcement.fromDoc)
                  .where((a) => _isVisibleForTeacher(a.target, classes))
                  .take(3)
                  .toList(growable: false);
            },
            orElse: () => const <Announcement>[],
          );

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              SchoolBrandBanner(
                schoolName: schoolName,
                subtitle: teacherName.isEmpty ? 'Teacher' : teacherName,
                primary: branding.primaryColor,
                secondary: branding.secondaryColor,
                logoUrl: logoUrl,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Recent Announcements',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TeacherAnnouncementsScreen(),
                                ),
                              );
                            },
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      announcementsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          'Failed to load announcements: $e',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        data: (_) {
                          if (visibleAnnouncements.isEmpty) {
                            return const Text(
                              'No announcements yet.',
                              style: TextStyle(color: Colors.black54),
                            );
                          }

                          return Column(
                            children: [
                              for (final a in visibleAnnouncements)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.campaign_rounded),
                                  title: Text(
                                    a.title.trim().isEmpty
                                        ? '(Untitled)'
                                        : a.title.trim(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                            AnnouncementDetailScreen(
                                          announcement: a,
                                        ),
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
              ),
              const SizedBox(height: 12),
              const Text(
                'My Classes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final classData in classes)
                if (classData is Map)
                  Builder(
                    builder: (context) {
                      final classId = (classData['classId'] ?? '').toString();

                      // Backward/forward compatible section keys.
                      final section = (classData['section'] ??
                              classData['sectionId'] ??
                              classData['sectionName'] ??
                              '')
                          .toString();

                      final className =
                          (classData['className'] ?? '').toString();
                      final sectionName =
                          (classData['sectionName'] ?? '').toString();

                      final c = className.trim().isNotEmpty
                          ? className.trim()
                          : classId;
                      final s = sectionName.trim().isNotEmpty
                          ? sectionName.trim()
                          : section.trim();

                      return Card(
                        child: ListTile(
                          title: Text('Class $c${s.isEmpty ? '' : s}'),
                          trailing: PopupMenuButton<_TeacherClassAction>(
                            tooltip: 'Open',
                            onSelected: (action) {
                              if (action == _TeacherClassAction.attendance) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceScreen(
                                      classId: classId,
                                      section: section,
                                    ),
                                  ),
                                );
                              } else if (action == _TeacherClassAction.homework) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherHomeworkScreen(
                                      classId: classId,
                                      sectionId: section,
                                    ),
                                  ),
                                );
                              } else if (action == _TeacherClassAction.exams) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherExamsScreen(
                                      classId: classId,
                                      sectionId: section,
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: _TeacherClassAction.attendance,
                                child: Text('Attendance'),
                              ),
                              PopupMenuItem(
                                value: _TeacherClassAction.homework,
                                child: Text('Homework'),
                              ),
                              PopupMenuItem(
                                value: _TeacherClassAction.exams,
                                child: Text('Exams & Results'),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceScreen(
                                  classId: classId,
                                  section: section,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

enum _TeacherClassAction { attendance, homework, exams }

bool _isVisibleForTeacher(String target, List classes) {
  final t = target.trim();
  if (t == 'all') return true;
  if (t == 'teachers') return true;

  if (!t.startsWith('class_')) return false;
  final parsed = _parseClassTarget(t);
  if (parsed == null) return false;
  final (classId, sectionId) = parsed;

  for (final item in classes) {
    if (item is! Map) continue;
    final cId = (item['classId'] ?? '').toString().trim();
    final sId = (item['sectionId'] ?? item['section'] ?? '').toString().trim();
    if (cId == classId && sId == sectionId) return true;
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
