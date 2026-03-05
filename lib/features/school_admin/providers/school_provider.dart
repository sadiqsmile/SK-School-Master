// features/school_admin/providers/school_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/providers/auth_state_provider.dart';

final schoolProvider = FutureProvider.autoDispose<DocumentSnapshot>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("User not logged in");
  }

  final userDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .get();

  final userData = userDoc.data();

  if (userData == null) {
    throw Exception("User data not found");
  }

  final schoolId = userData['schoolId'];

  final schoolDoc = await FirebaseFirestore.instance
      .collection("schools")
      .doc(schoolId)
      .get();

  return schoolDoc;
});
