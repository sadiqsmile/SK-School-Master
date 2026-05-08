import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference attendanceRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('attendance');
  }

  Stream<QuerySnapshot> getAttendance(String schoolId) {
    return attendanceRef(schoolId).snapshots();
  }

  Future<void> markAttendance({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await attendanceRef(schoolId).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
