// features/school_admin/dashboard/screens/school_admin_dashboard.dart
// features/school_admin/dashboard/screens/school_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/core/widgets/web_dashboard_footer.dart';
import 'package:school_app/providers/school_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  /// 🔥 SAFE HEX TO COLOR
  Color _hexToColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF3B82F6;
    return Color(value);
  }

  /// 🔥 SAFE GRADIENT
  List<Color> _getGradientColors(List<dynamic>? colorList) {
    if (colorList == null || colorList.isEmpty) {
      return [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)];
    }
    return colorList.map((c) => _hexToColor(c.toString())).toList();
  }

  /// 🔥 READ THEME SAFELY
  List<String>? _readCurrentThemeHex(Map<String, dynamic> data) {
    final primary = (data['themeColorPrimary'] ?? '').toString();
    final secondary = (data['themeColorSecondary'] ?? '').toString();

    if (primary.isNotEmpty && secondary.isNotEmpty) {
      return [primary, secondary];
    }

    final legacy = data['gradientColors'];
    if (legacy is List) {
      return legacy.map((c) => c.toString()).toList();
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(schoolProvider);

    return AdminLayout(
      title: 'Dashboard',
      body: schoolAsync.when(
        data: (doc) {
          final schoolData = doc.data();

          if (schoolData == null) {
            return const Center(child: Text('No data'));
          }

          /// 🔥 BASIC DATA
          final name = (schoolData['name'] ?? 'School').toString();
          final schoolId = (schoolData['schoolId'] ?? '').toString();

          final teachers =
              (schoolData['totalTeachers'] ?? 0).toString();

          /// ⚠️ FIXED FIELD (IMPORTANT)
          final students =
              (schoolData['studentCount'] ?? 0).toString();

          final plan =
              (schoolData['subscriptionsStatus'] ?? 'Standard').toString();

          /// 🎨 COLORS
          final gradientHex = _readCurrentThemeHex(schoolData);
          final colors = _getGradientColors(gradientHex);
          final primaryColor = colors.first;

          /// 📊 ATTENDANCE
          final attendance = schoolData['attendanceLatest'] ?? {};

          final present = (attendance['present'] ?? 0) as int;
          final total = (attendance['total'] ?? 0) as int;

          final attendanceValue =
              total > 0 ? "${((present / total) * 100).toStringAsFixed(0)}%" : "--";

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    /// 🔥 HEADER CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.school, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 🔥 STATS GRID
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [

                        _card("Plan", plan, Icons.workspace_premium, primaryColor),
                        _card("Teachers", teachers, Icons.school, primaryColor),
                        _card("Students", students, Icons.groups, primaryColor),
                        _card("Attendance", attendanceValue, Icons.bar_chart, primaryColor),

                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 INFO BOX
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Manage teachers, students, attendance, exams and more using the sidebar.",
                        style: TextStyle(color: Color(0xFF374151)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const WebDashboardFooter(),
                  ],
                ),
              ),
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(
          child: Text(
            "Error: $e",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  /// 🔥 CLEAN CARD
  Widget _card(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}