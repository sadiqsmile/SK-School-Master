import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'deleted_subjects_screen.dart';
import '../services/subject_service.dart';

class SubjectsScreen extends StatefulWidget {
  final String schoolId;

  const SubjectsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SubjectsScreen> createState() =>
      _SubjectsScreenState();
}

class _SubjectsScreenState
    extends State<SubjectsScreen> {


void _showDeleteDialog(
  String subjectId,
) {

  showDialog(

    context: context,

    builder: (_) {

      return AlertDialog(

        title: const Text(
          "Delete Subject",
        ),

        content: const Text(
          "Are you sure you want to delete this subject?",
        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(context);
            },

            child: const Text(
              "Cancel",
            ),
          ),

          ElevatedButton.icon(

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red,
            ),

            onPressed: () async {

              Navigator.pop(context);

              await FirebaseFirestore
                  .instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('subjects')
                  .doc(subjectId)
                  .update({

                'archived': true,
              });
            },

            icon: const Icon(
              Icons.delete,
              color: Colors.white,
            ),

            label: const Text(
              "Delete",
            ),
          ),
        ],
      );
    },
  );
}
  
  
  


  
  











  final SubjectService _service =
      SubjectService();

  final TextEditingController
      searchController =
          TextEditingController();

  String search = "";

  final List<String> groups = [
    "Nursery",
    "Primary",
    "Middle School",
    "High School",
    "College",
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF5F5F7),


      appBar: AppBar(
actions: [

  IconButton(

    icon: const Icon(
      Icons.settings,
    ),

    onPressed: () {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (_) =>
              DeletedSubjectsScreen(

            schoolId:
                widget.schoolId,
          ),
        ),
      );
    },
  ),
],
        title: const Text(
          "Subjects",
        ),

        elevation: 0,

        backgroundColor: Colors.white,
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        backgroundColor:
            const Color(0xff5B5FEF),

        onPressed: () {
          _showAddSubjectSheet();
        },

        icon: const Icon(Icons.add),

        label: const Text(
          "Add Subject",
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
                setState(() {
                  search = v;
                });
              },

              decoration: InputDecoration(

                hintText:
                    "Search subjects...",

                prefixIcon:
                    const Icon(Icons.search),

                filled: true,

                fillColor:
                    const Color(0xffF3F4F6),

                border: OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(14),

                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(

            child:
                StreamBuilder<QuerySnapshot>(

              stream:
                  _service.getSubjects(
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

                filtered.sort((a, b) {

                  final aData =
                      a.data()
                          as Map<String, dynamic>;

                  final bData =
                      b.data()
                          as Map<String, dynamic>;

                  return (aData['name'] ?? '')
                      .toString()
                      .compareTo(
                    (bData['name'] ?? '')
                        .toString(),
                  );
                });

                if (filtered.isEmpty) {

                  return const Center(

                    child: Text(
                      "No subjects found",
                    ),
                  );
                }

                return ListView.separated(

                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      filtered.length,

                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    height: 10,
                  ),

                  itemBuilder:
                      (context, index) {

                    final doc =
                        filtered[index];

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final subjectGroups =
                        List<String>.from(
                      data['groups'] ?? [],
                    );

                    return Container(

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),

                      child: Row(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Container(

                            width: 40,
                            alignment:
                                Alignment.center,

                            child: Text(

                              "${index + 1}",

                              style:
                                  const TextStyle(

                                fontSize: 16,

                                fontWeight:
                                    FontWeight.bold,

                                color: Color(
                                  0xff5B5FEF,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(

                                  (data['name'] ?? '')
                                      .toString()
                                      .toUpperCase(),

                                  style:
                                      const TextStyle(

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),

                                if (subjectGroups
                                    .isNotEmpty)

                                  Padding(

                                    padding:
                                        const EdgeInsets.only(
                                      top: 8,
                                    ),

                                    child: Wrap(

                                      spacing: 6,

                                      runSpacing: 6,

                                      children:
                                          subjectGroups
                                              .map((g) {

                                        return Container(

                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),

                                          decoration:
                                              BoxDecoration(

                                            color:
                                                const Color(
                                              0xffEEF2FF,
                                            ),

                                            borderRadius:
                                                BorderRadius.circular(
                                              8,
                                            ),
                                          ),

                                          child: Text(

                                            g,

                                            style:
                                                const TextStyle(

                                              fontSize: 11,

                                              color: Color(
                                                0xff5B5FEF,
                                              ),
                                            ),
                                          ),
                                        );

                                      }).toList(),
                                    ),
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

                                      _showAddSubjectSheet(
                                        editData:
                                            data,

                                        subjectId:
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

    Future.delayed(
      Duration.zero,

      () {

        _showDeleteDialog(
          doc.id,
        );
      },
    );
  },

  child: const Text(
    "Delete",
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














  void _showAddSubjectSheet({

    Map<String, dynamic>? editData,
    String? subjectId,

  }) {

    final bool isEdit =
        editData != null;

    final nameController =
        TextEditingController(

      text:
          editData?['name'] ?? '',
    );

    List<String> selectedGroups =
        List<String>.from(
      editData?['groups'] ?? [],
    );

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      builder: (_) {

        return StatefulBuilder(

          builder:
              (context, setSheetState) {

            return Padding(

              padding: EdgeInsets.only(

                left: 20,
                right: 20,
                top: 20,

                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        20,
              ),

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      isEdit
                          ? "Edit Subject"
                          : "Add Subject",

                      style:
                          const TextStyle(

                        fontSize: 20,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    TextField(

                      controller:
                          nameController,

                      textCapitalization:
                          TextCapitalization
                              .characters,

                      decoration:
                          InputDecoration(

                        labelText:
                            "Subject Name",

                        border:
                            OutlineInputBorder(

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(

                      "Applicable Groups",

                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Wrap(

                      spacing: 10,
                      runSpacing: 10,

                      children:
                          groups.map((group) {

                        final selected =
                            selectedGroups
                                .contains(group);

                        return GestureDetector(

                          onTap: () {

                            setSheetState(() {

                              if (selected) {

                                selectedGroups
                                    .remove(group);

                              } else {

                                selectedGroups
                                    .add(group);
                              }
                            });
                          },

                          child: Container(

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),

                            decoration:
                                BoxDecoration(

                              color: selected
                                  ? const Color(
                                      0xff5B5FEF,
                                    )
                                  : Colors.white,

                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              border: Border.all(

                                color: selected
                                    ? const Color(
                                        0xff5B5FEF,
                                      )
                                    : Colors.grey.shade300,
                              ),
                            ),

                            child: Text(

                              group,

                              style: TextStyle(

                                color: selected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );

                      }).toList(),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(

                      width: double.infinity,

                      child: ElevatedButton(

                        onPressed: () async {

                          final name =
                              nameController.text
                                  .trim()
                                  .toUpperCase();

                          if (name.isEmpty) {

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(

                              const SnackBar(
                                content: Text(
                                  "Enter subject name",
                                ),
                              ),
                            );

                            return;
                          }

                          if (isEdit) {

                            await _service
                                .updateSubject(

                              schoolId:
                                  widget.schoolId,

                              subjectId:
                                  subjectId!,

                              name: name,

                              shortName: '',

                              groups:
                                  selectedGroups,
                            );

                          } else {

                            await _service
                                .addSubject(

                              schoolId:
                                  widget.schoolId,

                              name: name,

                              shortName: '',

                              groups:
                                  selectedGroups,
                            );
                          }

                          if (!mounted) return;

                          Navigator.pop(context);
                        },

                        style:
                            ElevatedButton.styleFrom(

                          backgroundColor:
                              const Color(
                            0xff5B5FEF,
                          ),

                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),

                        child: Text(

                          isEdit
                              ? "Update Subject"
                              : "Save Subject",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}