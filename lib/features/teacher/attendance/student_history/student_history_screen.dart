import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'student_details_screen.dart';

class StudentHistoryScreen extends StatefulWidget {

  final String schoolId;
  final String classId;
  final String section;

  const StudentHistoryScreen({

    super.key,

    required this.schoolId,

    required this.classId,

    required this.section,
  });

  @override
  State<StudentHistoryScreen>
      createState() =>
          _StudentHistoryScreenState();
}

class _StudentHistoryScreenState
    extends State<StudentHistoryScreen> {

  String search = '';

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          'Student History',
        ),
      ),

      body: Column(

        children: [

          Padding(

            padding:
                const EdgeInsets.all(12),

            child: TextField(

              decoration:
                  InputDecoration(

                hintText:
                    'Search Student',

                prefixIcon:
                    const Icon(Icons.search),

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              onChanged: (value) {

                setState(() {

                  search =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
            ),
          ),

          Expanded(

            child:
                StreamBuilder<QuerySnapshot>(

              stream: FirebaseFirestore
                  .instance

                  .collection('schools')

                  .doc(widget.schoolId)

                  .collection('students')

                  .where(
                    'classId',
                    isEqualTo:
                        widget.classId,
                  )

                  .where(
                    'section',
                    isEqualTo:
                        widget.section,
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

                final filtered =
                    docs.where((doc) {

                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  final name =
                      (data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  return name.contains(
                    search,
                  );
                }).toList();


filtered.sort((a, b) {

  final aData =
      a.data()
          as Map<String, dynamic>;

  final bData =
      b.data()
          as Map<String, dynamic>;

  final aName =
      (aData['nameLower'] ?? '')
          .toString();

  final bName =
      (bData['nameLower'] ?? '')
          .toString();

  return aName.compareTo(
    bName,
  );
});



                if (filtered.isEmpty) {

                  return const Center(

                    child: Text(
                      'No Students Found',
                    ),
                  );
                }

                return ListView.builder(

                  itemCount:
                      filtered.length,

                  itemBuilder:
                      (context, index) {

                    final student =
                        filtered[index]
                            .data()
                            as Map<String, dynamic>;

                    final photo =
                        student['photoUrl']
                                ?.toString() ??
                            '';

                    final name =
                        student['name']
                                ?.toString() ??
                            '';

                    final admissionNo =
                        student['admissionNo']
                                ?.toString() ??
                            '';

                    return Card(

                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      child: ListTile(

                        leading:
                            CircleAvatar(

                          backgroundImage:
                              photo.isNotEmpty

                                  ? NetworkImage(
                                      photo,
                                    )

                                  : null,

                          child:
                              photo.isEmpty

                                  ? Text(

                                      name.isNotEmpty
                                          ? name[0]
                                          : '?',
                                    )

                                  : null,
                        ),

                        title: Text(
                          name,
                        ),

                        subtitle: Text(
                          admissionNo,
                        ),

                        trailing:
                            const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),

                        onTap: () {

                          Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (_) =>

                                  StudentDetailsScreen(

                                student:
                                    student,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}