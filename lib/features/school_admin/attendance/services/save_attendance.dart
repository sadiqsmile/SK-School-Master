import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveAttendance({
  required String schoolId,
  required String classId,
  required String sectionId,
  required DateTime date,
  required List<Map<String, dynamic>> students,
}) async {
  final db = FirebaseFirestore.instance;

  final dateKey =
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  final classKey = "class_${classId}_${sectionId}";

  int present = 0, absent = 0, late = 0, leave = 0;

  for (var s in students) {
    switch (s['status']) {
      case 'Present':
        present++;
        break;
      case 'Absent':
        absent++;
        break;
      case 'Late':
        late++;
        break;
      case 'Leave':
        leave++;
        break;
    }
  }

  final total = students.length;

  await db
      .collection('schools')
      .doc(schoolId)
      .collection('attendance')
      .doc(dateKey)
      .collection('meta')
      .doc(classKey)
      .set({
    "date": dateKey,
    "counts": {
      "present": present,
      "absent": absent,
      "late": late,
      "leave": leave,
      "total": total,
    }
  }, SetOptions(merge: true));
}
