import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/current_school_provider.dart';

class SectionUsageKey {
  const SectionUsageKey({required this.classId, required this.sectionId});

  final String classId;
  final String sectionId;

  @override
  bool operator ==(Object other) {
    return other is SectionUsageKey &&
        other.classId == classId &&
        other.sectionId == sectionId;
  }

  @override
  int get hashCode => Object.hash(classId, sectionId);
}

/// Returns true if any student is assigned to this class+section.
///
/// Path queried: `schools/{schoolId}/students`
///
/// We try an efficient compound query first. If the project doesn't have the
/// composite index, we fall back to querying by classId only and filtering
/// client-side (acceptable for typical class sizes).
final sectionInUseProvider = FutureProvider.family
    .autoDispose<bool, SectionUsageKey>((ref, key) async {
  final school = await ref.watch(currentSchoolProvider.future);
  final schoolId = school.id;

  final studentsCol = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('students');

  final classId = key.classId.trim();
  final sectionId = key.sectionId.trim();

  try {
    final q = await studentsCol
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: sectionId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  } on FirebaseException catch (e) {
    // Missing composite index -> fall back.
    if (e.code == 'failed-precondition') {
      final q = await studentsCol.where('classId', isEqualTo: classId).get();
      for (final doc in q.docs) {
        final data = doc.data();
        final s = (data['section'] ?? '').toString().trim();
        if (s.toUpperCase() == sectionId.toUpperCase()) {
          return true;
        }
      }
      return false;
    }
    rethrow;
  }
});
