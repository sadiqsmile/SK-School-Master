// features/super_admin/screens/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/providers/super_admin_provider.dart';
import 'package:school_app/core/widgets/web_dashboard_footer.dart';
import 'create_school_screen.dart';
import 'schools_screen.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  final String _searchQuery = '';

  // State for selected school
  String? _selectedSchoolId;
  final bool _isArchiveMode = false;

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static const List<Map<String, dynamic>> _gradientPalettes = [
    {
      'name': 'Ocean Wave',
      'colors': ['#06B6D4', '#3B82F6', '#1E40AF'],
    },
    {
      'name': 'Sunset Blaze',
      'colors': ['#F59E0B', '#EC4899', '#8B5CF6'],
    },
    {
      'name': 'Forest Fresh',
      'colors': ['#10B981', '#14B8A6', '#06B6D4'],
    },
    {
      'name': 'Royal Purple',
      'colors': ['#8B5CF6', '#A855F7', '#EC4899'],
    },
    {
      'name': 'Fire Flame',
      'colors': ['#EF4444', '#F97316', '#F59E0B'],
    },
    {
      'name': 'Cool Mint',
      'colors': ['#14B8A6', '#10B981', '#84CC16'],
    },
    {
      'name': 'Night Sky',
      'colors': ['#1E3A8A', '#7C3AED', '#EC4899'],
    },
    {
      'name': 'Warm Sunset',
      'colors': ['#EC4899', '#FB923C', '#FDE047'],
    },
    {
      'name': 'Deep Ocean',
      'colors': ['#0891B2', '#3B82F6', '#6366F1'],
    },
    {
      'name': 'Tropical Paradise',
      'colors': ['#84CC16', '#14B8A6', '#0EA5E9'],
    },
  ];

  Color _hexToColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF1976D2;
    return Color(value);
  }

  List<Color> _getGradientColors(List<dynamic>? colorList) {
    if (colorList == null || colorList.isEmpty) {
      return [
        const Color(0xFF06B6D4),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
      ];
    }
    return colorList.map((c) => _hexToColor(c.toString())).toList();
  }

  List<String>? _readCurrentThemeHex(Map<String, dynamic> data) {
    final primary = (data['themeColorPrimary'] ?? '').toString().trim();
    final secondary = (data['themeColorSecondary'] ?? '').toString().trim();
    final tertiary = (data['themeColorTertiary'] ?? '').toString().trim();

    if (primary.isNotEmpty && secondary.isNotEmpty && tertiary.isNotEmpty) {
      return [primary, secondary, tertiary];
    }

    final legacy = data['gradientColors'];
    if (legacy is List) {
      return legacy.map((c) => c.toString()).toList();
    }
    return null;
  }

  Future<void> _openGradientPicker(
    BuildContext context,
    List<dynamic>? currentGradient,
    bool currentApplyToAll,
  ) async {
    bool applyToAll = currentApplyToAll;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Customize Dashboard Theme',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        value: applyToAll,
                        onChanged: (value) {
                          setState(() => applyToAll = value);
                        },
                        title: const Text(
                          'Apply to Everything',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          applyToAll
                              ? 'AppBar, cards, buttons & dashboard'
                              : 'Dashboard background only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        activeThumbColor: const Color(0xFF00A876),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Gradient',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_gradientPalettes.length, (index) {
                        final palette = _gradientPalettes[index];
                        final name = palette['name'] as String;
                        final colors = (palette['colors'] as List<String>)
                            .map(_hexToColor)
                            .toList();
                        final isCurrent =
                            currentGradient != null &&
                            currentGradient.length == colors.length &&
                            currentGradient.asMap().entries.every(
                              (entry) =>
                                  entry.value ==
                                  (palette['colors'] as List)[entry.key],
                            );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop({
                              'colors': palette['colors'],
                              'applyToAll': applyToAll,
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomRight,
                                  end: Alignment.topLeft,
                                  colors: colors,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.black87
                                      : Colors.grey[300]!,
                                  width: isCurrent ? 3 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final selected = (result['colors'] as List<dynamic>)
        .map((c) => c.toString())
        .toList(growable: false);

    await FirebaseFirestore.instance.collection('platform').doc('config').set({
      'themeColorPrimary': selected[0],
      'themeColorSecondary': selected[1],
      'themeColorTertiary': selected[2],
      'gradientColors': FieldValue.delete(),
      'applyToAll': result['applyToAll'],
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard theme updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Scaffold(
          backgroundColor: const Color(0xFFF3F8FC),
          drawer: isMobile ? Drawer(child: _buildSidebar(context, isMobile: true)) : null,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  _buildSidebar(context, isMobile: false),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopCards(),
                        const SizedBox(height: 24),
                        _buildCenterArea(),
                        const SizedBox(height: 24),
                        const WebDashboardFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
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
          Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isMobile}) {
    return Container(
      width: isMobile ? null : 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: const Text('Add School', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                // Add school logic
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('schools').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final school = docs[index].data() as Map<String, dynamic>;
                    final schoolId = docs[index].id;
                    final isSelected = _selectedSchoolId == schoolId;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isSelected ? Colors.white.withAlpha(40) : Colors.transparent,
                      leading: CircleAvatar(backgroundImage: NetworkImage(school['logoUrl'] ?? ''), backgroundColor: Colors.white),
                      title: Text(school['name'] ?? '', style: TextStyle(color: Colors.white)),
                      onTap: () => setState(() => _selectedSchoolId = schoolId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').snapshots(),
      builder: (context, snapshot) {
        int totalSchools = 0;
        int totalStudents = 0;
        if (snapshot.hasData) {
          totalSchools = snapshot.data!.docs.length;
          totalStudents = snapshot.data!.docs.fold(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + ((data['studentCount'] ?? 0) as int);
          });
        }
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Schools',
                value: '$totalSchools',
                icon: Icons.school_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Total Students',
                value: '$totalStudents',
                icon: Icons.groups_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCenterArea() {
    if (_selectedSchoolId == null) {
      return Center(
        child: Text('Select a school to view dashboard', style: TextStyle(fontSize: 18, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600)),
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(_selectedSchoolId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: CircularProgressIndicator());
        }
        final school = snapshot.data!.data() as Map<String, dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(school['logoUrl'] ?? ''),
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(school['name'] ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text('School ID: $_selectedSchoolId', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _actionCard('Manage Students', Icons.people_alt_rounded),
                _actionCard('Manage Teachers', Icons.person_rounded),
                _actionCard('Attendance', Icons.check_circle_rounded),
                _actionCard('Settings', Icons.settings_rounded),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _actionCard(String title, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          width: 180,
          height: 120,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A), fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolDetailsPanel(Map<String, dynamic> school) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(school['logoUrl'] ?? ''),
                radius: 28,
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 16),
              Text(
                school['name'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: Icon(Icons.archive_rounded),
                label: Text('Archive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {}, // Implement archive logic
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.email_rounded, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                'Admin Email: ${school['adminEmail'] ?? ''}',
                style: TextStyle(color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 24),
              Icon(Icons.login_rounded, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                'Last Login: ${school['lastLogin'] ?? ''}',
                style: TextStyle(color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.color_lens_rounded, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                'Theme Color Change',
                style: TextStyle(color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  }
  Widget _buildCalendar() {
    return Container(
      height: 320,
      margin: const EdgeInsets.only(top: 24),
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
      child: Center(
        child: Text(
          'Calendar Widget Coming Soon',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
// End of class
