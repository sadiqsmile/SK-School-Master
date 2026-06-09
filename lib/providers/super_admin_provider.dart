// providers/super_admin_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';



final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 🔥 PLATFORM CONFIG
final platformProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('platform')
      .doc('config')
      .snapshots();
});



/// 🏫 ALL SCHOOLS
final schoolsProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authStateProvider);

  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      return FirebaseFirestore.instance
          .collection('schools')
          .where('archived', isEqualTo: false) // ✅ IMPORTANT
          .snapshots();
    },
    loading: () => const Stream.empty(),
    error: (error, stack) => const Stream.empty(),
  );
});




/// 👨‍🎓 TOTAL SCHOOLS COUNT (FIXED)
final totalSchoolsProvider = StreamProvider.autoDispose<int>((ref) {
  final auth = ref.watch(authStateProvider);

  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();

     return FirebaseFirestore.instance
    .collection('schools')
    .where('archived', isEqualTo: false)
    .snapshots()
    .map((snap) => snap.docs.length);
    },
    loading: () => const Stream.empty(),
    error: (error, stack) => const Stream.empty(),
  );
});




/// 👨‍🎓 TOTAL STUDENTS COUNT (FIXED)
final totalStudentsProvider = StreamProvider.autoDispose<int>((ref) {
  final auth = ref.watch(authStateProvider);

  return auth.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      /// 🔥 FIRST GET ACTIVE SCHOOLS
      return FirebaseFirestore.instance
          .collection('schools')
          .where('archived', isEqualTo: false)
          .snapshots()
          .asyncMap((schoolSnap) async {

        final schoolIds = schoolSnap.docs.map((e) => e.id).toList();

        if (schoolIds.isEmpty) return 0;

        /// 🔥 THEN COUNT STUDENTS ONLY FROM ACTIVE SCHOOLS
        final studentSnap = await FirebaseFirestore.instance
            .collectionGroup('students')
            .where('schoolId', whereIn: schoolIds.length > 10
                ? schoolIds.sublist(0, 10) // firestore limit
                : schoolIds)
            .get();

        return studentSnap.docs.length;
      });
    },
    loading: () => const Stream.empty(),
    error: (error, stack) => const Stream.empty(),
  );
});


final archivedSchoolsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('schools')
      .where('archived', isEqualTo: true)
      .snapshots();
});