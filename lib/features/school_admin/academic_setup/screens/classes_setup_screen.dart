import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/class_service.dart';

class ClassesSetupScreen extends StatefulWidget {

  final String schoolId;

  const ClassesSetupScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<ClassesSetupScreen> createState() =>
      _ClassesSetupScreenState();
}

class _ClassesSetupScreenState
    extends State<ClassesSetupScreen> {

  final ClassService _service =
      ClassService();

  final TextEditingController
      searchController =
          TextEditingController();

  String search = "";

  final List<String> schoolGroups = [

    "Nursery",
    "Primary",
    "Middle School",
    "High School",
    "College",
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Classes & Sections",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        backgroundColor:
            const Color(0xff5B5FEF),

        onPressed: () {
          _showClassSheet();
        },

        icon: const Icon(Icons.add),

        label: const Text(
          "Add Class",
        ),
      ),

      body: Column(
        children: [

          Container(
            color: Colors.white,

            padding:
                const EdgeInsets.all(16),

            child: TextField(

              controller: searchController,

              onChanged: (v) {
                setState(() => search = v);
              },

              decoration: InputDecoration(

                hintText:
                    "Search classes...",

                prefixIcon:
                    const Icon(Icons.search),

                filled: true,

                fillColor:
                    const Color(0xffF8FAFC),

                border: OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(16),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(

              stream:
                  _service.getClasses(
                widget.schoolId,
              ),

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

                  if (data['archived'] ==
                      true) {
                    return false;
                  }

                  final name =
                      (data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  return name.contains(
                    search.toLowerCase(),
                  );

                }).toList();

                if (filtered.isEmpty) {

                  return _emptyState();
                }

                return ListView.builder(

                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      filtered.length,

                  itemBuilder:
                      (context, index) {

                    final doc =
                        filtered[index];

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final sections =
                        List<String>.from(
                      data['sections'] ?? [],
                    );

                    return Container(

                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),

                      padding:
                          const EdgeInsets.all(
                        18,
                      ),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        border: Border.all(
                          color:
                              Colors.grey.shade100,
                        ),

                        boxShadow: [

                          BoxShadow(
                            color: Colors.black
                                .withOpacity(
                              0.02,
                            ),

                            blurRadius: 10,

                            offset:
                                const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),

                      child: Row(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Container(

                            height: 54,
                            width: 54,

                            decoration:
                                BoxDecoration(

                              color:
                                  const Color(
                                0xffEEF2FF,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),

                            child: Center(

                              child: Text(

                                data['name']
                                    .toString()
                                    .replaceAll(
                                      "Class ",
                                      "",
                                    ),

                                style:
                                    const TextStyle(

                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight
                                          .w700,

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
                                  data['name'] ??
                                      '',

                                  style:
                                      const TextStyle(

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight
                                            .w600,

                                    color: Color(
                                      0xff111827,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(

                                  data['group'] ??
                                      '',

                                  style:
                                      TextStyle(

                                    fontSize: 13,

                                    color:
                                        Colors.grey
                                            .shade600,
                                  ),
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                Wrap(

                                  spacing: 8,
                                  runSpacing: 8,

                                  children:
                                      sections.map(
                                    (section) {

                                      return Container(

                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              10,
                                          vertical:
                                              6,
                                        ),

                                        decoration:
                                            BoxDecoration(

                                          color:
                                              const Color(
                                            0xffF5F3FF,
                                          ),

                                          borderRadius:
                                              BorderRadius.circular(
                                            10,
                                          ),
                                        ),

                                        child: Text(

                                          section,

                                          style:
                                              const TextStyle(

                                            fontSize:
                                                12,

                                            fontWeight:
                                                FontWeight.w500,

                                            color:
                                                Color(
                                              0xff5B5FEF,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ],
                            ),
                          ),

                          PopupMenuButton(

                            itemBuilder:
                                (context) => [

                              PopupMenuItem(

                                onTap: () {

                                  Future.delayed(
                                    Duration.zero,

                                    () {

                                      _showClassSheet(

                                        editData:
                                            data,

                                        classId:
                                            doc.id,
                                      );
                                    },
                                  );
                                },

                                child: const Text(
                                  "Edit",
                                ),
                              ),

                              PopupMenuItem(

                                onTap: () {

                                  _service
                                      .archiveClass(

                                    schoolId:
                                        widget
                                            .schoolId,

                                    classId:
                                        doc.id,
                                  );
                                },

                                child: const Text(
                                  "Archive",
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
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {

    return Center(
      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(

            height: 90,
            width: 90,

            decoration: const BoxDecoration(
              color: Color(
                0xffEEF2FF,
              ),

              shape: BoxShape.circle,
            ),

            child: const Icon(

              Icons.school_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "No Classes Added",

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Add classes and sections to manage\nstudents, timetable and exams.",

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

  // TODO: implement full sheet in next step
  void _showClassSheet({
    Map<String, dynamic>? editData,
    String? classId,
  }) {}
}
