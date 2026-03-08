import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/core/utils/firestore_keys.dart';
import 'package:school_app/features/school_admin/analytics/models/student_risk.dart';
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';

class ClassRiskScreen extends ConsumerWidget {
  const ClassRiskScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = classKeyFrom(classId, sectionId);
    final listAsync = ref.watch(studentRiskByClassKeyProvider(key));

    return Scaffold(
      appBar: AppBar(
        title: Text('Class Risk • $classId$sectionId'),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No risk data yet for this class.'));
          }

          String subtitle(StudentRisk r) {
            final parts = <String>[];
            if (r.attendanceMarkedDays30d > 0) {
              parts.add('Att ${r.attendancePercent30d.toStringAsFixed(0)}%');
            }
            if (r.marksPercentLatest > 0) {
              parts.add('Marks ${r.marksPercentLatest.toStringAsFixed(0)}%');
            }
            if (r.feesPendingAmount > 0) {
              parts.add('Fees ₹${r.feesPendingAmount.round()}');
            }
            return parts.join(' • ');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final r = items[i];
              final c = _riskColor(r.riskLevel);

              return Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.withAlpha(30),
                    child: Text(
                      r.riskLevel.substring(0, 1),
                      style: TextStyle(fontWeight: FontWeight.w900, color: c),
                    ),
                  ),
                  title: Text(
                    r.studentName.isEmpty ? r.studentId : r.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(subtitle(r)),
                  trailing: Text(
                    r.riskLevel,
                    style: TextStyle(color: c, fontWeight: FontWeight.w900),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
