import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/current_school_provider.dart';

/// Streams students for the current school.
///
/// Path: `schools/{schoolId}/students`
final studentsProvider = StreamProvider.autoDispose<
    QuerySnapshot<Map<String, dynamic>>>((ref) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;
      return FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .snapshots();
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) => const Stream.empty(),
  );
});
