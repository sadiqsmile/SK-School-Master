import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_state_provider.dart';

final userRoleProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  // Watch auth state so this provider recomputes when user signs out/in.
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  final firestore = FirebaseFirestore.instance;

  // 1) Primary source: users/{uid}
  final userDoc = await firestore.collection('users').doc(user.uid).get();
  if (userDoc.exists) {
    return userDoc.data();
  }

  // 2) Fallback: super admin email(s)
  // If you prefer not to hardcode this, add one of these fields to `platform/config`:
  // - superAdminEmail: "name@domain.com"
  // - superAdminEmails / superAdmins: ["name@domain.com", ...]
  final email = user.email?.trim().toLowerCase();

  const hardcodedSuperAdminEmails = <String>{
    // Provided super admin account for this app.
    'sadiq.smile@gmail.com',
  };
  if (email != null && hardcodedSuperAdminEmails.contains(email)) {
    return {'role': 'superAdmin', 'status': 'active'};
  }

  final platformConfig = await firestore
      .collection('platform')
      .doc('config')
      .get();
  final config = platformConfig.data();
  if (email != null && config != null) {
    final dynamic single = config['superAdminEmail'];
    final dynamic listA = config['superAdminEmails'];
    final dynamic listB = config['superAdmins'];

    bool matches(dynamic v) {
      if (v is String) return v.trim().toLowerCase() == email;
      return false;
    }

    bool listMatches(dynamic v) {
      if (v is Iterable) {
        return v
            .whereType<String>()
            .map((e) => e.trim().toLowerCase())
            .contains(email);
      }
      return false;
    }

    if (matches(single) || listMatches(listA) || listMatches(listB)) {
      return {'role': 'superAdmin', 'status': 'active'};
    }
  }

  // Unknown user: let the UI send them back to Login.
  return null;
});
