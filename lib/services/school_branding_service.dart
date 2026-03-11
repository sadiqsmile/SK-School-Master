import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/models/school_branding.dart';

class SchoolBrandingService {
  const SchoolBrandingService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> brandingDoc(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('branding');
  }

  Future<void> setBranding({
    required String schoolId,
    required SchoolBranding branding,
    required String updatedByUid,
  }) async {
    await brandingDoc(schoolId).set({
      ...branding.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedByUid,
    }, SetOptions(merge: true));
  }
}
