import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../academic_setup/services/class_service.dart';
import '../../academic_setup/services/subject_service.dart';

import '../services/teacher_assignment_service.dart';

class TeacherAssignmentScreen
    extends StatefulWidget {

  final String schoolId;

  final String teacherId;

  final Map<String, dynamic>
      teacherData;

  const TeacherAssignmentScreen({

    super.key,

    required this.schoolId,

    required this.teacherId,

    required this.teacherData,
  });

  @override
  State<TeacherAssignmentScreen>
      createState() =>
          _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState
    extends State<TeacherAssignmentScreen> {

  // ── Services ──────────────────────────────────────────────

  final SubjectService _subjectService =
      SubjectService();

  final ClassService _classService =
      ClassService();

  final TeacherAssignmentService
      _assignmentService =
          TeacherAssignmentService();

  // ── State ─────────────────────────────────────────────────

  Map<String, dynamic>? selectedSubject;

  List<Map<String, dynamic>>
      assignedClasses = [];

  Map<String, dynamic>? classIncharge;

  Map<String, dynamic>? sectionTeacher;

  // ── Init ──────────────────────────────────────────────────

  @override
  void initState() {

    super.initState();

    selectedSubject =
        widget.teacherData['subject'];

    assignedClasses =
        List<Map<String, dynamic>>.from(
      widget.teacherData[
              'assignedClasses'] ??
          [],
    );

    classIncharge =
        widget.teacherData[
            'classIncharge'];

    sectionTeacher =
        widget.teacherData[
            'sectionTeacher'];
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Teacher Assignments",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            _buildSectionTitle(
              "Subject Assignment",
            ),

            const SizedBox(height: 16),

            _subjectSelector(),

            const SizedBox(height: 32),

            _buildSectionTitle(
              "Assigned Classes",
            ),

            const SizedBox(height: 16),

            _assignedClassesBuilder(),

            const SizedBox(height: 32),

            _buildSectionTitle(
              "Class Incharge",
            ),

            const SizedBox(height: 16),

            _classInchargeSelector(),

            const SizedBox(height: 32),

            _buildSectionTitle(
              "Section Class Teacher",
            ),

            const SizedBox(height: 16),

            _sectionTeacherSelector(),

            const SizedBox(height: 40),

            SizedBox(

              width: double.infinity,
              height: 56,

              child: ElevatedButton(

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      const Color(
                    0xff5B5FEF,
                  ),

                  shape:
                      RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                ),

                onPressed: _saveAssignments,

                child: const Text(

                  "Save Assignments",

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
  }

  // ── Section title ─────────────────────────────────────────

  Widget _buildSectionTitle(
    String title,
  ) {

    return Text(

      title,

      style: const TextStyle(

        fontSize: 18,

        fontWeight:
            FontWeight.w600,

        color: Color(0xff374151),
      ),
    );
  }

  // ── Placeholders (built in later steps) ───────────────────

  // ── Step 11 — Subject selector ──────────────────────────

  Widget _subjectSelector() {

    return StreamBuilder<QuerySnapshot>(

      stream:
          _subjectService.getSubjects(
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

        return DropdownButtonFormField<
            Map<String, dynamic>>(

          value: selectedSubject,

          decoration: InputDecoration(

            labelText: "Subject",

            filled: true,

            fillColor:
                Colors.white,

            border: OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(16),

              borderSide: BorderSide.none,
            ),
          ),

          items: docs.map((doc) {

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final value = {

              "subjectId": doc.id,

              "name":
                  data['name'] ?? '',

              "code":
                  data['code'] ?? '',
            };

            return DropdownMenuItem(

              value: value,

              child: Text(
                data['name'] ?? '',
              ),
            );

          }).toList(),

          onChanged: (value) {

            setState(() {

              selectedSubject = value;

              assignedClasses.clear();
            });
          },
        );
      },
    );
  }

  // ── Step 12 — Assigned classes builder ───────────────────

  Widget _assignedClassesBuilder() {

    return StreamBuilder<QuerySnapshot>(

      stream:
          _classService.getClasses(
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

        return Column(

          children: docs.map((doc) {

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final sections =
                List<String>.from(
              data['sections'] ?? [],
            );

            final alreadyAssigned =
                assignedClasses.any(
              (e) =>
                  e['classId'] ==
                  doc.id,
            );

            List<String>
                selectedSections = [];

            if (alreadyAssigned) {

              selectedSections =
                  List<String>.from(

                assignedClasses.firstWhere(
                  (e) =>
                      e['classId'] ==
                      doc.id,
                )['sections'],
              );
            }

            return Container(

              margin:
                  const EdgeInsets.only(
                bottom: 16,
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
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Text(

                          data['name'] ??
                              '',

                          style:
                              const TextStyle(

                            fontSize: 16,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      Checkbox(

                        value:
                            alreadyAssigned,

                        onChanged: (v) {

                          setState(() {

                            if (v == true) {

                              assignedClasses
                                  .add({

                                "classId":
                                    doc.id,

                                "className":
                                    data['name'],

                                "sections":
                                    [],
                              });

                            } else {

                              assignedClasses
                                  .removeWhere(
                                (e) =>
                                    e['classId'] ==
                                    doc.id,
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),

                  if (alreadyAssigned) ...[

                    const SizedBox(
                      height: 16,
                    ),

                    Wrap(

                      spacing: 10,
                      runSpacing: 10,

                      children:
                          sections.map(
                        (section) {

                          final isSelected =
                              selectedSections
                                  .contains(
                            section,
                          );

                          return GestureDetector(

                            onTap: () {

                              setState(() {

                                final index =
                                    assignedClasses
                                        .indexWhere(
                                  (e) =>
                                      e['classId'] ==
                                      doc.id,
                                );

                                if (isSelected) {

                                  assignedClasses[index]
                                          ['sections']
                                      .remove(
                                    section,
                                  );

                                } else {

                                  assignedClasses[index]
                                          ['sections']
                                      .add(
                                    section,
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
                                        0xffF5F3FF,
                                      ),

                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),

                              child: Text(

                                section,

                                style:
                                    TextStyle(

                                  fontWeight:
                                      FontWeight.w600,

                                  color: isSelected
                                      ? Colors
                                          .white
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
                  ],
                ],
              ),
            );

          }).toList(),
        );
      },
    );
  }

  // ── Step 14 — Class incharge selector ────────────────────

  Widget _classInchargeSelector() {

    return StreamBuilder<QuerySnapshot>(

      stream:
          _classService.getClasses(
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

        return DropdownButtonFormField<
            Map<String, dynamic>>(

          value: classIncharge,

          decoration: InputDecoration(

            labelText:
                "Class Incharge",

            filled: true,

            fillColor: Colors.white,

            border: OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(
                16,
              ),

              borderSide: BorderSide.none,
            ),
          ),

          items: docs.map((doc) {

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final value = {

              "classId": doc.id,

              "className":
                  data['name'],
            };

            return DropdownMenuItem(

              value: value,

              child: Text(
                data['name'],
              ),
            );

          }).toList(),

          onChanged: (value) {

            setState(() {

              classIncharge = value;
            });
          },
        );
      },
    );
  }

  // ── Step 15 — Section teacher selector ───────────────────

  Widget _sectionTeacherSelector() {

    return StreamBuilder<QuerySnapshot>(

      stream:
          _classService.getClasses(
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

        String? selectedClassId =
            sectionTeacher?['classId'];

        String? selectedSection =
            sectionTeacher?['section'];

        List<String> availableSections =
            [];

        if (selectedClassId != null) {

          final classDoc =
              docs.firstWhere(
            (e) => e.id == selectedClassId,
          );

          final classData =
              classDoc.data()
                  as Map<String, dynamic>;

          availableSections =
              List<String>.from(
            classData['sections'] ?? [],
          );
        }

        return Column(

          children: [

            DropdownButtonFormField<
                String>(

              value: selectedClassId,

              decoration: InputDecoration(

                labelText:
                    "Section Teacher Class",

                filled: true,

                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  borderSide:
                      BorderSide.none,
                ),
              ),

              items: docs.map((doc) {

                final data =
                    doc.data()
                        as Map<String,
                            dynamic>;

                return DropdownMenuItem(

                  value: doc.id,

                  child: Text(
                    data['name'],
                  ),
                );

              }).toList(),

              onChanged: (value) {

                final classDoc =
                    docs.firstWhere(
                  (e) => e.id == value,
                );

                final classData =
                    classDoc.data()
                        as Map<String,
                            dynamic>;

                setState(() {

                  sectionTeacher = {

                    "classId": value,

                    "className":
                        classData['name'],

                    "section": null,
                  };
                });
              },
            ),

            const SizedBox(height: 16),

            if (selectedClassId != null)

              DropdownButtonFormField<
                  String>(

                value: selectedSection,

                decoration: InputDecoration(

                  labelText: "Section",

                  filled: true,

                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    borderSide:
                        BorderSide.none,
                  ),
                ),

                items:
                    availableSections.map(
                  (section) {

                    return DropdownMenuItem(

                      value: section,

                      child: Text(
                        section,
                      ),
                    );

                  },
                ).toList(),

                onChanged: (value) {

                  setState(() {

                    sectionTeacher![
                        'section'] = value;
                  });
                },
              ),
          ],
        );
      },
    );
  }

  // ── Step 13 — Save assignments ────────────────────────────

  Future<void> _saveAssignments()
  async {

    if (selectedSubject == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Select subject",
          ),
        ),
      );

      return;
    }

    await _assignmentService
        .updateAssignments(

      schoolId:
          widget.schoolId,

      teacherId:
          widget.teacherId,

      subject:
          selectedSubject!,

      assignedClasses:
          assignedClasses,

      classIncharge:
          classIncharge,

      sectionTeacher:
          sectionTeacher,
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(
        content: Text(
          "Assignments updated",
        ),
      ),
    );
  }
}
