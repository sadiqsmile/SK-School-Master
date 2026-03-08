import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';

class TeacherAssignment {
  const TeacherAssignment({
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.sectionName,
  });

  final String classId;
  final String sectionId;
  final String className;
  final String sectionName;

  String get label {
    final c = className.trim().isNotEmpty ? className.trim() : classId.trim();
    final s = sectionName.trim().isNotEmpty ? sectionName.trim() : sectionId.trim();
    if (c.isEmpty && s.isEmpty) return 'Class';
    if (s.isEmpty) return 'Class $c';
    return 'Class $c$s';
  }

  static TeacherAssignment? fromDynamic(dynamic item) {
    if (item is Map) {
      final classId = (item['classId'] ?? '').toString().trim();
      final sectionId = (item['sectionId'] ?? item['section'] ?? '').toString().trim();
      final className = (item['className'] ?? '').toString();
      final sectionName = (item['sectionName'] ?? '').toString();
      if (classId.isEmpty && sectionId.isEmpty && className.trim().isEmpty && sectionName.trim().isEmpty) {
        return null;
      }
      return TeacherAssignment(
        classId: classId,
        sectionId: sectionId,
        className: className,
        sectionName: sectionName,
      );
    }
    return null;
  }
}

/// Finds the teacher document id for the logged-in teacher.
///
/// Preferred doc id is teacherUid. For backward compatibility, if it doesn't
/// exist, we fall back to searching `teacherUid` field.
final teacherDocIdProvider = FutureProvider.autoDispose<String>((ref) async {
  final schoolId = await ref.watch(schoolIdProvider.future);

  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  final directRef = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('teachers')
      .doc(user.uid);

  final directDoc = await directRef.get();
  if (directDoc.exists) return user.uid;

  final q = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('teachers')
      .where('teacherUid', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (q.docs.isEmpty) {
    throw Exception('Teacher profile not found');
  }

  return q.docs.first.id;
});

final teacherProfileProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((
  ref,
) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);
  final teacherDocId = await ref.watch(teacherDocIdProvider.future);

  yield* FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('teachers')
      .doc(teacherDocId)
      .snapshots();
});

final teacherAssignmentsProvider = Provider.autoDispose<List<TeacherAssignment>>((ref) {
  final profileAsync = ref.watch(teacherProfileProvider);
  final data = profileAsync.value?.data();
  if (data == null) return const <TeacherAssignment>[];

  final raw = data['classes'];
  if (raw is! List) return const <TeacherAssignment>[];

  final out = <TeacherAssignment>[];
  for (final item in raw) {
    final parsed = TeacherAssignment.fromDynamic(item);
    if (parsed != null) out.add(parsed);
  }
  return out;
});
