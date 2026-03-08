import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/features/school_admin/analytics/models/student_risk.dart';

/// Stream of the school-level risk summary doc:
/// schools/{schoolId}/analytics/risk_summary
final riskSummaryProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) async* {
    final schoolId = await ref.watch(schoolIdProvider.future);

    yield* FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('analytics')
        .doc('risk_summary')
        .snapshots();
  },
);

/// Which list does the analytics screen want to show?
enum RiskListFilter {
  highRisk,
  feeDefaulters,
  lowAttendance,
  topPerformers,
}

extension RiskListFilterX on RiskListFilter {
  String get label {
    switch (this) {
      case RiskListFilter.highRisk:
        return 'Students at Risk';
      case RiskListFilter.feeDefaulters:
        return 'Fee Defaulters';
      case RiskListFilter.lowAttendance:
        return 'Low Attendance';
      case RiskListFilter.topPerformers:
        return 'Top Performers';
    }
  }

  String get routeKey {
    switch (this) {
      case RiskListFilter.highRisk:
        return 'high-risk';
      case RiskListFilter.feeDefaulters:
        return 'fee-defaulters';
      case RiskListFilter.lowAttendance:
        return 'low-attendance';
      case RiskListFilter.topPerformers:
        return 'top-performers';
    }
  }

  static RiskListFilter? fromRouteKey(String key) {
    switch (key) {
      case 'high-risk':
        return RiskListFilter.highRisk;
      case 'fee-defaulters':
        return RiskListFilter.feeDefaulters;
      case 'low-attendance':
        return RiskListFilter.lowAttendance;
      case 'top-performers':
        return RiskListFilter.topPerformers;
      default:
        return null;
    }
  }
}

/// Query student risk docs based on a filter.
///
/// Source: schools/{schoolId}/analytics/student_risk/students/*
final studentRiskListProvider = StreamProvider.autoDispose
    .family<List<StudentRisk>, RiskListFilter>((ref, filter) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  Query<Map<String, dynamic>> q = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('analytics')
      .doc('student_risk')
      .collection('students');

  switch (filter) {
    case RiskListFilter.highRisk:
      q = q.where('riskLevel', isEqualTo: 'HIGH');
      break;
    case RiskListFilter.feeDefaulters:
      q = q.where('feePending', isEqualTo: true);
      break;
    case RiskListFilter.lowAttendance:
      q = q.where('lowAttendance', isEqualTo: true);
      break;
    case RiskListFilter.topPerformers:
      q = q.where('topPerformer', isEqualTo: true);
      break;
  }

  // Avoid composite-index requirements: no orderBy with where.
  // We'll sort client-side by riskScore.
  yield* q.limit(400).snapshots().map((snap) {
    final list = snap.docs.map(StudentRisk.fromDoc).toList(growable: false);
    final sorted = list.toList()..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return sorted;
  });
});

/// Teacher-friendly query by classKey (no orderBy to avoid indexes).
final studentRiskByClassKeyProvider = StreamProvider.autoDispose
    .family<List<StudentRisk>, String>((ref, classKey) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  final q = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('analytics')
      .doc('student_risk')
      .collection('students')
      .where('classKey', isEqualTo: classKey)
      .limit(600);

  yield* q.snapshots().map((snap) {
    final list = snap.docs.map(StudentRisk.fromDoc).toList(growable: false);
    final sorted = list.toList()..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return sorted;
  });
});

class AttendanceDailyPoint {
  const AttendanceDailyPoint({
    required this.dateKey,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.total,
  });

  final String dateKey; // YYYY-MM-DD
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int total;

  int get presentEquivalent => present + late + leave;
  double get percent => total <= 0 ? 0 : (presentEquivalent / total) * 100;
}

/// Last N days attendance totals (school-level), written by Cloud Functions.
///
/// Path: schools/{schoolId}/analytics/attendance_daily/days/{dateKey}
final attendanceDailyTrendProvider = StreamProvider.autoDispose
    .family<List<AttendanceDailyPoint>, int>((ref, days) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  final q = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('analytics')
      .doc('attendance_daily')
      .collection('days')
      .orderBy('dateKey', descending: true)
      .limit(days.clamp(1, 120));

  int readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  yield* q.snapshots().map((snap) {
    final list = <AttendanceDailyPoint>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final dateKey = (data['dateKey'] ?? doc.id).toString();
      list.add(
        AttendanceDailyPoint(
          dateKey: dateKey,
          present: readInt(data['present']),
          absent: readInt(data['absent']),
          late: readInt(data['late']),
          leave: readInt(data['leave']),
          total: readInt(data['total']),
        ),
      );
    }

    // q is newest-first; UI expects oldest-first for charts.
    return list.reversed.toList(growable: false);
  });
});
