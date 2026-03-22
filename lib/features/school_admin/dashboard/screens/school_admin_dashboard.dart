import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  Color _hexToColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF3B82F6;
    return Color(value);
  }

  List<Color> _getGradientColors(List<dynamic>? colorList) {
    if (colorList == null || colorList.isEmpty) {
      return [const Color(0xFF2563EB), const Color(0xFF7C3AED)];
    }
    return colorList.map((c) => _hexToColor(c.toString())).toList();
  }

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

  String? _readLogoUrl(Map<String, dynamic> data) {
    final logo =
        (data['logoUrl'] ?? data['schoolLogo'] ?? data['logo'] ?? '')
            .toString()
            .trim();
    return logo.isEmpty ? null : logo;
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

          final name = (schoolData['name'] ?? 'School').toString();
          final teachers = (schoolData['totalTeachers'] ?? 0).toString();
          final students = (schoolData['studentCount'] ?? 0).toString();
          final plan =
              (schoolData['subscriptionsStatus'] ?? 'Standard').toString();

          final gradientHex = _readCurrentThemeHex(schoolData);
          final colors = _getGradientColors(gradientHex);
          final primaryColor = colors.first;
          final logoUrl = _readLogoUrl(schoolData);

          final attendance = schoolData['attendanceLatest'] ?? {};
          final present = (attendance['present'] ?? 0) as int;
          final total = (attendance['total'] ?? 0) as int;

          final attendanceValue = total > 0
              ? '${((present / total) * 100).toStringAsFixed(0)}%'
              : '--';

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 700;
              final isDesktop = width >= 1100;

              final contentMaxWidth = isDesktop ? 1400.0 : width;
              final statAspectRatio = isDesktop ? 2.2 : 1.08;

              return Container(
                color: const Color(0xFFF4F7FB),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                isDesktop ? 8 : 0,
                                isDesktop ? 4 : 0,
                                isDesktop ? 8 : 0,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isDesktop ? 18 : 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colors.first.withOpacity(0.96),
                                          colors.last.withOpacity(0.92),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.first.withOpacity(0.16),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        _SchoolLogoBox(
                                          logoUrl: logoUrl,
                                          primaryColor: primaryColor,
                                          isMobile: isMobile,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 6,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    'Welcome back',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.88),
                                                      fontSize: isDesktop ? 12 : 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.16),
                                                      borderRadius:
                                                          BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      plan,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isDesktop ? 22 : 17,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.count(
                                    shrinkWrap: true,
                                    crossAxisCount: isDesktop ? 4 : 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: statAspectRatio,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      _statCard(
                                        title: 'Teachers',
                                        value: teachers,
                                        icon: Icons.badge_rounded,
                                        gradient: const [
                                          Color(0xFF2563EB),
                                          Color(0xFF06B6D4),
                                        ],
                                      ),
                                      _statCard(
                                        title: 'Students',
                                        value: students,
                                        icon: Icons.groups_rounded,
                                        gradient: const [
                                          Color(0xFF8B5CF6),
                                          Color(0xFFEC4899),
                                        ],
                                      ),
                                      _statCard(
                                        title: 'Attendance',
                                        value: attendanceValue,
                                        icon: Icons.fact_check_rounded,
                                        gradient: const [
                                          Color(0xFF10B981),
                                          Color(0xFF22C55E),
                                        ],
                                      ),
                                      _statCard(
                                        title: 'Classes',
                                        value: '--',
                                        icon: Icons.meeting_room_rounded,
                                        gradient: const [
                                          Color(0xFFF59E0B),
                                          Color(0xFFF97316),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFE5EAF2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF2563EB),
                                                Color(0xFF7C3AED),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.dashboard_customize_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Quick overview',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Manage teachers, students, attendance, exams, homework and reports from one place.',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.45,
                                                  color: Color(0xFF667085),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Text(
                              'Copyright © 2026 SK School Master. All rights reserved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _SchoolLogoBox extends StatelessWidget {
  const _SchoolLogoBox({
    required this.logoUrl,
    required this.primaryColor,
    required this.isMobile,
  });

  final String? logoUrl;
  final Color primaryColor;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final boxSize = isMobile ? 52.0 : 58.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.school,
                color: primaryColor,
                size: isMobile ? 26 : 28,
              ),
            )
          : Icon(
              Icons.school,
              color: primaryColor,
              size: isMobile ? 26 : 28,
            ),
    );
  }
}