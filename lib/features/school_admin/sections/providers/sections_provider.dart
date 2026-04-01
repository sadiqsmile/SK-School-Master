
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';

final sectionsProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, classId) async* {
  print('[sectionsProvider] Provider CALLED with classId: $classId');
  final school = await ref.watch(currentSchoolProvider.future);
  if (classId.isEmpty) {
    print('[sectionsProvider] classId is empty, returning empty stream');
    yield* const Stream.empty();
    return;
  }
  final query = FirebaseFirestore.instance
      .collection('schools')
      .doc(school.id)
      .collection('sections')
      .where('classId', isEqualTo: classId);
  print('[sectionsProvider] Query: schools/${school.id}/sections where classId == $classId');
  await for (final snapshot in query.snapshots()) {
    print('[sectionsProvider] Query returned ${snapshot.docs.length} docs for classId=$classId');
    for (final doc in snapshot.docs) {
      print('[sectionsProvider] Section doc: id=${doc.id}, data=${doc.data()}');
    }
    yield snapshot;
  }
});
