import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {

  final String id;

  final String name;

  final String examType;

  final List<String> groups;

  final List<String> classes;

  final List<Map<String, dynamic>>
      subjects;

  final bool gradingEnabled;

  final bool remarksEnabled;

  final bool attendanceEnabled;

  final List<dynamic> customFields;

  final bool published;

  final Timestamp? createdAt;

  ExamModel({

    required this.id,

    required this.name,

    required this.examType,

    required this.groups,

    required this.classes,

    required this.subjects,

    required this.gradingEnabled,

    required this.remarksEnabled,

    required this.attendanceEnabled,

    required this.customFields,

    required this.published,

    this.createdAt,
  });

  factory ExamModel.fromFirestore(
    DocumentSnapshot doc,
  ) {

    final data =
        doc.data() as Map<String, dynamic>;

    return ExamModel(

      id: doc.id,

      name: data['name'] ?? '',

      examType:
          data['examType'] ?? '',

      groups:
          List<String>.from(
        data['groups'] ?? [],
      ),

      classes:
          List<String>.from(
        data['classes'] ?? [],
      ),

      subjects:
          List<Map<String, dynamic>>.from(
        data['subjects'] ?? [],
      ),

      gradingEnabled:
          data['gradingEnabled'] ??
              false,

      remarksEnabled:
          data['remarksEnabled'] ??
              false,

      attendanceEnabled:
          data['attendanceEnabled'] ??
              false,

      customFields:
          List<dynamic>.from(
        data['customFields'] ?? [],
      ),

      published:
          data['published'] ?? false,

      createdAt:
          data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {

    return {

      'name': name,

      'examType': examType,

      'groups': groups,

      'classes': classes,

      'subjects': subjects,

      'gradingEnabled':
          gradingEnabled,

      'remarksEnabled':
          remarksEnabled,

      'attendanceEnabled':
          attendanceEnabled,

      'customFields':
          customFields,

      'published': published,

      'createdAt': createdAt,
    };
  }
}
