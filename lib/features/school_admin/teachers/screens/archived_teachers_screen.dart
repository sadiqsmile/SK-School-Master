import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/current_school_provider.dart';

class ArchivedTeachersScreen extends ConsumerWidget {

  const ArchivedTeachersScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(

        title: const Text(
          'Archived Teachers',
        ),

        backgroundColor:
            Colors.white,

        elevation: 0,
      ),

      body: FutureBuilder(

        future: ref.read(
          currentSchoolProvider.future,
        ),

        builder: (context, schoolSnap) {

          if (!schoolSnap.hasData) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final school =
              schoolSnap.data!;

          return StreamBuilder(

            stream: FirebaseFirestore
                .instance
                .collection('schools')
                .doc(school.id)
                .collection('teachers')
                .where(
                  'archived',
                  isEqualTo: true,
                )
                .snapshots(),

            builder: (context, snapshot) {

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
                    'No Archived Teachers',
                  ),
                );
              }




return Center(

  child: ConstrainedBox(

    constraints:
        const BoxConstraints(

      maxWidth: 760,
    ),

    child: ListView.builder(

      padding:
          const EdgeInsets.all(
        20,
      ),

      itemCount:
          docs.length,

      itemBuilder:
          (context, index) {

        final doc =
            docs[index];

        final data =
            doc.data();

        final name =
            (data['name'] ?? '')
                .toString();

        final email =
            (data['email'] ?? '')
                .toString();

        final phone =
            (data['phone'] ?? '')
                .toString();

        return Container(

          margin:
              const EdgeInsets.only(
            bottom: 18,
          ),

          padding:
              const EdgeInsets.all(
            18,
          ),

          decoration:
              BoxDecoration(

            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              24,
            ),

            boxShadow: const [

              BoxShadow(

                color: Color(
                  0x08000000,
                ),

                blurRadius: 18,

                offset: Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),

          child: Column(

            children: [

              Row(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Container(

                    width: 58,
                    height: 58,

                    decoration:
                        BoxDecoration(

                      color:
                          const Color(
                        0xffEEF2FF,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: Center(

                      child: Text(

                        name.isNotEmpty
                            ? name[0]
                                .toUpperCase()
                            : '?',

                        style:
                            const TextStyle(

                          fontSize: 24,

                          fontWeight:
                              FontWeight.w700,

                          color: Color(
                            0xff5B5FEF,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(

                          name,

                          style:
                              const TextStyle(

                            fontSize: 17,

                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),




                        Row(

                          children: [

                            const Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Color(
                                0xff6B7280,
                              ),
                            ),

                            const SizedBox(
                              width: 6,
                            ),

                            Expanded(

                              child: Text(

                                email,

                                style:
                                    const TextStyle(

                                  fontSize:
                                      13,

                                  color:
                                      Color(
                                    0xff6B7280,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Row(

                          children: [

                            const Icon(
                              Icons.call_outlined,
                              size: 16,
                              color: Color(
                                0xff6B7280,
                              ),
                            ),

                            const SizedBox(
                              width: 6,
                            ),

                            Text(

                              phone,

                              style:
                                  const TextStyle(

                                fontSize:
                                    13,

                                color:
                                    Color(
                                  0xff6B7280,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

Align(

  alignment: Alignment.centerLeft,

  child: Wrap(

    spacing: 12,

    runSpacing: 12,

    children: [

      ElevatedButton.icon(

        onPressed: () async {

          await FirebaseFirestore
              .instance
              .collection('schools')
              .doc(school.id)
              .collection('teachers')
              .doc(doc.id)
              .update({

            'archived': false,
          });
        },

        style:
            ElevatedButton.styleFrom(

          backgroundColor:
              const Color(
            0xffEEF2FF,
          ),

          foregroundColor:
              const Color(
            0xff5B5FEF,
          ),

          elevation: 0,

          padding:
              const EdgeInsets.symmetric(

            horizontal: 18,
            vertical: 14,
          ),

          shape:
              RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),

        icon: const Icon(
          Icons.restore_rounded,
          size: 18,
        ),

        label: const Text(
          'Restore',
        ),
      ),

      ElevatedButton.icon(

        onPressed: () async {

          final ok =
              await showDialog<bool>(

            context: context,

            builder: (_) {

              return AlertDialog(

                title: const Text(
                  'Delete Permanently?',
                ),

                content: const Text(
                  'This action cannot be undone.',
                ),

                actions: [

                  TextButton(

                    onPressed: () {

                      Navigator.pop(
                        context,
                        false,
                      );
                    },

                    child: const Text(
                      'Cancel',
                    ),
                  ),

                  ElevatedButton(

                    style:
                        ElevatedButton.styleFrom(

                      backgroundColor:
                          Colors.red,
                    ),

                    onPressed: () {

                      Navigator.pop(
                        context,
                        true,
                      );
                    },

                    child: const Text(
                      'Delete',
                    ),
                  ),
                ],
              );
            },
          );

          if (ok != true)
            return;

         final teacherId = doc.id;

await FirebaseFirestore
    .instance
    .collection('schools')
    .doc(school.id)
    .collection('teachers')
    .doc(teacherId)
    .delete();

await FirebaseFirestore
    .instance
    .collection('users')
    .doc(teacherId)
    .delete();



        },

        style:
            ElevatedButton.styleFrom(

          backgroundColor:
              const Color(
            0xffFEF2F2,
          ),

          foregroundColor:
              const Color(
            0xffDC2626,
          ),

          elevation: 0,

          padding:
              const EdgeInsets.symmetric(

            horizontal: 18,
            vertical: 14,
          ),

          shape:
              RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),

        icon: const Icon(
          Icons.delete_outline,
          size: 18,
        ),

        label: const Text(
          'Delete',
        ),
      ),
    ],
  ),
),



          
            
            
            
            
            ],
          ),
        );
      },
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