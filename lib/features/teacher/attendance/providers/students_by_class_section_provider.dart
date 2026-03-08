// features/teacher/attendance/providers/students_by_class_section_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/current_school_provider.dart';

class TeacherClassSectionKey {
  const TeacherClassSectionKey({required this.classId, required this.sectionId});

  final String classId;
  final String sectionId;

  @override
  bool operator ==(Object other) {
    return other is TeacherClassSectionKey &&
        other.classId == classId &&
        other.sectionId == sectionId;
  }

  @override
  int get hashCode => Object.hash(classId, sectionId);
}

/// Streams students for a specific class+section in the current school.
///
/// Path: `schools/{schoolId}/students` (filtered by `classId` and `section`).
final studentsByClassSectionProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, TeacherClassSectionKey>((
  ref,
  key,
) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;
      return FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .where('classId', isEqualTo: key.classId)
          .where('section', isEqualTo: key.sectionId)
          .orderBy('name')
          .snapshots();
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) => const Stream.empty(),
  );
});
