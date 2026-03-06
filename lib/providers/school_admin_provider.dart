// providers/school_admin_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';

/// Provider to get the current school ID for the logged-in user
final schoolIdProvider = FutureProvider.autoDispose<String>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  final userDoc = await ref
      .watch(firestoreServiceProvider)
      .getUserDoc(user.uid);
  final userData = userDoc.data();
  if (userData == null) {
    throw Exception('User data not found');
  }

  final schoolId = (userData['schoolId'] ?? '').toString();
  if (schoolId.isEmpty) {
    throw Exception('School ID missing for user');
  }

  return schoolId;
});

/// Teachers collection stream for the current school
final teachersProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
      ref,
    ) async* {
      final schoolId = await ref.watch(schoolIdProvider.future);

      yield* FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .snapshots();
    });

/// Students collection stream for the current school
final studentsProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
      ref,
    ) async* {
      final schoolId = await ref.watch(schoolIdProvider.future);

      yield* FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .snapshots();
    });

/// Classes collection stream for the current school
final classesProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
      ref,
    ) async* {
      final schoolId = await ref.watch(schoolIdProvider.future);

      yield* FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .snapshots();
    });

/// Attendance collection stream for the current school
final attendanceProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
      ref,
    ) async* {
      final schoolId = await ref.watch(schoolIdProvider.future);

      yield* FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .limit(50)
          .snapshots();
    });

/// Homework collection stream for the current school
final homeworkProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
      ref,
    ) async* {
      final schoolId = await ref.watch(schoolIdProvider.future);

      yield* FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('homework')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();
    });

/// Fees collection stream for the current school
final feesProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
      ref,
    ) async* {
      final schoolId = await ref.watch(schoolIdProvider.future);

      yield* FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('fees')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();
    });
