import 'package:cloud_firestore/cloud_firestore.dart';

/// Parent-facing Firestore queries.
///
/// NOTE: Parent account creation/login is handled via Cloud Functions in
/// [ParentAccountService]. This service is intentionally read-only.
class ParentService {
  ParentService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<QuerySnapshot<Map<String, dynamic>>> myChildrenSnapshots({
    required String schoolId,
    required String parentUid,
  }) {
    return _db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .where('parentUid', isEqualTo: parentUid)
        .limit(50)
        .snapshots();
  }
}
