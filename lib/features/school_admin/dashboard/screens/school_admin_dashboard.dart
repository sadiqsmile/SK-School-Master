import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/students/screens/student_list_screen.dart';
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

          final colors = _getGradientColors(
              schoolData['gradientColors'] ?? []);
          final primaryColor = colors.first;
          final logoUrl = _readLogoUrl(schoolData);

          return Container(
            color: const Color(0xFFF4F7FB),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                _SchoolLogoBox(
                                  logoUrl: logoUrl,
                                  primaryColor: primaryColor,
                                  isMobile: true,
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

                          // STATS
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  title: 'Teachers',
                                  value: teachers,
                                  icon: Icons.badge,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const StudentListScreen(),
                                        ),
                                    );
                                    
                                  },
                                  child: _statCard(
                                    title: 'Students',
                                    value: students,
                                    icon: Icons.groups,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // QUICK OVERVIEW
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick overview',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Manage teachers, students, attendance, exams, homework and reports.',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // BUTTON (optional)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentListScreen()
                                  ),
                                
                              );
                            },
                            child: const Text("Open Students"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18)),
              Text(title),
            ],
          )
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
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: logoUrl != null
          ? Image.network(logoUrl!, fit: BoxFit.cover)
          : Icon(Icons.school, color: primaryColor),
    );
  }
}