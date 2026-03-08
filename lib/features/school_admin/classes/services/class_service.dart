import 'package:cloud_firestore/cloud_firestore.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createClass({
    required String schoolId,
    required String className,
    required String sectionType,
  }) async {
    final classId = "${className}_$sectionType".toLowerCase().replaceAll(
      " ",
      "_",
    );

    final classRef = _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId);

    // Default sections for every class.
    const sections = <String>['A', 'B', 'C'];

    // Use a batched write so class + sections are created together.
    final batch = _firestore.batch();

    batch.set(classRef, {
      'name': className,
      'nameLower': className.trim().toLowerCase(),
      'sectionType': sectionType,
      'sectionTypeLower': sectionType.trim().toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final s in sections) {
      batch.set(classRef.collection('sections').doc(s), {
        'name': s,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
