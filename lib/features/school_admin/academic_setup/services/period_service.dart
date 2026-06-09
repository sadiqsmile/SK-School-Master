import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference periodRef(
    String schoolId,
  ) {

    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('periods');
  }

  Stream<QuerySnapshot> getPeriods(
    String schoolId,
  ) {

    return periodRef(schoolId)
        .orderBy('group')
        .orderBy('sortOrder')
        .snapshots();
  }

  Future<void> addPeriod({

    required String schoolId,

    required String name,

    required String group,

    required String startTime,

    required String endTime,

    required String type,

    required int sortOrder,

  }) async {

    await periodRef(schoolId).add({

      'name': name,

      'group': group,

      'startTime': startTime,

      'endTime': endTime,

      'type': type,

      'sortOrder': sortOrder,

      'archived': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePeriod({

    required String schoolId,

    required String periodId,

    required String name,

    required String group,

    required String startTime,

    required String endTime,

    required String type,

    required int sortOrder,

  }) async {

    await periodRef(schoolId)
        .doc(periodId)
        .update({

      'name': name,

      'group': group,

      'startTime': startTime,

      'endTime': endTime,

      'type': type,

      'sortOrder': sortOrder,
    });
  }

  Future<void> archivePeriod({

    required String schoolId,

    required String periodId,

  }) async {

    await periodRef(schoolId)
        .doc(periodId)
        .update({

      'archived': true,
    });
  }
}
