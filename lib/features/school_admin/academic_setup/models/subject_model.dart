import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {

  final String id;

  final String name;
  final String shortName;
  final String code;

  final List<String> groups;

  final bool archived;

  final Timestamp? createdAt;

  SubjectModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.code,
    required this.groups,
    required this.archived,
    this.createdAt,
  });

  factory SubjectModel.fromFirestore(
    DocumentSnapshot doc,
  ) {

    final data =
        doc.data() as Map<String, dynamic>;

    return SubjectModel(

      id: doc.id,

      name: data['name'] ?? '',

      shortName:
          data['shortName'] ?? '',

      code: data['code'] ?? '',

      groups:
          List<String>.from(
        data['groups'] ?? [],
      ),

      archived:
          data['archived'] ?? false,

      createdAt:
          data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {

    return {

      'name': name,

      'shortName': shortName,

      'code': code,

      'groups': groups,

      'archived': archived,

      'createdAt': createdAt,
    };
  }
}
