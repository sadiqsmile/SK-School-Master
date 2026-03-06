// features/school_admin/layout/sidebar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'School Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.dashboard_rounded,
              color: Color(0xFF1E40AF),
            ),
            title: const Text('Dashboard'),
            onTap: () => context.go('/school-admin'),
          ),
          ListTile(
            leading: const Icon(Icons.school_rounded, color: Color(0xFF1E40AF)),
            title: const Text('Teachers'),
            onTap: () => context.go('/school-admin/teachers'),
          ),
          ListTile(
            leading: const Icon(Icons.groups_rounded, color: Color(0xFF1E40AF)),
            title: const Text('Students'),
            onTap: () => context.go('/school-admin/students'),
          ),
          ListTile(
            leading: const Icon(Icons.class_rounded, color: Color(0xFF1E40AF)),
            title: const Text('Classes'),
            onTap: () => context.go('/classes'),
          ),
          ListTile(
            leading: const Icon(
              Icons.fact_check_rounded,
              color: Color(0xFF1E40AF),
            ),
            title: const Text('Attendance'),
            onTap: () => context.go('/school-admin/attendance'),
          ),
          ListTile(
            leading: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF1E40AF),
            ),
            title: const Text('Homework'),
            onTap: () => context.go('/school-admin/homework'),
          ),
          ListTile(
            leading: const Icon(
              Icons.payments_rounded,
              color: Color(0xFF1E40AF),
            ),
            title: const Text('Fees'),
            onTap: () => context.go('/school-admin/fees'),
          ),
        ],
      ),
    );
  }
}
