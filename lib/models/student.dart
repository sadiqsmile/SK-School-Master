// models/student.dart
class Student {
  final String id;
  final String name;
  final String admissionNo;
  final String classId;
  final String section;
  final String parentName;
  final String parentPhone;

  const Student({
    required this.id,
    required this.name,
    required this.admissionNo,
    required this.classId,
    required this.section,
    required this.parentName,
    required this.parentPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'admissionNo': admissionNo,
      'classId': classId,
      'section': section,
      'parentName': parentName,
      'parentPhone': parentPhone,
    };
  }

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      name: (data['name'] ?? '').toString(),
      admissionNo: (data['admissionNo'] ?? '').toString(),
      classId: (data['classId'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      parentName: (data['parentName'] ?? '').toString(),
      parentPhone: (data['parentPhone'] ?? '').toString(),
    );
  }
}
