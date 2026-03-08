// features/school_admin/attendance/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFF2F8FF);
    const accent = Color(0xFF3B82F6);
    final attendanceAsync = ref.watch(attendanceProvider);

    return AdminLayout(
      title: 'Attendance',
      body: _AttendanceBody(
        lightBg: lightBg,
        accent: accent,
        attendanceAsync: attendanceAsync,
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({
    required this.lightBg,
    required this.accent,
    required this.attendanceAsync,
  });

  final Color lightBg;
  final Color accent;
  final AsyncValue attendanceAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withAlpha(71)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withAlpha(41),
                    child: Icon(Icons.fact_check_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Attendance summary for present, absent, and late trends.',
                      style: TextStyle(height: 1.4, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            attendanceAsync.when(
              data: (snapshot) {
                final records = snapshot.docs;
                final totalRecords = records.length;
                final recentRecords = records.take(3).toList();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total Records',
                            '$totalRecords',
                            Icons.check_circle_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'This Week',
                            '${(totalRecords * 0.2).round()}',
                            Icons.calendar_today_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Attendance Logs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recentRecords.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No attendance records yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...recentRecords.map((doc) {
                              final data = doc.data();
                              final className =
                                  data['className'] ?? data['class'] ?? 'Class';
                              final date = data['date'] ?? 'Recent';
                              final info = data['info'] ?? 'Attendance marked';
                              return _listRow(
                                className,
                                '$info • $date',
                                Icons.trending_up_rounded,
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              ),
              error: (e, _) =>
                  Center(child: Text('Error loading attendance: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _listRow(String name, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
