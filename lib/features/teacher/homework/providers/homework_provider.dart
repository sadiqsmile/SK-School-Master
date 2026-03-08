import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream homework for a specific class/section.
///
/// Firestore structure:
/// schools/{schoolId}/homework/{homeworkId}
final teacherHomeworkProvider = StreamProvider.family
    .autoDispose<QuerySnapshot<Map<String, dynamic>>, (String, String, String)>(
  (ref, params) {
    final (schoolId, classId, section) = params;

    return FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('homework')
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: section)
        .limit(200)
        .snapshots();
  },
);
