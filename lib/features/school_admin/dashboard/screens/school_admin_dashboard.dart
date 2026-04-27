// FILE: lib/features/school_admin/dashboard/screens/school_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/analytics/providers/analytics_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return AdminLayout(
      title: 'Dashboard',
      body: analyticsAsync.when(
        data: (data) {
          final students = (data['students'] ?? 0).toString();
          final totalFees = (data['totalFees'] ?? 0).toString();
          final paidFees = (data['paidFees'] ?? 0).toString();
          final pendingFees = (data['pendingFees'] ?? 0).toString();

          final paidY = (data['paidFees'] is num)
              ? (data['paidFees'] as num).toDouble()
              : 0.0;

          final pendingY = (data['pendingFees'] is num)
              ? (data['pendingFees'] as num).toDouble()
              : 0.0;

          return LayoutBuilder(
            builder: (context, box) {
              final mobile = box.maxWidth < 760;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroHeader(),
                    const SizedBox(height: 18),

                    GridView.count(
                      crossAxisCount: mobile ? 2 : 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      childAspectRatio:
                          mobile ? 1.20 : 1.45,
                      children: [
                        _metricCard(
                          title: 'Students',
                          value: students,
                          icon: Icons.groups_rounded,
                          start: const Color(0xFF3B82F6),
                          end: const Color(0xFF2563EB),
                        ),
                        _metricCard(
                          title: 'Total Fees',
                          value: '₹$totalFees',
                          icon: Icons.account_balance_wallet_rounded,
                          start: const Color(0xFF111827),
                          end: const Color(0xFF374151),
                        ),
                        _metricCard(
                          title: 'Collected',
                          value: '₹$paidFees',
                          icon: Icons.check_circle_rounded,
                          start: const Color(0xFF10B981),
                          end: const Color(0xFF059669),
                        ),
                        _metricCard(
                          title: 'Pending',
                          value: '₹$pendingFees',
                          icon: Icons.pending_actions_rounded,
                          start: const Color(0xFFEF4444),
                          end: const Color(0xFFDC2626),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    mobile
                        ? Column(
                            children: [
                              _feesChartCard(
                                paidY: paidY,
                                pendingY: pendingY,
                              ),
                              const SizedBox(height: 14),
                              _quickActions(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _feesChartCard(
                                  paidY: paidY,
                                  pendingY: pendingY,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _quickActions(),
                              ),
                            ],
                          ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back 👋',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'School Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track students, fees and daily activity in one place.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color start,
    required Color end,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [start, end],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _feesChartCard({
    required double paidY,
    required double pendingY,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            maxY: (paidY > pendingY ? paidY : pendingY) + 10,
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: paidY,
                    width: 28,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: pendingY,
                    width: 28,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _tile(Icons.person_add, 'Add Student'),
          _tile(Icons.groups, 'Manage Students'),
          _tile(Icons.analytics, 'Analytics'),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}