import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public platform status document.
///
/// Path: platform/status
///
/// This is intentionally readable by everyone so the app can show a global
/// maintenance screen even before login.
final platformStatusDocProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) {
    return FirebaseFirestore.instance
        .collection('platform')
        .doc('status')
        .snapshots();
  },
);

/// Whether the system is in maintenance mode.
///
/// Stored as: platform/status.maintenanceMode == true
final maintenanceModeProvider = StreamProvider.autoDispose<bool>((ref) {
  return FirebaseFirestore.instance
      .collection('platform')
      .doc('status')
      .snapshots()
      .map((doc) {
    final data = doc.data();
    return (data?['maintenanceMode'] ?? false) == true;
  });
});
