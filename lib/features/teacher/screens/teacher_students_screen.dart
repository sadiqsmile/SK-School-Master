import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/attendance/providers/students_by_class_section_provider.dart';

class TeacherStudentsScreen extends ConsumerWidget {
  const TeacherStudentsScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(
      studentsByClassSectionProvider(
        TeacherClassSectionKey(classId: classId, sectionId: sectionId),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Students • Class $classId$sectionId')),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load students: $e')),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          return ListView.separated(
            itemCount: snapshot.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = snapshot.docs[i];
              final data = doc.data();
              final name = (data['name'] ?? '').toString();
              final admissionNo = (data['admissionNo'] ?? doc.id).toString();

              return ListTile(
                title: Text(name.isEmpty ? 'Student' : name),
                subtitle: Text('Admission: $admissionNo'),
              );
            },
          );
        },
      ),
    );
  }
}
