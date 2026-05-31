import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final examNamesProvider =
    StreamProvider.family<
        List<QueryDocumentSnapshot<Map<String, dynamic>>>,
        String>((ref, schoolId) {

  return FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('exam_names')
      .orderBy('order')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs,
      );
});