import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';
import 'package:school_app/features/school_admin/analytics/models/student_risk.dart';

class StudentRiskListScreen extends ConsumerWidget {
  const StudentRiskListScreen({super.key, required this.filter});

  final RiskListFilter filter;

  Color _riskColor(String level) {
    switch (level) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _classLabel(StudentRisk r) {
    final c = r.classId.trim();
    final s = r.sectionId.trim();
    if (c.isEmpty && s.isEmpty) return '';
    if (s.isEmpty) return 'Class $c';
    return 'Class $c$s';
  }

  String _subtitle(StudentRisk r) {
    final parts = <String>[];
    if (r.attendanceMarkedDays30d > 0) {
      parts.add('Attendance ${r.attendancePercent30d.toStringAsFixed(0)}%');
    }
    if (r.marksPercentLatest > 0) {
      parts.add('Marks ${r.marksPercentLatest.toStringAsFixed(0)}%');
    }
    if (r.feesPendingAmount > 0) {
      parts.add('Fees ₹${r.feesPendingAmount.round()}');
    }
    final cls = _classLabel(r);
    if (cls.isNotEmpty) parts.insert(0, cls);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFFF8FAFC);

    final listAsync = ref.watch(studentRiskListProvider(filter));

    return AdminLayout(
      title: filter.label,
      body: Container(
        color: bg,
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed: $e')),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No students found for this filter.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final r = items[i];
                final color = _riskColor(r.riskLevel);

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withAlpha(30),
                      child: Text(
                        r.riskLevel.substring(0, 1),
                        style: TextStyle(fontWeight: FontWeight.w900, color: color),
                      ),
                    ),
                    title: Text(
                      r.studentName.isEmpty ? r.studentId : r.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(_subtitle(r)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          r.riskLevel,
                          style: TextStyle(color: color, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Score ${r.riskScore}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
