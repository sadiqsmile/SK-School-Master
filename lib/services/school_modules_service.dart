import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/models/school_modules.dart';

class SchoolModulesService {
  SchoolModulesService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> modulesDoc(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('modules');
  }

  Future<SchoolModules> getModules(String schoolId) async {
    final snap = await modulesDoc(schoolId).get();
    return SchoolModules.fromMap(snap.data());
  }

  Future<void> setModule({
    required String schoolId,
    required SchoolModuleKey key,
    required bool enabled,
  }) async {
    await modulesDoc(schoolId).set(
      <String, dynamic>{key.key: enabled},
      SetOptions(merge: true),
    );
  }

  Future<void> setModules({
    required String schoolId,
    required SchoolModules modules,
  }) async {
    await modulesDoc(schoolId).set(
      modules.toMap(),
      SetOptions(merge: true),
    );
  }
}
