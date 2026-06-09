



import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/current_school_provider.dart';

final classesProvider = StreamProvider<QuerySnapshot>((ref) async* {
    print('[classesProvider] Provider CALLED');
    final school = await ref.watch(currentSchoolProvider.future);
    print('[classesProvider] Query: schools/${school.id}/classes');
    yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(school.id)
      .collection('classes')
      .snapshots();
});
