// providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/core_providers.dart';

final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  return ref.watch(authServiceProvider).authChanges();
});

final userRoleProvider = FutureProvider.autoDispose<UserRole>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) return UserRole.unknown;

  final userDoc = await ref
      .watch(firestoreServiceProvider)
      .getUserDoc(user.uid);
  final data = userDoc.data();

  if (data == null) {
    return UserRole.unknown;
  }

  final role = (data['role'] ?? '').toString();
  if (role == 'superAdmin') return UserRole.superAdmin;
  if (role == 'admin') return UserRole.admin;
  if (role == 'teacher') return UserRole.teacher;
  if (role == 'parent') return UserRole.parent;
  return UserRole.unknown;
});

/// Whether the signed-in user must change their password (used for parent flow).
final mustChangePasswordProvider = StreamProvider.autoDispose<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(false);
  }

  return ref
      .watch(firestoreServiceProvider)
      .userDocStream(user.uid)
      .map((userDoc) {
    final data = userDoc.data();
    if (data == null) return false;
    return (data['mustChangePassword'] ?? false) == true;
  });
});
