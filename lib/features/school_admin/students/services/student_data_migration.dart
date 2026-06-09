import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDataMigration {
  static Future<void> run({
    required String schoolId,
  }) async {
    final db = FirebaseFirestore.instance;

    final snapshot = await db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .get();

    int updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      String className =
          (data['className'] ?? '')
              .toString()
              .trim();

      String section =
          (data['section'] ?? '')
              .toString()
              .trim()
              .toUpperCase();

      String classId =
          (data['classId'] ?? '')
              .toString()
              .trim();

      // Fix old class names
      if (!className.startsWith('Class ')) {
        className = 'Class $className';
      }

      // Rebuild classId
      classId = className
          .replaceAll('Class ', '')
          .trim();

      // Rebuild classKey
      final classKey =
          'Class $classId $section';

      await doc.reference.update({
        'className': className,
        'classId': classId,
        'section': section,
        'classKey': classKey,
      });

      updated++;
    }

    print('Student migration completed. Updated $updated records.',
    );
  }
}