import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/providers/teacher_profile_provider.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';

/// Loads the current teacher profile document.
///
/// Path: `schools/{schoolId}/teachers/{teacherDocId}`
final teacherProvider = FutureProvider.autoDispose<
    DocumentSnapshot<Map<String, dynamic>>>((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);

  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  // Uses the existing compatibility logic (doc id == uid, else query by teacherUid).
  final teacherDocId = await ref.watch(teacherDocIdProvider.future);

  return FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('teachers')
      .doc(teacherDocId)
      .get();
});
