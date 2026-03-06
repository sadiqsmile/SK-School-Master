// features/school_admin/teachers/widgets/teacher_card.dart
import 'package:flutter/material.dart';

class TeacherCard extends StatelessWidget {
  const TeacherCard({super.key, required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(name), subtitle: Text(email)),
    );
  }
}
