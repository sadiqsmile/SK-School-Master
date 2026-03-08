import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/grading_system.dart';
import 'package:school_app/providers/school_admin_provider.dart';

/// Streams the school's default grading system:
/// schools/{schoolId}/gradingSystems/default
final gradingSystemProvider = StreamProvider.autoDispose<GradingSystem>((ref) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('gradingSystems')
      .doc('default')
      .snapshots()
      .map((doc) => GradingSystem.fromDoc(doc) ?? GradingSystem.defaults());
});
