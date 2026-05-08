import 'package:cloud_firestore/cloud_firestore.dart';

class GroupTimingService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference timingRef(
    String schoolId,
  ) {

    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('group_timings');
  }

  Stream<QuerySnapshot> getTimings(
    String schoolId,
  ) {

    return timingRef(schoolId)
        .orderBy('group')
        .snapshots();
  }

  Future<void> saveTiming({

    required String schoolId,

    required String group,

    required String schoolStartTime,

    required int periodDuration,

    required int totalPeriods,

    required int lunchAfterPeriod,

    required int lunchDuration,

    required int shortBreakAfter,

    required int shortBreakDuration,

  }) async {

    await timingRef(schoolId)
        .doc(group)
        .set({

      'group': group,

      'schoolStartTime':
          schoolStartTime,

      'periodDuration':
          periodDuration,

      'totalPeriods':
          totalPeriods,

      'lunchAfterPeriod':
          lunchAfterPeriod,

      'lunchDuration':
          lunchDuration,

      'shortBreakAfter':
          shortBreakAfter,

      'shortBreakDuration':
          shortBreakDuration,

      'archived': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}
