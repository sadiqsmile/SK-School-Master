// features/school_admin/fees/services/fee_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FeeService {
  const FeeService();

  CollectionReference feeRef(String schoolId) {
    return FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('fees');
  }

  Stream<QuerySnapshot> getFees(String schoolId) {
    return feeRef(schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addFee({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await feeRef(schoolId).add({
      ...data,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFee({
    required String schoolId,
    required String feeId,
    required Map<String, dynamic> data,
  }) async {
    await feeRef(schoolId).doc(feeId).update(data);
  }
}
