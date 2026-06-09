import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference timetableRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('timetables');
  }

  Stream<QuerySnapshot> getTimetable(String schoolId) {
    return timetableRef(schoolId).orderBy('day').snapshots();
  }

  Future<void> addTimetable({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await timetableRef(schoolId).add({
      ...data,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTimetable({
    required String schoolId,
    required String timetableId,
  }) async {
    await timetableRef(schoolId).doc(timetableId).delete();
  }
}
