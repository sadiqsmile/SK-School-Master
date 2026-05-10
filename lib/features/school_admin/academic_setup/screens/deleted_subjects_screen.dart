import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeletedSubjectsScreen
    extends StatelessWidget {

  final String schoolId;

  const DeletedSubjectsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF5F5F7),

      appBar: AppBar(

        title: const Text(
          "Deleted Subjects",
        ),

        backgroundColor:
            Colors.white,

        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore
            .instance
            .collection('schools')
            .doc(schoolId)
            .collection('subjects')
            .where(
              'archived',
              isEqualTo: true,
            )
            .snapshots(),

        builder:
            (context, snapshot) {

          if (!snapshot.hasData) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {

            return const Center(

              child: Text(
                "No deleted subjects",
              ),
            );
          }

          return ListView.builder(

            padding:
                const EdgeInsets.all(16),

            itemCount:
                docs.length,

            itemBuilder:
                (context, index) {

              final doc =
                  docs[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

              return Container(

                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: ListTile(

                  title: Text(

                    (data['name'] ?? '')
                        .toString()
                        .toUpperCase(),
                  ),

                  trailing:
                      ElevatedButton(

                    onPressed: () async {

                      await FirebaseFirestore
                          .instance
                          .collection(
                            'schools',
                          )
                          .doc(schoolId)
                          .collection(
                            'subjects',
                          )
                          .doc(doc.id)
                          .update({

                        'archived':
                            false,
                      });
                    },

                    child: const Text(
                      "Restore",
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}