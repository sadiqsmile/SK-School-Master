import 'package:cloud_firestore/cloud_firestore.dart';

class ParentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference parentsRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('parents');
  }

  Future<void> createOrLinkParent({
    required String schoolId,
    required String studentId,
    required String studentName,
    required String parentName,
    required String phone,
  }) async {
    final existing = await parentsRef(schoolId)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> studentIds = data['studentIds'] ?? [];

      if (!studentIds.contains(studentId)) {
        studentIds.add(studentId);
        await doc.reference.update({'studentIds': studentIds});
      }

      return;
    }

    final defaultPassword =
        phone.length >= 4 ? phone.substring(phone.length - 4) : "1234";

    await parentsRef(schoolId).add({
      "name": parentName,
      "phone": phone,
      "studentIds": [studentId],
      "studentNames": [studentName],
      "mustChangePassword": true,
      "password": defaultPassword,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
