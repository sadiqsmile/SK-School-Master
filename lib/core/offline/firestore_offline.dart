import 'package:cloud_firestore/cloud_firestore.dart';

/// Enables robust local caching so writes can be queued while offline.
///
/// Notes:
/// - On Android/iOS, offline persistence is enabled by default, but we set it
///   explicitly for consistency.
/// - On Web, persistence is not always enabled unless explicitly requested.
Future<void> configureFirestoreOfflinePersistence() async {
  // This should be called after Firebase.initializeApp().
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    // Best-effort: some platforms/configs may throw if settings were already set.
  }
}
