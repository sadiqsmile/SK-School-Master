import 'package:cloud_firestore/cloud_firestore.dart';

class ExamService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference examRef(
    String schoolId,
  ) {

    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('exams');
  }

  Stream<QuerySnapshot> getExams(
    String schoolId,
  ) {

    return examRef(schoolId)
        .orderBy('createdAt',
            descending: true)
        .snapshots();
  }

  Future<void> createExam({

    required String schoolId,

    required Map<String, dynamic>
        data,

  }) async {

    await examRef(schoolId).add({

      ...data,

      'published': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> publishExam({

    required String schoolId,

    required String examId,

  }) async {

    await examRef(schoolId)
        .doc(examId)
        .update({

      'published': true,
    });
  }

  Future<void> deleteExam({

    required String schoolId,

    required String examId,

  }) async {

    await examRef(schoolId)
        .doc(examId)
        .delete();
  }
}
