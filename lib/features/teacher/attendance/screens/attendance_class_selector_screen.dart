import 'package:flutter/material.dart';

import 'quick_attendance_screen.dart';

class AttendanceClassSelectorScreen extends StatelessWidget {
  final String schoolId;
  final String teacherId;
  final Map<String, dynamic> teacherData;

  const AttendanceClassSelectorScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.teacherData,
  });

  @override
  Widget build(BuildContext context) {



final attendanceClasses = <String>[];

if (teacherData['classTeacherOf'] != null) {
  attendanceClasses.add(
    '${teacherData['classTeacherOf']['classId']} ${teacherData['classTeacherOf']['sectionId']}',
  );
}

attendanceClasses.addAll(
  List<String>.from(
    teacherData['attendanceClasses'] ?? [],
  ),
);

final classes =
    attendanceClasses.toSet().toList();





    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Class',
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (context, index) {

          final item =
              classes[index];

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.class_,
              ),
              title: Text(item),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () {

                final parts =
                    item.split(' ');

                final section =
                    parts.last;

                final className =
                    item.replaceAll(
                  ' $section',
                  '',
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuickAttendanceScreen(
                      schoolId: schoolId,
                      teacherId: teacherId,

                      teacherData: {
                        ...teacherData,

                        'selectedAttendanceClass':
                            className,

                        'selectedAttendanceSection':
                            section,
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}