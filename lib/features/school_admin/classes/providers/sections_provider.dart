import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/current_school_provider.dart';

/// Streams sections for a given class inside the current school.
///
/// Path: `schools/{schoolId}/classes/{classId}/sections`
final sectionsProvider = StreamProvider.family
    .autoDispose<QuerySnapshot<Map<String, dynamic>>, String>((ref, classId) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;
      return FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('sections')
          .orderBy('name')
          .snapshots();
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) => const Stream.empty(),
  );
});
