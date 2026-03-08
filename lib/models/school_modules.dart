// School-level feature toggles (modules).
//
// Stored at: `schools/{schoolId}/settings/modules`
//
// Firestore document example:
// {
//   "teachers": true,
//   "students": true,
//   "attendance": true,
//   "exams": true,
//   "parents": false,
//   "fees": false,
//   "homework": true,
//   "messages": false
// }
//
// Notes:
// - Missing fields default to `true` (backward compatible).
// - Unknown fields are ignored by this model.

enum SchoolModuleKey {
  teachers,
  students,
  attendance,
  exams,
  parents,
  fees,
  homework,
  messages,
}

extension SchoolModuleKeyX on SchoolModuleKey {
  String get key => name;

  String get label {
    switch (this) {
      case SchoolModuleKey.teachers:
        return 'Teachers';
      case SchoolModuleKey.students:
        return 'Students';
      case SchoolModuleKey.attendance:
        return 'Attendance';
      case SchoolModuleKey.exams:
        return 'Exams';
      case SchoolModuleKey.parents:
        return 'Parents App';
      case SchoolModuleKey.fees:
        return 'Fees Management';
      case SchoolModuleKey.homework:
        return 'Homework';
      case SchoolModuleKey.messages:
        return 'Messages & Notifications';
    }
  }
}

class SchoolModules {
  const SchoolModules({
    required this.teachers,
    required this.students,
    required this.attendance,
    required this.exams,
    required this.parents,
    required this.fees,
    required this.homework,
    required this.messages,
  });

  /// Default is permissive (all enabled) to avoid breaking existing schools.
  factory SchoolModules.defaults() {
    return const SchoolModules(
      teachers: true,
      students: true,
      attendance: true,
      exams: true,
      parents: true,
      fees: true,
      homework: true,
      messages: true,
    );
  }

  factory SchoolModules.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};

    // Missing values default to true.
    bool boolForKey(String key) {
      final v = d[key];
      if (v is bool) return v;
      return true;
    }

    return SchoolModules(
      teachers: boolForKey(SchoolModuleKey.teachers.key),
      students: boolForKey(SchoolModuleKey.students.key),
      attendance: boolForKey(SchoolModuleKey.attendance.key),
      exams: boolForKey(SchoolModuleKey.exams.key),
      parents: boolForKey(SchoolModuleKey.parents.key),
      fees: boolForKey(SchoolModuleKey.fees.key),
      homework: boolForKey(SchoolModuleKey.homework.key),
      messages: boolForKey(SchoolModuleKey.messages.key),
    );
  }

  final bool teachers;
  final bool students;
  final bool attendance;
  final bool exams;
  final bool parents;
  final bool fees;
  final bool homework;
  final bool messages;

  bool isEnabled(SchoolModuleKey key) {
    switch (key) {
      case SchoolModuleKey.teachers:
        return teachers;
      case SchoolModuleKey.students:
        return students;
      case SchoolModuleKey.attendance:
        return attendance;
      case SchoolModuleKey.exams:
        return exams;
      case SchoolModuleKey.parents:
        return parents;
      case SchoolModuleKey.fees:
        return fees;
      case SchoolModuleKey.homework:
        return homework;
      case SchoolModuleKey.messages:
        return messages;
    }
  }

  SchoolModules copyWith({
    bool? teachers,
    bool? students,
    bool? attendance,
    bool? exams,
    bool? parents,
    bool? fees,
    bool? homework,
    bool? messages,
  }) {
    return SchoolModules(
      teachers: teachers ?? this.teachers,
      students: students ?? this.students,
      attendance: attendance ?? this.attendance,
      exams: exams ?? this.exams,
      parents: parents ?? this.parents,
      fees: fees ?? this.fees,
      homework: homework ?? this.homework,
      messages: messages ?? this.messages,
    );
  }

  SchoolModules copyWithKey(SchoolModuleKey key, bool enabled) {
    switch (key) {
      case SchoolModuleKey.teachers:
        return copyWith(teachers: enabled);
      case SchoolModuleKey.students:
        return copyWith(students: enabled);
      case SchoolModuleKey.attendance:
        return copyWith(attendance: enabled);
      case SchoolModuleKey.exams:
        return copyWith(exams: enabled);
      case SchoolModuleKey.parents:
        return copyWith(parents: enabled);
      case SchoolModuleKey.fees:
        return copyWith(fees: enabled);
      case SchoolModuleKey.homework:
        return copyWith(homework: enabled);
      case SchoolModuleKey.messages:
        return copyWith(messages: enabled);
    }
  }

  Map<String, bool> toMap() {
    return <String, bool>{
      SchoolModuleKey.teachers.key: teachers,
      SchoolModuleKey.students.key: students,
      SchoolModuleKey.attendance.key: attendance,
      SchoolModuleKey.exams.key: exams,
      SchoolModuleKey.parents.key: parents,
      SchoolModuleKey.fees.key: fees,
      SchoolModuleKey.homework.key: homework,
      SchoolModuleKey.messages.key: messages,
    };
  }
}
