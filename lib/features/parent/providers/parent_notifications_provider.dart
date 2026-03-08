import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/auth_provider.dart';

/// Parent in-app notifications feed.
///
/// Path: users/{uid}/notifications/{notificationId}
final parentNotificationsProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, int>((ref, limit) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(limit.clamp(1, 200))
      .snapshots();
});

/// Unread count for a small badge/dot.
///
/// Note: Uses a dedicated query to avoid downloading full notification docs.
final parentUnreadNotificationsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .where('readAt', isNull: true)
      // Keep this query cheap: we only need a badge, not an exact count.
      // UI already shows 99+ when count >= 99.
      .limit(99)
      .snapshots()
      .map((snap) => snap.size);
});
