import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:school_app/firebase_options.dart';

class FirestoreService {
  const FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSchoolDoc(String schoolId) {
    return _firestore.collection('schools').doc(schoolId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> schoolsStream() {
    return _firestore.collection('schools').snapshots();
  }

  Future<void> createSchoolWithAdmin({
    required String schoolName,
    required String adminEmail,
    required String adminPassword,
    required String themeColor,
  }) async {
    if (schoolName.trim().isEmpty) {
      throw ArgumentError('schoolName cannot be empty');
    }

    final schoolId =
        schoolName
            .substring(0, schoolName.length >= 4 ? 4 : schoolName.length)
            .toLowerCase()
            .replaceAll(' ', '') +
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);

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

    await _firestore.collection('schools').doc(schoolId).set({
      'name': schoolName,
      'schoolId': schoolId,
      'logo': 'pending',
      'themeColor': themeColor,
      'subscriptionStatus': 'active',
      'subscriptionPlan': 'pro',
      'adminUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('platform').doc('config').set({
      'totalSchools': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await _firestore.collection('platform').doc('stats').set({
      'totalSchools': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(adminUid).set({
      'role': 'admin',
      'status': 'active',
      'schoolId': schoolId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
