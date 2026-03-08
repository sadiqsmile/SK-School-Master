// models/teacher.dart
class Teacher {
  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.subjects = const <String>[],
    this.classes = const <String>[],
    this.sections = const <String>[],
    this.teacherUid,
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  /// Human-readable subjects (e.g. "Math").
  final List<String> subjects;

  /// Stored as strings per current spec (e.g. "Class 5").
  final List<String> classes;

  /// Stored as strings (e.g. "A").
  final List<String> sections;

  /// Optional link to the Auth user record in `/users/{uid}`.
  final String? teacherUid;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'subjects': subjects,
      'classes': classes,
      'sections': sections,
      if (teacherUid != null) 'teacherUid': teacherUid,
    };
  }

  factory Teacher.fromMap(String id, Map<String, dynamic> data) {
    final subjectsRaw = (data['subjects'] as List?) ?? const [];
    final classesRaw = (data['classes'] as List?) ?? const [];
    final sectionsRaw = (data['sections'] as List?) ?? const [];

    return Teacher(
      id: id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      subjects: subjectsRaw.map((e) => e.toString()).toList(growable: false),
      classes: classesRaw.map((e) => e.toString()).toList(growable: false),
      sections: sectionsRaw.map((e) => e.toString()).toList(growable: false),
      teacherUid: (data['teacherUid'] ?? '').toString().trim().isEmpty
          ? null
          : (data['teacherUid'] ?? '').toString(),
    );
  }
}
