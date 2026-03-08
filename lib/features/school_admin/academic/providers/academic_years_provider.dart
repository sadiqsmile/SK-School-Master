import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/current_school_provider.dart';

/// Streams academic years for the current school.
///
/// Firestore structure:
/// schools/{schoolId}/academicYears/{academicYearId}
/// where academicYearId example: "2025-2026".
final academicYearsProvider = StreamProvider.autoDispose<
    QuerySnapshot<Map<String, dynamic>>>(
  (ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      data: (schoolDoc) {
        return FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDoc.id)
            .collection('academicYears')
            .snapshots();
      },
      loading: () => const Stream.empty(),
      error: (_, _) => const Stream.empty(),
    );
  },
);

/// Best-effort "current" academic year.
///
/// - If academicYears exist and include startYear/endYear fields, returns the
///   most recent.
/// - Otherwise falls back to "YYYY-YYYY+1" based on today's year.
final currentAcademicYearIdProvider = Provider.autoDispose<String>((ref) {
  final yearsAsync = ref.watch(academicYearsProvider);

  final docs = yearsAsync.value?.docs;
  if (docs != null && docs.isNotEmpty) {
    // Prefer explicit startYear if present.
    docs.sort((a, b) {
      final aStart = (a.data()['startYear'] as int?) ?? _parseStartYear(a.id);
      final bStart = (b.data()['startYear'] as int?) ?? _parseStartYear(b.id);
      return bStart.compareTo(aStart);
    });
    return docs.first.id;
  }

  final now = DateTime.now();
  final start = now.year;
  return '$start-${start + 1}';
});

int _parseStartYear(String academicYearId) {
  // academicYearId expected: "2025-2026".
  final parts = academicYearId.split('-');
  if (parts.isEmpty) return 0;
  return int.tryParse(parts.first) ?? 0;
}
