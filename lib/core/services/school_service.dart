import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchoolService {
  static Stream<DocumentSnapshot<Map<String, dynamic>>> schoolStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('schools')
        .doc(uid)
        .snapshots();
  }
}