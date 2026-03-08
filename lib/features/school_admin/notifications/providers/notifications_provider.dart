import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/school_admin_provider.dart';

/// In-app notifications feed for staff.
///
/// Path: schools/{schoolId}/notifications/{notificationId}
final schoolNotificationsProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, int>((ref, limit) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(limit.clamp(1, 200))
      .snapshots();
});
