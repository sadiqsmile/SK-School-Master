// providers/super_admin_provider.dart
// providers/super_admin_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔥 PLATFORM CONFIG
final platformProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) {
    return FirebaseFirestore.instance
        .collection('platform')
        .doc('config')
        .snapshots();
  },
);

/// 🏫 ALL SCHOOLS (SAFE VERSION - NO ORDER BY ISSUE)
final schoolsProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('schools')
      // ❌ removed orderBy (causing empty list issue)
      .snapshots();
});

/// 📊 TOTAL SCHOOLS
final totalSchoolsProvider = Provider<int>((ref) {
  final schoolsAsync = ref.watch(schoolsProvider);

  return schoolsAsync.when(
    data: (snap) => snap.docs.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 👨‍🎓 TOTAL STUDENTS
final totalStudentsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return FirebaseFirestore.instance.collectionGroup('students').snapshots();
    });
