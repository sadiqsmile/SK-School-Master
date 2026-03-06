// providers/current_school_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/auth_provider.dart';

final currentSchoolProvider =
    FutureProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>(
      (ref) async {
        // IMPORTANT: depend on authStateProvider so this recomputes when a user
        // logs out/in. This avoids stale cached schoolId that can cause
        // permission-denied until a hard refresh.
        final auth = ref.watch(authStateProvider);
        final user = auth.value;

        if (user == null) {
          throw Exception('User not logged in');
        }

        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        final schoolId = (userDoc.data()?['schoolId'] ?? '').toString();

        if (schoolId.isEmpty) {
          throw Exception('School ID not found');
        }

        return firestore.collection('schools').doc(schoolId).get();
      },
    );
