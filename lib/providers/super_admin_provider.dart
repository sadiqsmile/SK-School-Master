// providers/super_admin_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform config provider (cached, single instance)
final platformProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) {
    return FirebaseFirestore.instance
        .collection('platform')
        .doc('config')
        .snapshots();
  },
);

/// Schools list provider (cached, single instance)
final schoolsProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance.collection('schools').snapshots();
});
