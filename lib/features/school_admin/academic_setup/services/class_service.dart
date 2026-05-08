import 'package:cloud_firestore/cloud_firestore.dart';

class ClassService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference classRef(
    String schoolId,
  ) {

    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes');
  }

  Stream<QuerySnapshot> getClasses(
    String schoolId,
  ) {

    return classRef(schoolId)
        .orderBy('name')
        .snapshots();
  }

  Future<void> addClass({

    required String schoolId,

    required String name,

    required String group,

    required List<String> sections,

  }) async {

    await classRef(schoolId).add({

      'name': name.trim(),

      'group': group,

      'sections': sections,

      'archived': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClass({

    required String schoolId,

    required String classId,

    required String name,

    required String group,

    required List<String> sections,

  }) async {

    await classRef(schoolId)
        .doc(classId)
        .update({

      'name': name.trim(),

      'group': group,

      'sections': sections,
    });
  }

  Future<void> archiveClass({

    required String schoolId,

    required String classId,

  }) async {

    await classRef(schoolId)
        .doc(classId)
        .update({

      'archived': true,
    });
  }
}
