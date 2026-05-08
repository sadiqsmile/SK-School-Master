import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class ArchivedTeachersScreen extends StatelessWidget {

  final String schoolId;

  const ArchivedTeachersScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {

    return AdminLayout(
      title: 'Archived Teachers',

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('teachers')
            .where('archived', isEqualTo: true)
            .orderBy('archivedAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.archive_outlined,
                      size: 42,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "No Archived Teachers",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff374151),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Teachers you delete will appear here\nand can be restored anytime.",
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

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),

            itemBuilder: (context, index) {

              final doc = docs[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              final name =
                  data['name'] as String? ?? 'Unknown';

              final email =
                  data['email'] as String? ?? '';

              final photoUrl =
                  data['photoUrl'] as String? ?? '';

              final archivedAt =
                  data['archivedAt'] as Timestamp?;

              final archivedDate = archivedAt != null
                  ? _formatDate(archivedAt.toDate())
                  : 'Unknown date';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade100,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                child: Row(
                  children: [

                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          const Color(0xffF4F5FB),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              name
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff5B5FEF),
                              ),
                            )
                          : null,
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1F2937),
                            ),
                          ),

                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(
                                Icons.archive_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Archived $archivedDate",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () =>
                          _restore(context, doc.id),

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xff5B5FEF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),

                      child: const Text(
                        "Restore",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Future<void> _restore(
    BuildContext context,
    String teacherId,
  ) async {

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(teacherId)
        .update({
      'archived': false,
      'archivedAt': null,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Teacher restored successfully âœ…"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}
