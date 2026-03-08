// features/school_admin/dashboard/screens/school_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/models/school_branding.dart';
import 'package:school_app/providers/school_branding_provider.dart';
import 'package:school_app/providers/school_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(schoolBrandingProvider).maybeWhen(
          data: (b) => b,
          orElse: () => SchoolBranding.defaults(),
        );

    final primaryBlue = branding.primaryColor;
    final accentCyan = branding.secondaryColor;
    const deepBlue = Color(0xFF1E40AF);
    final schoolAsync = ref.watch(schoolProvider);

    return AdminLayout(
      title: 'School Admin Dashboard',
      body: schoolAsync.when(
        data: (doc) {
          final schoolData = doc.data();
          if (schoolData == null) {
            return const Center(child: Text('School data not found'));
          }

          final name = (schoolData['name'] ?? 'School').toString();
          final schoolId = (schoolData['schoolId'] ?? '').toString();
          final plan = (schoolData['subscriptionPlan'] ?? '').toString();
          final teachers = (schoolData['totalTeachers'] ?? 0).toString();
          final students = (schoolData['totalStudents'] ?? 0).toString();

          final attendanceLatestRaw = schoolData['attendanceLatest'];
          final attendanceLatest = attendanceLatestRaw is Map
              ? Map<String, dynamic>.from(attendanceLatestRaw)
              : <String, dynamic>{};
          final latestKey =
              (attendanceLatest['dateKey'] ?? schoolData['attendanceLatestDateKey'] ?? '')
                  .toString();
          final present = (attendanceLatest['present'] is num)
              ? (attendanceLatest['present'] as num).toInt()
              : 0;
          final absent = (attendanceLatest['absent'] is num)
              ? (attendanceLatest['absent'] as num).toInt()
              : 0;
          final late = (attendanceLatest['late'] is num)
              ? (attendanceLatest['late'] as num).toInt()
              : 0;
          final leave = (attendanceLatest['leave'] is num)
              ? (attendanceLatest['leave'] as num).toInt()
              : 0;
          final total = (attendanceLatest['total'] is num)
              ? (attendanceLatest['total'] as num).toInt()
              : 0;
          final classesMarked = (attendanceLatest['classesMarked'] is num)
              ? (attendanceLatest['classesMarked'] as num).toInt()
              : 0;

          final hasAttendance = latestKey.isNotEmpty && total > 0;
          final attendanceValue =
              hasAttendance ? '${((present / total) * 100).toStringAsFixed(0)}%' : '—';
          final attendanceSubtitle = hasAttendance
              ? () {
                  final parts = <String>[
                    latestKey,
                    '$present present',
                    '$absent absent',
                    if (late > 0) '$late late',
                    if (leave > 0) '$leave leave',
                    '$classesMarked classes',
                  ];
                  return parts.join(' • ');
                }()
              : 'No attendance marked yet';

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBlue, accentCyan],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withAlpha(89),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.apartment_rounded,
                              color: deepBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'School ID: $schoolId',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Plan',
                            value: plan.isEmpty ? 'Standard' : plan,
                            icon: Icons.workspace_premium_rounded,
                            iconColor: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Teachers',
                            value: teachers,
                            icon: Icons.school_rounded,
                            iconColor: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Students',
                            value: students,
                            icon: Icons.groups_rounded,
                            iconColor: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Attendance',
                            value: attendanceValue,
                            subtitle: attendanceSubtitle,
                            icon: Icons.fact_check_rounded,
                            iconColor: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Use the drawer to manage teachers, students, classes, attendance, homework, and fees. This dashboard gives you quick access to your school administration tools.',
                            style: TextStyle(
                              height: 1.45,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Error: $e',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
