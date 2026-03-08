import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';

class SchoolAnalyticsScreen extends ConsumerWidget {
  const SchoolAnalyticsScreen({super.key});

  int _readInt(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFFF8FAFC);
    const accent = Color(0xFF0EA5E9);

    final summaryAsync = ref.watch(riskSummaryProvider);
    final attendanceTrendAsync = ref.watch(attendanceDailyTrendProvider(30));

    return AdminLayout(
      title: 'School Analytics',
      body: Container(
        color: bg,
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load analytics: $e')),
          data: (doc) {
            final data = doc.data() ?? const <String, dynamic>{};

            final high = _readInt(data, 'studentsHighRisk');
            final medium = _readInt(data, 'studentsMediumRisk');
            final low = _readInt(data, 'studentsLowRisk');
            final fee = _readInt(data, 'feeDefaulters');
            final lowAtt = _readInt(data, 'lowAttendance');
            final top = _readInt(data, 'topPerformers');

            Widget card({
              required String title,
              required int value,
              required IconData icon,
              required RiskListFilter filter,
              String? subtitle,
              Color? color,
            }) {
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (color ?? accent).withAlpha(30),
                    child: Icon(icon, color: color ?? accent),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: subtitle == null ? null : Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => context.push('/school-admin/analytics/${filter.routeKey}'),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Insights',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 12),

                _RiskDistributionCard(
                  low: low,
                  medium: medium,
                  high: high,
                ),
                const SizedBox(height: 12),

                _AttendanceTrendCard(trendAsync: attendanceTrendAsync),
                const SizedBox(height: 12),

                card(
                  title: 'Students at Risk',
                  value: high,
                  icon: Icons.warning_amber_rounded,
                  filter: RiskListFilter.highRisk,
                  subtitle: 'High risk (2+ conditions) — tap to view list',
                  color: const Color(0xFFEF4444),
                ),
                card(
                  title: 'Fee Defaulters',
                  value: fee,
                  icon: Icons.payments_rounded,
                  filter: RiskListFilter.feeDefaulters,
                  subtitle: 'Pending amount > 0 (v1 — overdue logic can be added when due dates exist)',
                  color: const Color(0xFFF59E0B),
                ),
                card(
                  title: 'Low Attendance',
                  value: lowAtt,
                  icon: Icons.fact_check_rounded,
                  filter: RiskListFilter.lowAttendance,
                  subtitle: 'Attendance < 75% in last 30 marked days',
                  color: const Color(0xFF8B5CF6),
                ),
                card(
                  title: 'Top Performers',
                  value: top,
                  icon: Icons.emoji_events_rounded,
                  filter: RiskListFilter.topPerformers,
                  subtitle: 'Marks ≥ 80% and Attendance ≥ 90%',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Tip: If this is your first time opening Analytics, run “Recompute Student Risk” from Super Admin → Maintenance to backfill existing data.',
                    style: TextStyle(color: Color(0xFF475569), height: 1.35),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RiskDistributionCard extends StatelessWidget {
  const _RiskDistributionCard({
    required this.low,
    required this.medium,
    required this.high,
  });

  final int low;
  final int medium;
  final int high;

  @override
  Widget build(BuildContext context) {
    final total = (low + medium + high);

    double pct(int v) => total <= 0 ? 0 : (v / total);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Risk Distribution',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (pct(low) * 1000).round().clamp(0, 1000),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                  Expanded(
                    flex: (pct(medium) * 1000).round().clamp(0, 1000),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                  Expanded(
                    flex: (pct(high) * 1000).round().clamp(0, 1000),
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
                  if (total == 0)
                    const Expanded(
                      flex: 1000,
                      child: ColoredBox(color: Color(0xFFE2E8F0)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legend(color: const Color(0xFF10B981), label: 'Low', value: low),
              _legend(color: const Color(0xFFF59E0B), label: 'Medium', value: medium),
              _legend(color: const Color(0xFFEF4444), label: 'High', value: high),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend({required Color color, required String label, required int value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}

class _AttendanceTrendCard extends StatelessWidget {
  const _AttendanceTrendCard({required this.trendAsync});

  final AsyncValue<List<AttendanceDailyPoint>> trendAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Trend (last 30 days)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          trendAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load trend: $e'),
            data: (points) {
              if (points.isEmpty) {
                return const Text(
                  'No daily attendance analytics yet.',
                  style: TextStyle(color: Color(0xFF64748B)),
                );
              }

                final values = points
                  .map((p) => p.percent.clamp(0, 100).toDouble())
                  .toList(growable: false);
              final last = points.last;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniSparkBars(values: values),
                  const SizedBox(height: 10),
                  Text(
                    'Latest: ${last.dateKey} • ${last.percent.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniSparkBars extends StatelessWidget {
  const _MiniSparkBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const height = 56.0;
    const barWidth = 4.0;
    const gap = 2.0;

    Color colorFor(double v) {
      if (v < 75) return const Color(0xFFEF4444);
      if (v < 90) return const Color(0xFFF59E0B);
      return const Color(0xFF10B981);
    }

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final v in values)
              Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Container(
                  width: barWidth,
                  height: (height * (v / 100)).clamp(2, height),
                  decoration: BoxDecoration(
                    color: colorFor(v),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
