// providers/super_admin_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform config provider (cached, single instance)
final platformProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) {
    return FirebaseFirestore.instance
        .collection('platform')
        .doc('config')
        .snapshots();
  },
);

/// Schools list provider (cached, single instance)
final schoolsProvider = StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((
  ref,
) {
  // Protect against unbounded real-time reads in large SaaS deployments.
  // For real pagination, prefer a cursor-based paging UI.
  return FirebaseFirestore.instance
      .collection('schools')
      .limit(200)
      .snapshots();
});
