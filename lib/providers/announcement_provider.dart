import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/school_admin_provider.dart';

/// Streams announcements for the current user's school.
///
/// Firestore structure:
/// schools/{schoolId}/announcements/{announcementId}
final announcementsProvider = StreamProvider.autoDispose<
    QuerySnapshot<Map<String, dynamic>>>(
  (ref) async* {
    final schoolId = await ref.watch(schoolIdProvider.future);

    yield* FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  },
);
