import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/core_providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authChanges();
});

final userRoleProvider = FutureProvider.autoDispose<UserRole>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return UserRole.unknown;

  final userDoc = await ref.watch(firestoreServiceProvider).getUserDoc(user.uid);
  final data = userDoc.data();

  if (data == null) {
    const hardcodedSuperAdminEmails = <String>{'sadiq.smile@gmail.com'};
    final email = user.email?.trim().toLowerCase();
    if (email != null && hardcodedSuperAdminEmails.contains(email)) {
      return UserRole.superAdmin;
    }
    return UserRole.unknown;
  }

  final role = (data['role'] ?? '').toString();
  if (role == 'superAdmin') return UserRole.superAdmin;
  if (role == 'admin') return UserRole.admin;
  return UserRole.unknown;
});
