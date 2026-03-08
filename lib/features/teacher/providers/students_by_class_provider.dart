import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/current_school_provider.dart'
  as current_school_provider;

/// Streams students for attendance by class + section.
///
/// NOTE: We scope to the *current school* for SaaS safety.
/// Path: `schools/{schoolId}/students` (filtered by classId + section)
final studentsByClassProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, (String, String)>(
  (ref, params) {
    final (classId, section) = params;
    final schoolAsync = ref.watch(current_school_provider.currentSchoolProvider);

    return schoolAsync.when(
      data: (schoolDoc) {
        return FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolDoc.id)
            .collection('students')
            .where('classId', isEqualTo: classId)
            .where('section', isEqualTo: section)
            .orderBy('name')
            .snapshots();
      },
      loading: () => const Stream.empty(),
      error: (e, st) => const Stream.empty(),
    );
  },
);
