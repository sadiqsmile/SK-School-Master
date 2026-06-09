import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference announcementsRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('announcements');
  }

  Stream<QuerySnapshot> getAnnouncements(String schoolId) {
    return announcementsRef(schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addAnnouncement({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    await announcementsRef(schoolId).add({
      ...data,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement({
    required String schoolId,
    required String announcementId,
  }) async {
    await announcementsRef(schoolId).doc(announcementId).delete();
  }
}
