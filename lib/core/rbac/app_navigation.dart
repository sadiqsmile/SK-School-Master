import 'package:flutter/material.dart';

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
      case UserRole.unknown:
        return 'User';
    }
  }

  /// Drawer entries for a given role.
  ///
  /// Note: Teacher and Parent currently use dedicated UIs (dashboard / bottom
  /// navigation). This list primarily powers the School Admin drawer today.
  static List<AppNavEntry> drawerEntriesFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          AppNavEntry.item(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            route: '/school-admin',
          ),
          AppNavEntry.item(
            label: 'Teachers',
            icon: Icons.school_rounded,
            route: '/school-admin/teachers',
          ),
          AppNavEntry.item(
            label: 'Students',
            icon: Icons.groups_rounded,
            route: '/school-admin/students',
          ),
          AppNavEntry.item(
            label: 'Classes',
            icon: Icons.class_rounded,
            route: '/classes',
          ),
          AppNavEntry.item(
            label: 'Attendance',
            icon: Icons.fact_check_rounded,
            route: '/school-admin/attendance',
          ),
          AppNavEntry.item(
            label: 'Homework',
            icon: Icons.menu_book_rounded,
            route: '/school-admin/homework',
          ),
          AppNavEntry.item(
            label: 'Fees',
            icon: Icons.payments_rounded,
            route: '/school-admin/fees',
          ),
          AppNavEntry.item(
            label: 'Announcements',
            icon: Icons.campaign_rounded,
            route: '/school-admin/announcements',
          ),
          AppNavEntry.item(
            label: 'Exam Types',
            icon: Icons.category_rounded,
            route: '/school-admin/exam-types',
          ),
          AppNavEntry.item(
            label: 'Reports',
            icon: Icons.bar_chart_rounded,
            route: '/school-admin/reports',
          ),
          AppNavEntry.item(
            label: 'Analytics',
            icon: Icons.analytics_rounded,
            route: '/school-admin/analytics',
          ),
          AppNavEntry.header('Academic Management'),
          AppNavEntry.item(
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

      // Teacher/Parent: no drawer by default (their shells use other patterns).
      case UserRole.teacher:
      case UserRole.parent:
      case UserRole.unknown:
        return const [];
    }
  }
}
