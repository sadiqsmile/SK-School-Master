import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAssignmentService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> updateAssignments({

    required String schoolId,
    required String teacherId,

    required Map<String, dynamic>
        subject,

    required List<Map<String, dynamic>>
        assignedClasses,

    required Map<String, dynamic>?
        classIncharge,

    required Map<String, dynamic>?
        sectionTeacher,

  }) async {

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(teacherId)
        .update({

      'subject': subject,

      'assignedClasses':
          assignedClasses,

      'classIncharge':
          classIncharge,

      'sectionTeacher':
          sectionTeacher,

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}
