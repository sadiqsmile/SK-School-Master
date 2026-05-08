import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {

  final String id;

  final String name;

  final String group;

  final List<String> sections;

  final bool archived;

  final Timestamp? createdAt;

  ClassModel({

    required this.id,

    required this.name,

    required this.group,

    required this.sections,

    required this.archived,

    this.createdAt,
  });

  factory ClassModel.fromFirestore(
    DocumentSnapshot doc,
  ) {

    final data =
        doc.data() as Map<String, dynamic>;

    return ClassModel(

      id: doc.id,

      name: data['name'] ?? '',

      group: data['group'] ?? '',

      sections:
          List<String>.from(
        data['sections'] ?? [],
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

      'group': group,

      'sections': sections,

      'archived': archived,

      'createdAt': createdAt,
    };
  }
}
