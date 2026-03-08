import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/school_modules.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/school_modules_service.dart';

final schoolModulesServiceProvider = Provider<SchoolModulesService>((ref) {
  return SchoolModulesService(ref.watch(firebaseFirestoreProvider));
});

/// Streams the school module settings for the current school.
///
/// Document path: `schools/{schoolId}/settings/modules`
final schoolModulesProvider = StreamProvider.autoDispose<SchoolModules>((ref) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);

  final docRef = ref.watch(schoolModulesServiceProvider).modulesDoc(schoolId);

  yield* docRef.snapshots().map((snap) {
    return SchoolModules.fromMap(snap.data());
  });
});
