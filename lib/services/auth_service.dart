// services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:school_app/core/offline/firestore_sync_tracker.dart';
import 'package:school_app/core/utils/school_storage.dart';

class AuthService {
  const AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Stop any Firestore listeners before we attempt to clear persistence.
    FirestoreSyncTracker.instance.dispose();

    await _auth.signOut();
    await SchoolStorage.clearSchool();

    // Best-effort: remove cached school data from disk after logout.
    // Firestore requires termination before clearing persistence.
    try {
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();
    } catch (_) {
      // Ignore: some platforms/configurations may not support this at runtime.
    } finally {
      // Re-start the sync tracker for the next session.
      FirestoreSyncTracker.instance.start();
    }
  }
}
