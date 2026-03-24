import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app/features/data_center/screens/data_center_screen.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
              ),
            ),
            child: const Align(
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.dashboard_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Dashboard'),
                  onTap: () => context.go('/school-admin'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Teachers'),
                  onTap: () => context.go('/school-admin/teachers'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Students'),
                  onTap: () => context.go('/school-admin/students'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.class_rounded,
                    color: Color(0xFF1E40AF),
                  ),
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
                ListTile(
                  leading: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Announcements'),
                  onTap: () => context.go('/school-admin/announcements'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.category_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Exam Types'),
                  onTap: () => context.go('/school-admin/exam-types'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Reports'),
                  onTap: () => context.go('/school-admin/reports'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Analytics'),
                  onTap: () => context.go('/school-admin/analytics'),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    'Academic Management',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF1E40AF),
                  ),
                  title: const Text('Promote Students'),
                  onTap: () => context.go('/school-admin/academic/promote'),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    'Data Tools',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  title: const Text('Data Center'),
                  subtitle: const Text(
                    'Import, Export & Sync',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataCenterScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 18,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => context.go('/'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}