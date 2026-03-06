import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore operations for class sections.
///
/// Path: `schools/{schoolId}/classes/{classId}/sections/{sectionId}`
class SectionService {
  SectionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _sectionIdFromName(String name) {
    return name.trim().toUpperCase().replaceAll(' ', '_');
  }

  Future<void> createSection({
    required String schoolId,
    required String classId,
    required String sectionName,
  }) async {
    final trimmed = sectionName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('sectionName cannot be empty');
    }

    final sectionId = _sectionIdFromName(trimmed);

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('sections')
        .doc(sectionId)
        .set({
      'name': trimmed.toUpperCase(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSection({
    required String schoolId,
    required String classId,
    required String sectionId,
  }) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('sections')
        .doc(sectionId)
        .delete();
  }

  /// Creates the default sections (A/B/C) if they don't exist.
  ///
  /// This is useful for classes created before the app started auto-creating
  /// sections on class creation.
  Future<void> ensureDefaultSections({
    required String schoolId,
    required String classId,
    List<String> defaults = const ['A', 'B', 'C'],
  }) async {
    final batch = _firestore.batch();
    final sectionsCol = _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('sections');

    for (final s in defaults) {
      final id = _sectionIdFromName(s);
      batch.set(
        sectionsCol.doc(id),
        {
          'name': id,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
