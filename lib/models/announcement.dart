import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String target;
  final String? createdBy;
  final DateTime? createdAt;

  static Announcement fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();

    return Announcement(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      target: (data['target'] ?? '').toString(),
      createdBy: (data['createdBy'] as String?),
      createdAt: created,
    );
  }
}
