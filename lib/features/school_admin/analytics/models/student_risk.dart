import 'package:cloud_firestore/cloud_firestore.dart';

/// Read model for: schools/{schoolId}/analytics/student_risk/students/{studentId}
class StudentRisk {
  const StudentRisk({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.sectionId,
    required this.classKey,
    required this.riskLevel,
    required this.riskScore,
    required this.attendancePercent30d,
    required this.attendanceMarkedDays30d,
    required this.marksPercentLatest,
    required this.feesPendingAmount,
    required this.lowAttendance,
    required this.lowMarks,
    required this.feePending,
    required this.topPerformer,
  });

  final String studentId;
  final String studentName;
  final String classId;
  final String sectionId;
  final String classKey;

  /// LOW | MEDIUM | HIGH
  final String riskLevel;
  final int riskScore;

  final double attendancePercent30d;
  final int attendanceMarkedDays30d;
  final double marksPercentLatest;
  final num feesPendingAmount;

  final bool lowAttendance;
  final bool lowMarks;
  final bool feePending;
  final bool topPerformer;

  static StudentRisk fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    double readDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    num readNum(dynamic v) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    final studentId = (data['studentId'] ?? doc.id).toString();

    return StudentRisk(
      studentId: studentId,
      studentName: (data['studentName'] ?? '').toString(),
      classId: (data['classId'] ?? '').toString(),
      sectionId: (data['sectionId'] ?? '').toString(),
      classKey: (data['classKey'] ?? '').toString(),
      riskLevel: (data['riskLevel'] ?? 'LOW').toString(),
      riskScore: readInt(data['riskScore']),
      attendancePercent30d: readDouble(data['attendancePercent30d']),
      attendanceMarkedDays30d: readInt(data['attendanceMarkedDays30d']),
      marksPercentLatest: readDouble(data['marksPercentLatest']),
      feesPendingAmount: readNum(data['feesPendingAmount']),
      lowAttendance: data['lowAttendance'] == true,
      lowMarks: data['lowMarks'] == true,
      feePending: data['feePending'] == true,
      topPerformer: data['topPerformer'] == true,
    );
  }
}
