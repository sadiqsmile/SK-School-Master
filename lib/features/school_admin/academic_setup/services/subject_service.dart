import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference subjectsRef(
    String schoolId,
  ) {

    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('subjects');
  }

  Stream<QuerySnapshot> getSubjects(
    String schoolId,
  ) {

    return subjectsRef(schoolId)
        .orderBy('name')
        .snapshots();
  }

  Future<void> addSubject({

    required String schoolId,

    required String name,

    required String shortName,

    required String code,

    required List<String> groups,

  }) async {

    await subjectsRef(schoolId).add({

      'name': name.trim(),

      'shortName':
          shortName.trim(),

      'code': code.trim(),

      'groups': groups,

      'archived': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSubject({

    required String schoolId,
    required String subjectId,

    required String name,
    required String shortName,
    required String code,

    required List<String> groups,

  }) async {

    await subjectsRef(schoolId)
        .doc(subjectId)
        .update({

      'name': name.trim(),

      'shortName':
          shortName.trim(),

      'code': code.trim(),

      'groups': groups,
    });
  }

  Future<void> archiveSubject({

    required String schoolId,
    required String subjectId,

  }) async {

    await subjectsRef(schoolId)
        .doc(subjectId)
        .update({

      'archived': true,
    });
  }

  Future<void> restoreSubject({

    required String schoolId,
    required String subjectId,

  }) async {

    await subjectsRef(schoolId)
        .doc(subjectId)
        .update({

      'archived': false,
    });
  }
}
