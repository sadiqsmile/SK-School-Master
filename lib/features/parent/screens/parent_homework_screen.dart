import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ParentHomeworkScreen extends StatelessWidget {
  final String schoolId;
  final String studentId;
  final Map<String, dynamic> studentData;

  const ParentHomeworkScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Homework"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('homework')
            .where('classId', isEqualTo: studentData['classId'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final sections = List<String>.from(data['sections'] ?? []);
            return sections.contains(studentData['section']);
          }).toList();

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff111827),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${data['subjectName']} • ${data['className']}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            data['dueDate'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xff5B5FEF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffDCFCE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "Active Homework",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xff166534),
                            ),
                          ),
                        ),
                      ],
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xffEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Homework Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Homework shared by teachers\nwill appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
