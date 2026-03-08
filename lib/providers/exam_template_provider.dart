import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/core/utils/firestore_keys.dart';
import 'package:school_app/models/exam_template.dart';
import 'package:school_app/providers/school_admin_provider.dart';

/// Streams exam templates for the current user's school.
///
/// Firestore:
/// schools/{schoolId}/examTemplates/{templateId}
final examTemplatesProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String?>((ref, examTypeKey) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  var q = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('examTemplates')
      .orderBy('updatedAt', descending: true);

  final key = (examTypeKey ?? '').trim();
  if (key.isNotEmpty) {
    q = q.where('examTypeKey', isEqualTo: key);
  }

  yield* q.limit(200).snapshots();
});

/// Streams a single template doc.
final examTemplateDocProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>((ref, templateId) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('examTemplates')
      .doc(templateId)
      .snapshots();
});

class ResolvedExamTemplateArgs {
  const ResolvedExamTemplateArgs({
    required this.templateId,
    required this.examTypeKey,
  });

  final String templateId;
  final String examTypeKey;

  @override
  bool operator ==(Object other) {
    return other is ResolvedExamTemplateArgs &&
        other.templateId == templateId &&
        other.examTypeKey == examTypeKey;
  }

  @override
  int get hashCode => Object.hash(templateId, examTypeKey);
}

/// Resolves the effective template to use for a given exam.
///
/// Priority:
/// 1) If [ResolvedExamTemplateArgs.templateId] is present, use it (locked).
/// 2) Else, read exam type doc and use `defaultTemplateId`.
/// 3) Else, null.
final resolvedExamTemplateProvider = StreamProvider.autoDispose
    .family<ExamTemplate?, ResolvedExamTemplateArgs>((ref, args) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  Stream<ExamTemplate?> templateStreamForId(String id) {
    return FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('examTemplates')
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ExamTemplate.fromDoc(doc);
    });
  }

  final lockedId = args.templateId.trim();
  if (lockedId.isNotEmpty) {
    yield* templateStreamForId(lockedId);
    return;
  }

  final typeKey = normalizeKeyLower(args.examTypeKey).trim();
  if (typeKey.isEmpty) {
    yield null;
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('examTypes')
      .doc(typeKey)
      .snapshots()
      .asyncExpand((typeDoc) {
    final data = typeDoc.data();
    final defaultId = (data == null ? '' : (data['defaultTemplateId'] ?? '')).toString().trim();
    if (defaultId.isEmpty) return Stream.value(null);
    return templateStreamForId(defaultId);
  });
});
