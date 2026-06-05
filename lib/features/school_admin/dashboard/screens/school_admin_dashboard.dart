// FILE: lib/features/school_admin/dashboard/screens/school_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/dashboard/providers/dashboard_providers.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/settings/screens/admin_settings_screen.dart';



class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return AdminLayout(
  title: 'Dashboard',

  onSettingsPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminSettingsScreen(),
      ),
    );
  },



      body: schoolAsync.when(
        data: (school) {
          final schoolId = school.id;

          return LayoutBuilder(
            builder: (context, box) {
              final mobile = box.maxWidth < 760;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroHeader(),
                    const SizedBox(height: 18),

                    GridView.count(
                      crossAxisCount: mobile ? 2 : 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: mobile ? 1.20 : 1.45,
                      children: [
                        ref.watch(studentsCountProvider(schoolId)).when(
                          data: (count) => _metricCard(
                            title: 'Students',
                            value: count.toString(),
                            icon: Icons.groups_rounded,
                            start: const Color(0xFF3B82F6),
                            end: const Color(0xFF2563EB),
                          ),
                          loading: () => _loadingCard(),
                          error: (_, __) => _loadingCard(),
                        ),
                        ref.watch(teachersCountProvider(schoolId)).when(
                          data: (count) => _metricCard(
                            title: 'Teachers',
                            value: count.toString(),
                            icon: Icons.school_rounded,
                            start: const Color(0xFF8B5CF6),
                            end: const Color(0xFF7C3AED),
                          ),
                          loading: () => _loadingCard(),
                          error: (_, __) => _loadingCard(),
                        ),
                        ref.watch(todayAttendanceProvider(schoolId)).when(
                          data: (att) => _metricCard(
                            title: 'Today Present',
                            value: (att['present'] ?? 0).toString(),
                            icon: Icons.check_circle_rounded,
                            start: const Color(0xFF10B981),
                            end: const Color(0xFF059669),
                          ),
                          loading: () => _loadingCard(),
                          error: (_, __) => _loadingCard(),
                        ),
                        ref.watch(todayAttendanceProvider(schoolId)).when(
                          data: (att) => _metricCard(
                            title: 'Today Absent',
                            value: (att['absent'] ?? 0).toString(),
                            icon: Icons.cancel_rounded,
                            start: const Color(0xFFEF4444),
                            end: const Color(0xFFDC2626),
                          ),
                          loading: () => _loadingCard(),
                          error: (_, __) => _loadingCard(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    mobile
                        ? _quickActions(context, schoolId)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _quickActions(context, schoolId),
                              ),
                            ],
                          ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _heroHeader(),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.45,
                children: List.generate(
                  4,
                  (_) => _loadingCard(),
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back 👋',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'School Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track students, fees and daily activity in one place.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color start,
    required Color end,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [start, end],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, String schoolId) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _tile(
            context,
            Icons.person_add,
            'Add Student',
            () {
              Navigator.pushNamed(
                context,
                '/school-admin/students/add',
              );
            },
          ),
          _tile(
            context,
            Icons.groups,
            'Manage Students',
            () {
              Navigator.pushNamed(
                context,
                '/school-admin/students',
              );
            },
          ),
          _tile(
            context,
            Icons.analytics,
            'Analytics',
            () {
              Navigator.pushNamed(
                context,
                '/school-admin/analytics',
              );
            },
          ),
          _tile(
            context,
            Icons.account_tree_rounded,
            'Academic Setup',
            () {
              context.push(
                '/school-admin/academic-setup',
                extra: schoolId,  // passed from currentSchoolProvider data callback
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _strengthOverviewSection({
    required int nurseryCount,
    required int primaryCount,
    required int middleCount,
    required int highSchoolCount,
    required int collegeCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Strength Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _strengthCard(
                title: 'Nursery',
                count: nurseryCount,
                color: const Color(0xFFF59E0B),
                icon: Icons.child_care_rounded,
              ),
              _strengthCard(
                title: 'Primary',
                count: primaryCount,
                color: const Color(0xFF3B82F6),
                icon: Icons.menu_book_rounded,
              ),
              _strengthCard(
                title: 'Middle School',
                count: middleCount,
                color: const Color(0xFF10B981),
                icon: Icons.groups_rounded,
              ),
              _strengthCard(
                title: 'High School',
                count: highSchoolCount,
                color: const Color(0xFF8B5CF6),
                icon: Icons.school_rounded,
              ),
              _strengthCard(
                title: 'College',
                count: collegeCount,
                color: const Color(0xFFEF4444),
                icon: Icons.account_balance_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strengthCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}