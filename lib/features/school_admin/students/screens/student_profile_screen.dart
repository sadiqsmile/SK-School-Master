import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const StudentProfileScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final className = (data['className'] ?? '').toString();
    final section = (data['section'] ?? '').toString();
    final photoUrl = (data['photoUrl'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 👤 PHOTO
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFEDE9FE),
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      name.isEmpty ? '?' : name[0],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B21B6),
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 12),

            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              '$className - $section',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}