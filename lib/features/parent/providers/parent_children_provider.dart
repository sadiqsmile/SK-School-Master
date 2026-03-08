import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/student.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/parent_service.dart';

/// Streams students linked to the currently signed-in parent.
final parentChildrenProvider = StreamProvider.autoDispose<List<Student>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    yield const <Student>[];
    return;
  }

  final schoolDoc = await ref.watch(currentSchoolProvider.future);
  final schoolId = schoolDoc.id;

  yield* ParentService()
      .myChildrenSnapshots(schoolId: schoolId, parentUid: user.uid)
      .map((snap) {
    final list = snap.docs
        .map((d) => Student.fromMap(d.id, d.data()))
        .toList(growable: false);

    // Avoid orderBy() to prevent composite-index requirements.
    final sorted = [...list]..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  });
});

/// Holds the selected child/student id for the parent dashboard.
final selectedChildIdProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Convenience provider for the currently selected child record.
final selectedChildProvider = Provider.autoDispose<Student?>((ref) {
  final selectedId = ref.watch(selectedChildIdProvider);
  final childrenAsync = ref.watch(parentChildrenProvider);

  return childrenAsync.maybeWhen(
    data: (children) {
      if (children.isEmpty) return null;
      if (selectedId == null) return children.first;
      for (final s in children) {
        if (s.id == selectedId) return s;
      }
      return children.first;
    },
    orElse: () => null,
  );
});
