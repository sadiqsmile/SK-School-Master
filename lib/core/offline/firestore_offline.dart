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
    // SECURITY NOTE:
    // Firestore persistence stores cached data unencrypted on device.
    // We keep persistence enabled for offline UX, but DO NOT allow unlimited
    // growth to reduce privacy exposure on lost/stolen devices.
    const boundedCacheBytes = 40 * 1024 * 1024; // 40 MB
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: boundedCacheBytes,
    );
  } catch (_) {
    // Best-effort: some platforms/configs may throw if settings were already set.
  }
}
