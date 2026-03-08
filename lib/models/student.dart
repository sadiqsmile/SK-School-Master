// models/student.dart
class Student {
  final String id;
  final String name;
  final String admissionNo;
  final String classId;
  final String section;
  final String academicYear;
  final String status;
  final String parentName;
  final String parentPhone;

  const Student({
    required this.id,
    required this.name,
    required this.admissionNo,
    required this.classId,
    required this.section,
    this.academicYear = '',
    this.status = '',
    required this.parentName,
    required this.parentPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'admissionNo': admissionNo,
      'classId': classId,
      'section': section,
      'academicYear': academicYear,
      'status': status,
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
      academicYear: (data['academicYear'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      parentName: (data['parentName'] ?? '').toString(),
      parentPhone: (data['parentPhone'] ?? '').toString(),
    );
  }
}
