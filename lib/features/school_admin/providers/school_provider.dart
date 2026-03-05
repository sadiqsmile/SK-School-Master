import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_state_provider.dart';

final schoolProvider = FutureProvider<DocumentSnapshot>((ref) async {
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    throw Exception("User not logged in");
  }

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final schoolId = userDoc.data()?['schoolId'];

  final schoolDoc = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .get();

  return schoolDoc;
});
