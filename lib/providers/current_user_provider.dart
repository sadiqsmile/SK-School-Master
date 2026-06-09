import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserDocProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final authUser = ref.watch(authStateProvider).value;

  if (authUser == null) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authUser.uid)
      .snapshots();
});

final currentUserDataProvider = Provider<Map<String, dynamic>?>((ref) {
  final doc = ref.watch(currentUserDocProvider).value;
  if (doc == null || !doc.exists) return null;
  return doc.data();
});

final currentUserRoleProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData?['role']?.toString();
});

final currentSchoolIdProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData?['schoolId']?.toString();
});

final currentUserStatusProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData?['status']?.toString();
});