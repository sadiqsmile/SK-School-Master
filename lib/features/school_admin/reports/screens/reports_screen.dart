import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8FAFC);
    const accent = Color(0xFF7C3AED);

    return AdminLayout(
      title: 'Reports',
      body: Container(
        color: bg,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(
              accent: accent,
              title: 'School Reports',
              subtitle:
                  'Turn your attendance, fees, homework, and exams into clear summaries for decision-making.',
            ),
            const SizedBox(height: 12),
            _ReportTile(
              accent: accent,
              title: 'Attendance Reports',
              subtitle: 'Daily + date-range summaries and monthly insights.',
              icon: Icons.fact_check_rounded,
              onTap: () => context.go('/school-admin/reports/attendance'),
            ),
            _ReportTile(
              accent: accent,
              title: 'Fee Reports',
              subtitle: 'Collected vs pending, with class/section breakdowns.',
              icon: Icons.payments_rounded,
              onTap: () => context.go('/school-admin/reports/fees'),
            ),
            _ReportTile(
              accent: accent,
              title: 'Exam Reports',
              subtitle: 'Top students, subject averages, and pass percentage.',
              icon: Icons.auto_graph_rounded,
              onTap: () => context.go('/school-admin/reports/exams'),
            ),
            _ReportTile(
              accent: accent,
              title: 'Student Reports',
              subtitle:
                  'One student view: attendance, fees, homework, and latest exam grade.',
              icon: Icons.person_search_rounded,
              onTap: () => context.go('/school-admin/reports/students'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tip: start with a class & section, then select a date range.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withAlpha(28),
            child: Icon(Icons.bar_chart_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    height: 1.4,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.withAlpha(24),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
