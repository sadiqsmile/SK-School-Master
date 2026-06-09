import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classesByGroupProvider =
    StreamProvider.family<
        List<QueryDocumentSnapshot<Map<String, dynamic>>>,
        Map<String, String>>(
  (ref, params) {

    final schoolId =
        params['schoolId'] ?? '';

    final group =
        params['group'] ?? '';

    return FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .where(
          'group',
          isEqualTo: group,
        )
        .snapshots()


      .map((snapshot) {

  print(
    'Classes Found: ${snapshot.docs.length}',
  );

  return snapshot.docs;
});




  },
);