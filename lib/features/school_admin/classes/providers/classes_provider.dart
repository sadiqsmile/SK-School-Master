import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';

final classesProvider =
  StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return schoolAsync.when(
    data: (schoolDoc) {
      final schoolId = schoolDoc.id;

      return FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .snapshots();
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});
