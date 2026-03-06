import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';

final schoolProvider = FutureProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) async {
    final authState = ref.watch(authStateProvider);
    final user = authState.value ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final userDoc = await ref.watch(firestoreServiceProvider).getUserDoc(user.uid);
    final userData = userDoc.data();
    if (userData == null) {
      throw Exception('User data not found');
    }

    final schoolId = (userData['schoolId'] ?? '').toString();
    if (schoolId.isEmpty) {
      throw Exception('School ID missing for user');
    }

    return ref.watch(firestoreServiceProvider).getSchoolDoc(schoolId);
  },
);
