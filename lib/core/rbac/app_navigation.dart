import 'package:flutter/material.dart';

import 'package:school_app/models/school_modules.dart';
import 'package:school_app/models/user_role.dart';

/// A single navigation entry used to build role-based navigation.
///
/// - If [header] is non-null, the entry is rendered as a section header.
/// - Otherwise [label]/[icon]/[route] describe a clickable destination.
class AppNavEntry {
  const AppNavEntry.header(this.header)
      : label = null,
        icon = null,
        route = null;

  const AppNavEntry.item({
    required this.label,
    required this.icon,
    required this.route,
  }) : header = null;

  final String? header;
  final String? label;
  final IconData? icon;
  final String? route;

  bool get isHeader => header != null;
}

class AppNavigation {
  const AppNavigation._();

  static String roleTitle(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'School Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.parent:
        return 'Parent';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.unknown:
        return 'User';
    }
  }

  /// Drawer entries for a given role.
  static List<AppNavEntry> drawerEntriesFor(
    UserRole role, {
    SchoolModules? modules,
  }) {
    switch (role) {
      case UserRole.admin:
        final m = modules ?? SchoolModules.defaults();
        return [
          const AppNavEntry.item(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            route: '/school-admin',
          ),

          if (m.teachers)
            const AppNavEntry.item(
              label: 'Teachers',
              icon: Icons.school_rounded,
              route: '/school-admin/teachers',
            ),

          if (m.students)
            const AppNavEntry.item(
              label: 'Students',
              icon: Icons.groups_rounded,
              route: '/school-admin/students',
            ),

          if (m.students)
            const AppNavEntry.item(
              label: 'Classes',
              icon: Icons.class_rounded,
              route: '/classes',
            ),

          if (m.attendance)
            const AppNavEntry.item(
              label: 'Attendance',
              icon: Icons.fact_check_rounded,
              route: '/school-admin/attendance',
            ),

          if (m.homework)
            const AppNavEntry.item(
              label: 'Homework',
              icon: Icons.menu_book_rounded,
              route: '/school-admin/homework',
            ),

          if (m.fees)
            const AppNavEntry.item(
              label: 'Fees',
              icon: Icons.payments_rounded,
              route: '/school-admin/fees',
            ),

          if (m.messages)
            const AppNavEntry.item(
              label: 'Announcements',
              icon: Icons.campaign_rounded,
              route: '/school-admin/announcements',
            ),

          if (m.exams)
            const AppNavEntry.item(
              label: 'Exam Types',
              icon: Icons.category_rounded,
              route: '/school-admin/exam-types',
            ),

          if (m.exams)
            const AppNavEntry.item(
              label: 'Marks Card Templates',
              icon: Icons.description_rounded,
              route: '/school-admin/marks-card-templates',
            ),

          const AppNavEntry.item(
            label: 'Reports',
            icon: Icons.bar_chart_rounded,
            route: '/school-admin/reports',
          ),

          const AppNavEntry.item(
            label: 'Analytics',
            icon: Icons.analytics_rounded,
            route: '/school-admin/analytics',
          ),

          const AppNavEntry.header('Settings'),

          const AppNavEntry.item(
            label: 'Module Control',
            icon: Icons.tune_rounded,
            route: '/school-admin/settings/modules',
          ),

          const AppNavEntry.header('Academic Management'),

          if (m.students)
            const AppNavEntry.item(
              label: 'Promote Students',
              icon: Icons.trending_up_rounded,
              route: '/school-admin/academic/promote',
            ),
        ];

      case UserRole.superAdmin:
        return const [
          AppNavEntry.item(
            label: 'Dashboard',
            icon: Icons.admin_panel_settings_rounded,
            route: '/super-admin',
          ),
          AppNavEntry.item(
            label: 'Maintenance',
            icon: Icons.build_circle_outlined,
            route: '/super-admin/maintenance',
          ),
        ];

      case UserRole.teacher:
      case UserRole.parent:
      case UserRole.mentor:
      case UserRole.unknown:
        return const [];
    }
  }
}