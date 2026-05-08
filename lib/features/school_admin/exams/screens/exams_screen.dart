import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../academic_setup/services/class_service.dart';
import '../../academic_setup/services/subject_service.dart';

import '../services/exam_service.dart';

class ExamsScreen
    extends StatefulWidget {

  final String schoolId;

  const ExamsScreen({

    super.key,

    required this.schoolId,
  });

  @override
  State<ExamsScreen> createState() =>
      _ExamsScreenState();
}

class _ExamsScreenState
    extends State<ExamsScreen> {

  final ExamService _service =
      ExamService();

  final SubjectService _subjectService =
      SubjectService();

  final ClassService _classService =
      ClassService();

  final List<String> schoolGroups = [

    "Nursery",
    "Primary",
    "Middle School",
    "High School",
    "College",
  ];

  final List<String> examTypes = [

    "Theory",
    "Practical",
    "Internal",
    "Project",
    "Oral",
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Examinations",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        backgroundColor:
            const Color(0xff5B5FEF),

        onPressed: () {

          _showExamBuilder();
        },

        icon: const Icon(Icons.add),

        label: const Text(
          "Create Exam",
        ),
      ),

      body:
          StreamBuilder<QuerySnapshot>(

        stream:
            _service.getExams(
          widget.schoolId,
        ),

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

            return _emptyState();
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
                      as Map<String,
                          dynamic>;

              final subjects =
                  List<Map<String,
                      dynamic>>.from(

                data['subjects'] ?? [],
              );

              return Container(

                margin:
                    const EdgeInsets.only(
                  bottom: 18,
                ),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),

                  border: Border.all(
                    color:
                        Colors.grey.shade100,
                  ),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.02),

                      blurRadius: 10,

                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),

                child: Padding(

                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Row(

                        children: [

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

                                    fontSize: 18,

                                    fontWeight:
                                        FontWeight
                                            .w700,

                                    color: Color(
                                      0xff111827,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Text(

                                  data['examType'] ??
                                      '',

                                  style:
                                      TextStyle(

                                    fontSize: 13,

                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),

                            decoration:
                                BoxDecoration(

                              color:
                                  data['published']
                                      ? const Color(
                                          0xffDCFCE7,
                                        )
                                      : const Color(
                                          0xffFEF3C7,
                                        ),

                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),

                            child: Text(

                              data['published']
                                  ? "Published"
                                  : "Draft",

                              style:
                                  TextStyle(

                                fontWeight:
                                    FontWeight.w600,

                                color:
                                    data['published']
                                        ? const Color(
                                            0xff166534,
                                          )
                                        : const Color(
                                            0xff92400E,
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Wrap(

                        spacing: 10,
                        runSpacing: 10,

                        children:
                            subjects.map(
                          (subject) {

                            return Container(

                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),

                              decoration:
                                  BoxDecoration(

                                color:
                                    const Color(
                                  0xffEEF2FF,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child: Text(

                                "${subject['subjectName']} (${subject['maxMarks']})",

                                style:
                                    const TextStyle(

                                  fontWeight:
                                      FontWeight.w600,

                                  color: Color(
                                    0xff5B5FEF,
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),

                      const SizedBox(height: 22),

                      Row(

                        children: [

                          Expanded(
                            child: OutlinedButton(

                              onPressed: () {

                                _service
                                    .publishExam(

                                  schoolId:
                                      widget
                                          .schoolId,

                                  examId:
                                      doc.id,
                                );
                              },

                              child: const Text(
                                "Publish",
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: OutlinedButton(

                              onPressed: () {

                                _service
                                    .deleteExam(

                                  schoolId:
                                      widget
                                          .schoolId,

                                  examId:
                                      doc.id,
                                );
                              },

                              child: const Text(
                                "Delete",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(

            height: 90,
            width: 90,

            decoration: BoxDecoration(
              color: const Color(
                0xffEEF2FF,
              ),

              shape: BoxShape.circle,
            ),

            child: const Icon(

              Icons.fact_check_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "No Exams Created",

            style: TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.w700,

              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Create examinations to manage\nmarks, grading and results.",

            textAlign: TextAlign.center,

            style: TextStyle(

              fontSize: 14,

              height: 1.5,

              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showExamBuilder() {

    final examNameController =
        TextEditingController();

    String selectedExamType =
        examTypes.first;

    List<String> selectedGroups =
        [];

    List<String> selectedClasses =
        [];

    bool gradingEnabled = true;

    bool remarksEnabled = true;

    bool attendanceEnabled = false;

    List<Map<String, dynamic>>
        selectedSubjects = [];

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {

        return StatefulBuilder(

          builder: (context, setSheetState) {

            return Container(

              padding: EdgeInsets.only(

                left: 24,
                right: 24,
                top: 24,

                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        24,
              ),

              decoration: const BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),

              child: SingleChildScrollView(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    Center(

                      child: Container(

                        height: 5,
                        width: 60,

                        decoration: BoxDecoration(

                          color: Colors.grey.shade300,

                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(

                      "Create Examination",

                      style: TextStyle(

                        fontSize: 22,

                        fontWeight:
                            FontWeight.w700,

                        color:
                            Color(0xff111827),
                      ),
                    ),

                    const SizedBox(height: 28),

                    TextField(

                      controller:
                          examNameController,

                      decoration:
                          _inputDecoration(
                        "Exam Name",
                      ),
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(

                      value:
                          selectedExamType,

                      decoration:
                          _inputDecoration(
                        "Exam Type",
                      ),

                      items:
                          examTypes.map(
                        (type) {

                          return DropdownMenuItem(

                            value: type,

                            child: Text(type),
                          );

                        },
                      ).toList(),

                      onChanged: (v) {

                        if (v != null) {

                          setSheetState(() {
                            selectedExamType = v;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(

                      "Academic Groups",

                      style: TextStyle(

                        fontSize: 16,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Wrap(

                      spacing: 10,
                      runSpacing: 10,

                      children:
                          schoolGroups.map(
                        (group) {

                          final isSelected =
                              selectedGroups
                                  .contains(
                            group,
                          );

                          return GestureDetector(

                            onTap: () {

                              setSheetState(() {

                                if (isSelected) {

                                  selectedGroups
                                      .remove(
                                    group,
                                  );

                                } else {

                                  selectedGroups
                                      .add(
                                    group,
                                  );
                                }
                              });
                            },

                            child: Container(

                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    14,
                                vertical:
                                    10,
                              ),

                              decoration:
                                  BoxDecoration(

                                color: isSelected
                                    ? const Color(
                                        0xff5B5FEF,
                                      )
                                    : const Color(
                                        0xffEEF2FF,
                                      ),

                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child: Text(

                                group,

                                style:
                                    TextStyle(

                                  fontWeight:
                                      FontWeight.w600,

                                  color: isSelected
                                      ? Colors.white
                                      : const Color(
                                          0xff5B5FEF,
                                        ),
                                ),
                              ),
                            ),
                          );

                        },
                      ).toList(),
                    ),

                    const SizedBox(height: 28),

                    const Text(

                      "Exam Features",

                      style: TextStyle(

                        fontSize: 16,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SwitchListTile(

                      value:
                          gradingEnabled,

                      onChanged: (v) {

                        setSheetState(() {
                          gradingEnabled = v;
                        });
                      },

                      title:
                          const Text(
                        "Enable Grading",
                      ),
                    ),

                    SwitchListTile(

                      value:
                          remarksEnabled,

                      onChanged: (v) {

                        setSheetState(() {
                          remarksEnabled = v;
                        });
                      },

                      title:
                          const Text(
                        "Enable Remarks",
                      ),
                    ),

                    SwitchListTile(

                      value:
                          attendanceEnabled,

                      onChanged: (v) {

                        setSheetState(() {
                          attendanceEnabled = v;
                        });
                      },

                      title:
                          const Text(
                        "Enable Attendance",
                      ),
                    ),

                    const SizedBox(height: 28),

                    StreamBuilder<QuerySnapshot>(

                      stream:
                          _subjectService
                              .getSubjects(
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

                        return Column(

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            const Text(

                              "Subjects",

                              style: TextStyle(

                                fontSize: 16,

                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            ...docs.map((doc) {

                              final data =
                                  doc.data()
                                      as Map<String,
                                          dynamic>;

                              final alreadyAdded =
                                  selectedSubjects.any(
                                (e) =>
                                    e[
                                        'subjectId'] ==
                                    doc.id,
                              );

                              return Container(

                                margin:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),

                                padding:
                                    const EdgeInsets.all(
                                  14,
                                ),

                                decoration:
                                    BoxDecoration(

                                  color:
                                      Colors.white,

                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),

                                  border:
                                      Border.all(
                                    color: Colors
                                        .grey
                                        .shade200,
                                  ),
                                ),

                                child: Row(

                                  children: [

                                    Expanded(
                                      child: Text(

                                        data['name'] ??
                                            '',

                                        style:
                                            const TextStyle(

                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                    ),

                                    Checkbox(

                                      value:
                                          alreadyAdded,

                                      onChanged:
                                          (v) {

                                        setSheetState(() {

                                          if (v ==
                                              true) {

                                            selectedSubjects
                                                .add({

                                              "subjectId":
                                                  doc.id,

                                              "subjectName":
                                                  data['name'],

                                              "maxMarks":
                                                  100,

                                              "passMarks":
                                                  35,

                                              "hasPractical":
                                                  false,
                                            });

                                          } else {

                                            selectedSubjects
                                                .removeWhere(
                                              (e) =>
                                                  e['subjectId'] ==
                                                  doc.id,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );

                            }).toList(),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 34),

                    SizedBox(

                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton(

                        style:
                            ElevatedButton
                                .styleFrom(

                          backgroundColor:
                              const Color(
                            0xff5B5FEF,
                          ),

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),

                        onPressed: () async {

                          await _service
                              .createExam(

                            schoolId:
                                widget.schoolId,

                            data: {

                              "name":
                                  examNameController
                                      .text
                                      .trim(),

                              "examType":
                                  selectedExamType,

                              "groups":
                                  selectedGroups,

                              "classes":
                                  selectedClasses,

                              "subjects":
                                  selectedSubjects,

                              "gradingEnabled":
                                  gradingEnabled,

                              "remarksEnabled":
                                  remarksEnabled,

                              "attendanceEnabled":
                                  attendanceEnabled,

                              "customFields":
                                  [],
                            },
                          );

                          if (!mounted) return;

                          Navigator.pop(context);
                        },

                        child: const Text(

                          "Create Exam",

                          style: TextStyle(

                            fontSize: 15,

                            fontWeight:
                                FontWeight.w600,

                            color: Colors.white,
                          ),
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

  InputDecoration _inputDecoration(
    String label,
  ) {

    return InputDecoration(

      labelText: label,

      filled: true,

      fillColor:
          const Color(0xffF8FAFC),

      border: OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(16),

        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(16),

        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      focusedBorder:
          const OutlineInputBorder(

        borderRadius:
            BorderRadius.all(
          Radius.circular(16),
        ),

        borderSide: BorderSide(
          color: Color(0xff5B5FEF),
        ),
      ),
    );
  }
}
