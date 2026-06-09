import 'package:cloud_firestore/cloud_firestore.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

int _getClassOrder(
  String className,
) {
  switch (
    className.trim()
  ) {

    case 'LKG':
      return 1;

    case 'UKG':
      return 2;

    case 'Class 1':
      return 3;

    case 'Class 2':
      return 4;

    case 'Class 3':
      return 5;

    case 'Class 4':
      return 6;

    case 'Class 5':
      return 7;

    case 'Class 6':
      return 8;

    case 'Class 7':
      return 9;

    case 'Class 8':
      return 10;

    case 'Class 9':
      return 11;

    case 'Class 10':
      return 12;

    case 'I-PU':
      return 13;

    case 'II-PU':
      return 14;

    default:
      return 999;
  }
}



Future<void> fixClassOrder({
  required String schoolId,
}) async {

  final snapshot = await _firestore
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .get();

  final batch = _firestore.batch();

  for (final doc in snapshot.docs) {

    final className =
        doc.data()['name'] ?? '';

    batch.update(
      doc.reference,
      {
        'order':
            _getClassOrder(
          className,
        ),
      },
    );
  }

  await batch.commit();
}





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
  'sectionTypeLower':
      sectionType.trim().toLowerCase(),

  'order': _getClassOrder(
    className,
  ),

  'createdAt':
      FieldValue.serverTimestamp(),
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
