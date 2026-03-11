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
  String _searchQuery = '';

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
    const accentGreen = Color(0xFF00B889);
    const textPrimary = Color(0xFF1F2937);
    final platformData = ref.watch(platformProvider);

    return platformData.when(
      data: (doc) {
        final data = doc.data() ?? <String, dynamic>{};
        final totalSchools = data['totalSchools'] ?? 0;
        final totalStudents = data['totalStudents'] ?? 0;
        final gradientColors = _readCurrentThemeHex(data);
        final applyToAll = (data['applyToAll'] ?? false) as bool;
        final colors = _getGradientColors(gradientColors);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'SUPER ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        // Keep navigation within GoRouter; pushing LoginScreen via
                        // Navigator can leave the app outside the router context on web.
                        context.go('/');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: colors,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 720;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(43),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withAlpha(82),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.school_rounded,
                                      color: accentGreen,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Welcome back! Manage schools and monitor the platform from one place.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
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
                        ),
                        const SizedBox(height: 16),
                        isCompact
                            ? Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) => const SafeArea(
                                            child: CreateSchoolScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 1,
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                      ),
                                      label: const Text(
                                        'Add School',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.push(
                                        '/super-admin/maintenance',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withAlpha(
                                          230,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 1,
                                      ),
                                      icon: const Icon(
                                        Icons.build_circle_outlined,
                                      ),
                                      label: const Text(
                                        'Maintenance',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                height: 52,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (context) =>
                                                const SafeArea(
                                                  child: CreateSchoolScreen(),
                                                ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF1E3A8A,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          elevation: 1,
                                        ),
                                        icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                        ),
                                        label: const Text(
                                          'Add School',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => context.push(
                                          '/super-admin/maintenance',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withAlpha(230),
                                          foregroundColor: const Color(
                                            0xFF1E3A8A,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          elevation: 1,
                                        ),
                                        icon: const Icon(
                                          Icons.build_circle_outlined,
                                        ),
                                        label: const Text(
                                          'Maintenance',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search schools by name...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF1E3A8A),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3A8A),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Schools',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 10),
                              RepaintBoundary(
                                child: SizedBox(
                                  height: 380,
                                  child: SchoolsScreen(
                                    searchQuery: _searchQuery,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const WebDashboardFooter(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: _getGradientColors(null),
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: _getGradientColors(null),
            ),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Error: $e',
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
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
}
