import 'package:cloud_firestore/cloud_firestore.dart';

class GroupTimingModel {

  final String id;

  final String group;

  final String schoolStartTime;

  final int periodDuration;

  final int totalPeriods;

  final int lunchAfterPeriod;

  final int lunchDuration;

  final int shortBreakAfter;

  final int shortBreakDuration;

  final bool archived;

  final Timestamp? createdAt;

  GroupTimingModel({

    required this.id,

    required this.group,

    required this.schoolStartTime,

    required this.periodDuration,

    required this.totalPeriods,

    required this.lunchAfterPeriod,

    required this.lunchDuration,

    required this.shortBreakAfter,

    required this.shortBreakDuration,

    required this.archived,

    this.createdAt,
  });

  factory GroupTimingModel.fromFirestore(
    DocumentSnapshot doc,
  ) {

    final data =
        doc.data() as Map<String, dynamic>;

    return GroupTimingModel(

      id: doc.id,

      group: data['group'] ?? '',

      schoolStartTime:
          data['schoolStartTime'] ?? '',

      periodDuration:
          data['periodDuration'] ?? 45,

      totalPeriods:
          data['totalPeriods'] ?? 8,

      lunchAfterPeriod:
          data['lunchAfterPeriod'] ?? 4,

      lunchDuration:
          data['lunchDuration'] ?? 40,

      shortBreakAfter:
          data['shortBreakAfter'] ?? 2,

      shortBreakDuration:
          data['shortBreakDuration'] ?? 15,

      archived:
          data['archived'] ?? false,

      createdAt:
          data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {

    return {

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

      'archived': archived,

      'createdAt': createdAt,
    };
  }
}
