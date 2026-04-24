import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/analytics/providers/analytics_provider.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(
      analyticsProvider,
    );

    return AdminLayout(
      title: 'Dashboard',
      body: analyticsAsync.when(
        data: (data) {
          final students =
              (data['students'] ?? 0)
                  .toString();

          final totalFees =
              (data['totalFees'] ?? 0)
                  .toString();

          final paidFees =
              (data['paidFees'] ?? 0)
                  .toString();

          final pendingFees =
              (data['pendingFees'] ?? 0)
                  .toString();

          final paidY =
              (data['paidFees'] is num)
                  ? (data['paidFees']
                          as num)
                      .toDouble()
                  : 0.0;

          final pendingY =
              (data['pendingFees']
                      is num)
                  ? (data['pendingFees']
                          as num)
                      .toDouble()
                  : 0.0;

          return LayoutBuilder(
            builder:
                (context, box) {
              final mobile =
                  box.maxWidth <
                      760;

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _heroHeader(),

                    const SizedBox(
                      height: 18,
                    ),

                    GridView.count(
                      crossAxisCount:
                          mobile
                              ? 2
                              : 4,
                      crossAxisSpacing:
                          14,
                      mainAxisSpacing:
                          14,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      childAspectRatio:
                          mobile
                              ? 1.25
                              : 1.45,
                      children: [
                        _metricCard(
                          title:
                              'Students',
                          value:
                              students,
                          icon:
                              Icons.groups_rounded,
                          start:
                              const Color(
                            0xFF3B82F6,
                          ),
                          end:
                              const Color(
                            0xFF2563EB,
                          ),
                        ),
                        _metricCard(
                          title:
                              'Total Fees',
                          value:
                              '₹$totalFees',
                          icon:
                              Icons.account_balance_wallet_rounded,
                          start:
                              const Color(
                            0xFF111827,
                          ),
                          end:
                              const Color(
                            0xFF374151,
                          ),
                        ),
                        _metricCard(
                          title:
                              'Collected',
                          value:
                              '₹$paidFees',
                          icon:
                              Icons.check_circle_rounded,
                          start:
                              const Color(
                            0xFF10B981,
                          ),
                          end:
                              const Color(
                            0xFF059669,
                          ),
                        ),
                        _metricCard(
                          title:
                              'Pending',
                          value:
                              '₹$pendingFees',
                          icon:
                              Icons.pending_actions_rounded,
                          start:
                              const Color(
                            0xFFEF4444,
                          ),
                          end:
                              const Color(
                            0xFFDC2626,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    mobile
                        ? Column(
                            children: [
                              _feesChartCard(
                                paidY:
                                    paidY,
                                pendingY:
                                    pendingY,
                              ),
                              const SizedBox(
                                height:
                                    14,
                              ),
                              _quickActions(
                                  context),
                            ],
                          )
                        : Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child:
                                    _feesChartCard(
                                  paidY:
                                      paidY,
                                  pendingY:
                                      pendingY,
                                ),
                              ),
                              const SizedBox(
                                width:
                                    14,
                              ),
                              Expanded(
                                child:
                                    _quickActions(
                                  context,
                                ),
                              ),
                            ],
                          ),

                    const SizedBox(
                      height: 18,
                    ),

                    _activityCard(),
                  ],
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (e, _) =>
            Center(
          child: Text(
            'Error: $e',
          ),
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF2563EB),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x224F46E5,
            ),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            'Welcome Back 👋',
            style: TextStyle(
              color:
                  Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'School Dashboard',
            style: TextStyle(
              color:
                  Colors.white,
              fontSize: 26,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track students, fees and daily activity in one place.',
            style: TextStyle(
              color:
                  Colors.white70,
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
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              gradient:
                  LinearGradient(
                colors: [
                  start,
                  end,
                ],
              ),
            ),
            child: Icon(
              icon,
              color:
                  Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.w800,
              color: Color(
                0xFF111827,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 13,
              color: Color(
                0xFF6B7280,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feesChartCard({
    required double paidY,
    required double pendingY,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            'Fees Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF111827),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          const Text(
            'Collected vs pending fees',
            style: TextStyle(
              color:
                  Color(0xFF6B7280),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY:
                    (paidY >
                                pendingY
                            ? paidY
                            : pendingY) *
                        1.2 +
                    1,
                gridData:
                    FlGridData(
                  show: true,
                  drawVerticalLine:
                      false,
                ),
                borderData:
                    FlBorderData(
                  show: false,
                ),
                titlesData:
                    FlTitlesData(
                  topTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles:
                          false,
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles:
                          false,
                    ),
                  ),
                  bottomTitles:
                      AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles:
                          true,
                      getTitlesWidget:
                          (
                        value,
                        meta,
                      ) {
                        if (value ==
                            0) {
                          return const Padding(
                            padding:
                                EdgeInsets.only(
                              top:
                                  8,
                            ),
                            child:
                                Text(
                              'Paid',
                            ),
                          );
                        }

                        if (value ==
                            1) {
                          return const Padding(
                            padding:
                                EdgeInsets.only(
                              top:
                                  8,
                            ),
                            child:
                                Text(
                              'Pending',
                            ),
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: paidY,
                        width:
                            28,
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(
                              0xFF10B981,
                            ),
                            Color(
                              0xFF059669,
                            ),
                          ],
                          begin:
                              Alignment.topCenter,
                          end:
                              Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY:
                            pendingY,
                        width:
                            28,
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(
                              0xFFEF4444,
                            ),
                            Color(
                              0xFFDC2626,
                            ),
                          ],
                          begin:
                              Alignment.topCenter,
                          end:
                              Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          _actionTile(
            icon:
                Icons.person_add_alt_1,
            title:
                'Add Student',
            onTap: () {
              context.push(
                '/add-student',
              );
            },
          ),
          _actionTile(
            icon:
                Icons.groups_rounded,
            title:
                'Manage Students',
            onTap: () {
              context.push(
                '/students',
              );
            },
          ),
          _actionTile(
            icon:
                Icons.analytics_rounded,
            title:
                'Analytics',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color: const Color(
                  0xFFF1F5F9,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color: const Color(
                  0xFF2563EB,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '• 12 fee payments collected today',
          ),
          SizedBox(height: 8),
          Text(
            '• 3 new student admissions added',
          ),
          SizedBox(height: 8),
          Text(
            '• Attendance marked for Class 8',
          ),
        ],
      ),
    );
  }
}