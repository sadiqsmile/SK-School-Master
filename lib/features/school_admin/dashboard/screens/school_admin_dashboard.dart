import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';

import 'package:school_app/features/school_admin/analytics/providers/analytics_provider.dart';

import 'package:fl_chart/fl_chart.dart';

class SchoolAdminDashboard extends ConsumerWidget {
  const SchoolAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return AdminLayout(
      title: 'Dashboard',
      body: analyticsAsync.when(
        data: (data) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                                            
                Row(
                  children: [
                    _card('Students', data['students'].toString(), Colors.blue),
                    _card('Total Fees', '₹${data['totalFees']}', Colors.black),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _card('Paid', '₹${data['paidFees']}', Colors.green),
                    _card('Pending', '₹${data['pendingFees']}', Colors.red),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  'Fees Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text('Paid');
                                case 1:
                                  return const Text('Pending');
                                default:
                                  return const Text('');
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                            toY: (data['paidFees'] is num) ? (data['paidFees'] as num).toDouble() : 0.0,
                            color: Colors.green,
                            width: 20,
                          )
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                            toY: (data['pendingFees'] is num) ? (data['pendingFees'] as num).toDouble() : 0.0,
                            color: Colors.red,
                            width: 20,
                          )
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },

        loading: () =>
            const Center(child: CircularProgressIndicator()),

        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _card(String title, String value, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}