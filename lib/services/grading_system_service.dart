import 'package:cloud_firestore/cloud_firestore.dart';

class GradingSystemService {
  GradingSystemService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _defaultRef(String schoolId) {
    return _db
        .collection('schools')
        .doc(schoolId)
        .collection('gradingSystems')
        .doc('default');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDefault({
    required String schoolId,
  }) {
    return _defaultRef(schoolId).snapshots();
  }

  Future<void> upsertDefault({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await _defaultRef(schoolId).set(data, SetOptions(merge: true));
  }
}
