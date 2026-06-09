import 'package:cloud_firestore/cloud_firestore.dart';

class MarksService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference marksRef(
    String schoolId,
  ) {

    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('exam_results');
  }

  Stream<QuerySnapshot> getResults(
    String schoolId,
  ) {

    return marksRef(schoolId)
        .snapshots();
  }

  Future<void> saveStudentMarks({

    required String schoolId,

    required Map<String, dynamic>
        data,

  }) async {

    await marksRef(schoolId).add({

      ...data,

      'published': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> publishResult({

    required String schoolId,

    required String resultId,

  }) async {

    await marksRef(schoolId)
        .doc(resultId)
        .update({

      'published': true,
    });
  }
}
