// features/super_admin/screens/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/providers/super_admin_provider.dart';
import 'package:school_app/providers/platform_status_provider.dart';
import 'create_school_screen.dart';
import 'schools_screen.dart';
import '../widgets/reset_school_data_sheet.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  Future<bool> _confirmEnableMaintenance(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Maintenance Mode?'),
        content: const Text(
          'This will block Admin/Teacher/Parent access and show “System under maintenance”.\n\nOnly Super Admin will be able to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryGreen = Color(0xFF00C896);
    const darkGreen = Color(0xFF00A876);
    final platformData = ref.watch(platformProvider);
    final maintenanceAsync = ref.watch(maintenanceModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryGreen, darkGreen],
          ),
        ),
        child: SafeArea(
          child: platformData.when(
            data: (doc) {
              final data = doc.data() ?? <String, dynamic>{};

              final totalSchools = data['totalSchools'] ?? 0;
              final totalStudents = data['totalStudents'] ?? 0;

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
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: primaryGreen,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Welcome back! Manage schools and monitor the platform from one place.',
                              style: TextStyle(
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
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Maintenance Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            maintenanceAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text(
                                'Failed to load status: $e',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              data: (enabled) {
                                return SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    enabled ? 'Enabled' : 'Disabled',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text(
                                    enabled
                                        ? 'All non-super-admin users are blocked.'
                                        : 'Normal app usage is allowed.',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  value: enabled,
                                  onChanged: (value) async {
                                    bool nextValue = value;
                                    if (value) {
                                      final ok = await _confirmEnableMaintenance(context);
                                      if (!ok) return;
                                      nextValue = true;
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('platform')
                                        .doc('status')
                                        .set(
                                      {
                                        'maintenanceMode': nextValue,
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      },
                                      SetOptions(merge: true),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Backup & Restore',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create a single-file database backup and restore later if needed.',
                              style: TextStyle(color: Colors.black54, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => context.go('/super-admin/backup-restore'),
                                icon: const Icon(Icons.backup_rounded),
                                label: const Text(
                                  'Open Backup & Restore',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Sheets Sync',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Export school data to a Google Spreadsheet (server-side, super-admin only).',
                              style: TextStyle(color: Colors.black54, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => context.go('/super-admin/google-sheets'),
                                icon: const Icon(Icons.table_view_rounded),
                                label: const Text(
                                  'Open Google Sheets Sync',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.red.withAlpha(46)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Danger Zone',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Reset a school\'s Firebase data. This is destructive and cannot be undone.',
                              style: TextStyle(color: Colors.black54, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (context) => const ResetSchoolDataSheet(),
                                  );
                                },
                                icon: const Icon(Icons.delete_forever_rounded),
                                label: const Text(
                                  'Reset School Data',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Expanded(
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
                                foregroundColor: darkGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 1,
                              ),
                              icon: const Icon(Icons.add_circle_outline_rounded),
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
                              onPressed: () => context.go('/super-admin/maintenance'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(230),
                                foregroundColor: darkGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 1,
                              ),
                              icon: const Icon(Icons.build_circle_outlined),
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schools',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(height: 380, child: SchoolsScreen()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Center(
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
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
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
          Icon(icon, color: const Color(0xFF00A876), size: 22),
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
