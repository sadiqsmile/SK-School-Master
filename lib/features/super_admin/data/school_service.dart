import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:school_app/firebase_options.dart';

class SchoolService {
  Future<void> createSchool({
    required String schoolName,
    required String adminEmail,
    required String adminPassword,
    required String themeColor,
  }) async {
    final firestore = FirebaseFirestore.instance;

    if (schoolName.trim().isEmpty) {
      throw ArgumentError('schoolName cannot be empty');
    }

    final schoolId =
        schoolName
            .substring(0, schoolName.length >= 4 ? 4 : schoolName.length)
            .toLowerCase()
            .replaceAll(" ", "") +
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);

    // IMPORTANT:
    // Creating a user with the primary FirebaseAuth instance would switch the
    // current session to the new admin (auth state change), which can kick the
    // super admin out of the dashboard mid-action.
    // Use a secondary FirebaseApp/Auth instance for account creation.
    const secondaryAppName = 'secondary-auth';
    final secondaryApp = Firebase.apps.any((a) => a.name == secondaryAppName)
        ? Firebase.app(secondaryAppName)
        : await Firebase.initializeApp(
            name: secondaryAppName,
            options: DefaultFirebaseOptions.currentPlatform,
          );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
    final adminUid = userCredential.user!.uid;
    await secondaryAuth.signOut();

    await firestore.collection('schools').doc(schoolId).set({
      'name': schoolName,
      'schoolId': schoolId,
      'logo': 'pending',
      'themeColor': themeColor,
      'subscriptionStatus': 'active',
      'subscriptionPlan': 'pro',
      'adminUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update platform counters (safe even if docs don't exist yet)
    // Super admin dashboard reads totals from `platform/config`.
    await firestore.collection('platform').doc('config').set({
      'totalSchools': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Optional: keep the legacy stats doc updated too (harmless if unused).
    await firestore.collection('platform').doc('stats').set({
      'totalSchools': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await firestore.collection('users').doc(adminUid).set({
      'role': 'admin',
      'status': 'active',
      'schoolId': schoolId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
