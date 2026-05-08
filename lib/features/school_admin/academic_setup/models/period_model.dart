import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodModel {

  final String id;

  final String name;

  final String group;

  final String startTime;

  final String endTime;

  final String type;

  final int sortOrder;

  final bool archived;

  final Timestamp? createdAt;

  PeriodModel({

    required this.id,

    required this.name,

    required this.group,

    required this.startTime,

    required this.endTime,

    required this.type,

    required this.sortOrder,

    required this.archived,

    this.createdAt,
  });

  factory PeriodModel.fromFirestore(
    DocumentSnapshot doc,
  ) {

    final data =
        doc.data() as Map<String, dynamic>;

    return PeriodModel(

      id: doc.id,

      name: data['name'] ?? '',

      group: data['group'] ?? '',

      startTime:
          data['startTime'] ?? '',

      endTime:
          data['endTime'] ?? '',

      type: data['type'] ?? '',

      sortOrder:
          data['sortOrder'] ?? 0,

      archived:
          data['archived'] ?? false,

      createdAt:
          data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {

    return {

      'name': name,

      'group': group,

      'startTime': startTime,

      'endTime': endTime,

      'type': type,

      'sortOrder': sortOrder,

      'archived': archived,

      'createdAt': createdAt,
    };
  }
}
