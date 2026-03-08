import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/school_branding.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/school_branding_service.dart';

final schoolBrandingServiceProvider = Provider<SchoolBrandingService>((ref) {
  return SchoolBrandingService(ref.watch(firebaseFirestoreProvider));
});

/// Streams school branding settings.
///
/// Document path: `schools/{schoolId}/settings/branding`
final schoolBrandingProvider = StreamProvider.autoDispose<SchoolBranding>((ref) async* {
  final schoolId = await ref.watch(schoolIdProvider.future);
  final docRef = ref.watch(schoolBrandingServiceProvider).brandingDoc(schoolId);

  yield* docRef.snapshots().map((snap) {
    return SchoolBranding.fromMap(snap.data());
  });
});

/// Resolves the current school's logo download URL from Storage.
///
/// Returns null if no logoPath is set or if the object is missing/unreadable.
final schoolBrandingLogoUrlProvider = FutureProvider.autoDispose<String?>((ref) async {
  final branding = await ref.watch(schoolBrandingProvider.future);
  final path = (branding.logoPath ?? '').trim();
  if (path.isEmpty) return null;

  try {
    return await FirebaseStorage.instance.ref(path).getDownloadURL();
  } catch (_) {
    return null;
  }
});

/// Saves school branding settings (Firestore only).
final saveSchoolBrandingProvider = Provider<Future<void> Function({required SchoolBranding branding})>((ref) {
  return ({required SchoolBranding branding}) async {
    final schoolId = await ref.read(schoolIdProvider.future);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await ref.read(schoolBrandingServiceProvider).setBranding(
          schoolId: schoolId,
          branding: branding,
          updatedByUid: uid,
        );
  };
});
