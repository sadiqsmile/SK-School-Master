import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String schoolId) {
    return _db.collection('schools').doc(schoolId).collection('announcements');
  }

  Future<void> createAnnouncement({
    required String schoolId,
    required String title,
    required String message,
    required String target,
  }) async {
    final cleanTitle = title.trim();
    final cleanMessage = message.trim();
    final cleanTarget = target.trim();

    if (cleanTitle.isEmpty) throw ArgumentError('Title is required');
    if (cleanMessage.isEmpty) throw ArgumentError('Message is required');
    if (cleanTarget.isEmpty) throw ArgumentError('Target is required');

    final uid = FirebaseAuth.instance.currentUser?.uid;

    await _col(schoolId).add({
      'title': cleanTitle,
      'message': cleanMessage,
      'target': cleanTarget,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement({
    required String schoolId,
    required String announcementId,
  }) async {
    await _col(schoolId).doc(announcementId).delete();
  }
}
