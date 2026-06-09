import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestoreStudentsScreen extends StatelessWidget {
  final String schoolId;

  const RestoreStudentsScreen({super.key, required this.schoolId});

  Future<void> _restoreStudent(
    BuildContext context,
    String studentId,
    Map<String, dynamic> data,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final restored = Map<String, dynamic>.from(data)..remove('deletedAt');

    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(studentId)
        .set(restored);

    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('deleted_students')
        .doc(studentId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student restored')),
      );
    }
  }

  Future<void> _deletePermanently(
    BuildContext context,
    String studentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: const Text(
          'This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('deleted_students')
        .doc(studentId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student permanently deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore Students')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('deleted_students')
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No deleted students',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString();
              final className = (data['className'] ?? '').toString();
              final section = (data['section'] ?? '').toString();

              return ListTile(
                title: Text(name),
                subtitle: Text(
                  [className, section].where((e) => e.isNotEmpty).join(' '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.green),
                      tooltip: 'Restore',
                      onPressed: () =>
                          _restoreStudent(context, doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(
                          Icons.delete_forever, color: Colors.red),
                      tooltip: 'Delete permanently',
                      onPressed: () =>
                          _deletePermanently(context, doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
