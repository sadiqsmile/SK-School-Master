import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';

/// Streams the signed-in user's profile document (`users/{uid}`).
final currentUserDocProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  yield* ref.watch(firestoreServiceProvider).userDocStream(user.uid);
});

/// Best-effort display name for the current user.
final currentUserDisplayNameProvider = Provider.autoDispose<String>((ref) {
  final doc = ref.watch(currentUserDocProvider).value;
  final data = doc?.data();
  if (data == null) return '';

  final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;

  final email = (data['email'] ?? '').toString().trim();
  if (email.isNotEmpty) return email;

  final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().trim();
  return phone;
});
