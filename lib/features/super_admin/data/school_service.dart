import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchoolService {

Future<void> createSchool({
  required String schoolName,
  required String adminEmail,
  required String adminPassword,
  required String themeColor,
}) async {

final firestore = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;

final schoolId = schoolName
    .substring(0, schoolName.length >= 4 ? 4 : schoolName.length)
    .toLowerCase()
    .replaceAll(" ", "") +
    DateTime.now().millisecondsSinceEpoch.toString().substring(8);

final userCredential = await auth.createUserWithEmailAndPassword(
  email: adminEmail,
  password: adminPassword,
);

final adminUid = userCredential.user!.uid;

await auth.signInWithEmailAndPassword(
  email: "sadiq.smile@gmail.com",
  password: "admin@123",
);

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

await firestore.collection('users').doc(adminUid).set({
  'role': 'admin',
  'status': 'active',
  'schoolId': schoolId,
  'createdAt': FieldValue.serverTimestamp(),
});

}

}

