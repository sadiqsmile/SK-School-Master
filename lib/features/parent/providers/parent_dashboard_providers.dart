import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/announcement.dart';
import 'package:school_app/models/student.dart';
import 'package:school_app/providers/announcement_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/core/utils/firestore_keys.dart';

import 'parent_children_provider.dart';

class ParentAttendanceTodaySummary {
  const ParentAttendanceTodaySummary({
    required this.dateKey,
    required this.classKey,
    required this.isMarked,
    required this.studentStatus,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.total,
  });

  final String dateKey;
  final String classKey;

  /// Whether the class attendance was submitted for the day.
  final bool isMarked;

  /// The selected student's status for today (present/absent/late/leave) if marked.
  final String? studentStatus;

  final int present;
  final int absent;
  final int late;
  final int leave;
  final int total;
}

class ParentFeesSummary {
  const ParentFeesSummary({required this.pendingAmount});

  final num pendingAmount;
}

String _dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _classKeyFor(Student s) {
  return classKeyFrom(s.classId, s.section);
}

/// Today attendance summary for the selected child.
final parentAttendanceTodayProvider = StreamProvider.autoDispose
    .family<ParentAttendanceTodaySummary, Student>((ref, student) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;
      final today = DateTime.now();
      final dateKey = _dateKey(today);
      final classKey = _classKeyFor(student);

      if (classKey == 'class__') {
        return Stream.value(
          ParentAttendanceTodaySummary(
            dateKey: dateKey,
            classKey: classKey,
            isMarked: false,
            studentStatus: null,
            present: 0,
            absent: 0,
            late: 0,
            leave: 0,
            total: 0,
          ),
        );
      }

      final dateDoc = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .doc(dateKey);

      final metaDoc = dateDoc.collection('meta').doc(classKey);
      final recordDoc = dateDoc.collection(classKey).doc(student.id);

      // Combine meta + student record streams.
      return metaDoc.snapshots().asyncMap((metaSnap) async {
        final isMarked = metaSnap.exists;

        int present = 0;
        int absent = 0;
        int late = 0;
        int leave = 0;
        int total = 0;

        if (metaSnap.exists) {
          final data = metaSnap.data() ?? const <String, dynamic>{};
          final counts = data['counts'];
          if (counts is Map) {
            present = (counts['present'] as num?)?.toInt() ?? 0;
            absent = (counts['absent'] as num?)?.toInt() ?? 0;
            late = (counts['late'] as num?)?.toInt() ?? 0;
            leave = (counts['leave'] as num?)?.toInt() ?? 0;
            total = (counts['total'] as num?)?.toInt() ?? 0;
          }
        }

        String? studentStatus;
        if (isMarked) {
          final recordSnap = await recordDoc.get();
          final r = recordSnap.data() ?? const <String, dynamic>{};
          final raw = (r['status'] ?? '').toString().trim();
          studentStatus = raw.isEmpty ? null : raw;
        }

        return ParentAttendanceTodaySummary(
          dateKey: dateKey,
          classKey: classKey,
          isMarked: isMarked,
          studentStatus: studentStatus,
          present: present,
          absent: absent,
          late: late,
          leave: leave,
          total: total,
        );
      });
    },
  );
});

/// Pending homework count for the selected child.
///
/// We avoid Firestore range queries to prevent composite-index requirements.
final parentPendingHomeworkCountProvider = StreamProvider.autoDispose
    .family<int, Student>((ref, student) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;
      final startOfToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      return FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('homework')
          .where('classId', isEqualTo: student.classId)
          .where('section', isEqualTo: student.section)
          .snapshots()
          .map((snap) {
        int count = 0;
        for (final doc in snap.docs) {
          final data = doc.data();
          final raw = data['dueDate'];
          DateTime? due;
          if (raw is Timestamp) due = raw.toDate();
          if (raw is DateTime) due = raw;
          if (raw is String) due = DateTime.tryParse(raw);

          if (due == null) continue;
          if (!due.isBefore(startOfToday)) count++;
        }
        return count;
      });
    },
  );
});

/// Fee pending amount summary for the selected child.
///
/// Expected future structure:
/// schools/{schoolId}/studentFees/* where each doc has studentId and either:
/// - pendingAmount/balance (number)
/// - OR amount + status == 'pending'
final parentFeesSummaryProvider = StreamProvider.autoDispose
    .family<ParentFeesSummary, Student>((ref, student) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;

      return FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('studentFees')
          .where('studentId', isEqualTo: student.id)
          .snapshots()
          .map((snap) {
        num pending = 0;

        for (final doc in snap.docs) {
          final data = doc.data();

          final bal = data['balance'] ?? data['pendingAmount'];
          if (bal is num) {
            pending += bal;
            continue;
          }

          final status = (data['status'] ?? '').toString();
          final amount = data['amount'];
          if (status == 'pending' && amount is num) {
            pending += amount;
          }
        }

        return ParentFeesSummary(pendingAmount: pending);
      });
    },
  );
});

/// Latest announcement visible to the selected child (parents).
final parentLatestAnnouncementProvider = Provider.autoDispose
    .family<Announcement?, Student>((ref, student) {
  final announcementsAsync = ref.watch(announcementsProvider);

  return announcementsAsync.maybeWhen(
    data: (snap) {
      for (final doc in snap.docs) {
        final a = Announcement.fromDoc(doc);
        if (_isVisibleForParent(a.target, student)) return a;
      }
      return null;
    },
    orElse: () => null,
  );
});

bool _isVisibleForParent(String target, Student student) {
  final t = target.trim();
  if (t == 'all') return true;
  if (t == 'parents') return true;

  if (!t.startsWith('class_')) return false;
  final parsed = _parseClassTarget(t);
  if (parsed == null) return false;

  final (classId, sectionId) = parsed;
  return student.classId.trim() == classId && student.section.trim() == sectionId;
}

(String, String)? _parseClassTarget(String target) {
  final parts = target.split('_');
  if (parts.length < 3) return null;
  final classId = parts[1].trim();
  final sectionId = parts.sublist(2).join('_').trim();
  if (classId.isEmpty || sectionId.isEmpty) return null;
  return (classId, sectionId);
}

/// Convenience provider: current selected child, or null.
final selectedChildDashboardProvider = Provider.autoDispose<Student?>((ref) {
  return ref.watch(selectedChildProvider);
});
