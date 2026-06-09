import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_app/core/widgets/profile_avatar.dart';

import '../../school_admin/exams/services/exam_service.dart';
import '../../school_admin/exams/services/marks_service.dart';

class MarksEntryScreen
    extends StatefulWidget {

  final String schoolId;

  final String teacherId;

  final Map<String, dynamic>
      teacherData;

  const MarksEntryScreen({

    super.key,

    required this.schoolId,

    required this.teacherId,

    required this.teacherData,
  });

  @override
  State<MarksEntryScreen>
      createState() =>
          _MarksEntryScreenState();
}

class _MarksEntryScreenState
    extends State<MarksEntryScreen> {

  final ExamService _examService =
      ExamService();

  final MarksService _marksService =
      MarksService();

  String? selectedExamId;

  Map<String, dynamic>? selectedExam;

  Map<String, dynamic>? selectedClass;

  String? selectedSection;

  final Map<String,
      TextEditingController>
      marksControllers = {};

  final Map<String,
      TextEditingController>
      remarksControllers = {};

  List<Map<String, dynamic>>
  get assignedClasses {

    return List<Map<String, dynamic>>.from(

      widget.teacherData[
              'assignedClasses'] ??
          [],
    );
  }

  Map<String, dynamic>?
  get teacherSubject {

    return widget.teacherData[
        'subject'];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Marks Entry",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      floatingActionButton:
          selectedExam != null
              ? FloatingActionButton.extended(

                  backgroundColor:
                      const Color(
                    0xff5B5FEF,
                  ),

                  onPressed:
                      _saveMarks,

                  icon: const Icon(
                    Icons.save,
                  ),

                  label: const Text(
                    "Save Marks",
                  ),
                )
              : null,

      body: Column(

        children: [

          _topSelectors(),

          Expanded(
            child: _studentsList(),
          ),
        ],
      ),
    );
  }

  Widget _topSelectors() {

    return Container(

      color: Colors.white,

      padding:
          const EdgeInsets.all(16),

      child: Column(

        children: [

          StreamBuilder<QuerySnapshot>(

            stream:
                _examService.getExams(
              widget.schoolId,
            ),

            builder:
                (context, snapshot) {

              if (!snapshot.hasData) {

                return const SizedBox();
              }

              final docs =
                  snapshot.data!.docs;

              return DropdownButtonFormField<
                  String>(

                value: selectedExamId,

                decoration:
                    _inputDecoration(
                  "Select Exam",
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

                onChanged: (v) {

                  final doc =
                      docs.firstWhere(
                    (e) => e.id == v,
                  );

                  final data =
                      doc.data()
                          as Map<String,
                              dynamic>;

                  setState(() {

                    selectedExamId = v;

                    selectedExam = data;
                  });
                },
              );
            },
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<
              Map<String, dynamic>>(

            value: selectedClass,

            decoration:
                _inputDecoration(
              "Select Class",
            ),

            items:
                assignedClasses.map(
              (assignment) {

                return DropdownMenuItem(

                  value: assignment,

                  child: Text(
                    assignment[
                        'className'],
                  ),
                );

              },
            ).toList(),

            onChanged: (v) {

              setState(() {

                selectedClass = v;

                selectedSection = null;
              });
            },
          ),

          const SizedBox(height: 14),

          if (selectedClass != null)

            DropdownButtonFormField<
                String>(

              value: selectedSection,

              decoration:
                  _inputDecoration(
                "Select Section",
              ),

              items:
                  List<String>.from(
                selectedClass![
                        'sections'] ??
                    [],
              ).map((section) {

                return DropdownMenuItem(

                  value: section,

                  child: Text(section),
                );

              }).toList(),

              onChanged: (v) {

                setState(() {

                  selectedSection = v;
                });
              },
            ),
        ],
      ),
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

  Widget _studentsList() {

    if (selectedExam == null ||
        selectedClass == null ||
        selectedSection == null) {

      return _emptyState();
    }

    return StreamBuilder<QuerySnapshot>(

      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where(
                'classId',
                isEqualTo:
                    selectedClass![
                        'classId'],
              )
              .where(
                'section',
                isEqualTo:
                    selectedSection,
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
              "No students found",
            ),
          );
        }

        final subject =
            teacherSubject;

        final examSubjects =
            List<Map<String, dynamic>>.from(

          selectedExam!['subjects'] ??
              [],
        );

        final subjectConfig =
            examSubjects.firstWhere(

          (e) =>
              e['subjectId'] ==
              subject?['subjectId'],

          orElse: () => {},
        );

        final maxMarks =
            subjectConfig['maxMarks'] ??
                100;

        final passMarks =
            subjectConfig['passMarks'] ??
                35;

        return ListView.builder(

          padding:
              const EdgeInsets.all(16),

          itemCount: docs.length,

          itemBuilder:
              (context, index) {

            final doc =
                docs[index];

            final data =
                doc.data()
                    as Map<String,
                        dynamic>;

            final studentId =
                doc.id;

            marksControllers.putIfAbsent(

              studentId,

              () =>
                  TextEditingController(),
            );

            remarksControllers
                .putIfAbsent(

              studentId,

              () =>
                  TextEditingController(),
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
                  22,
                ),

                border: Border.all(
                  color:
                      Colors.grey.shade100,
                ),
              ),

              child: Column(

                children: [

                  Row(

                    children: [

                      ProfileAvatar(

                        name: (data['name'] ?? '').toString(),

                        imageUrl: data['photoUrl']?.toString(),

                        radius: 24,
                      ),

                      const SizedBox(
                        width: 14,
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

                                fontSize: 15,

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

                              "Max: $maxMarks • Pass: $passMarks",

                              style:
                                  TextStyle(

                                fontSize: 12,

                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(

                    children: [

                      Expanded(
                        flex: 2,

                        child: TextField(

                          controller:
                              marksControllers[
                                  studentId],

                          keyboardType:
                              TextInputType
                                  .number,

                          decoration:
                              _inputDecoration(
                            "Marks",
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(

                        child: Container(

                          height: 56,

                          decoration:
                              BoxDecoration(

                            color:
                                const Color(
                              0xffEEF2FF,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),

                          child: Center(

                            child: Text(

                              _calculateGrade(

                                marksControllers[
                                            studentId]
                                        ?.text ??
                                    '',

                                maxMarks,
                              ),

                              style:
                                  const TextStyle(

                                fontSize: 16,

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
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(

                    controller:
                        remarksControllers[
                            studentId],

                    decoration:
                        _inputDecoration(
                      "Remarks (Optional)",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _calculateGrade(

    String marksText,
    int maxMarks,

  ) {

    if (marksText.isEmpty) {
      return "-";
    }

    final marks =
        double.tryParse(
          marksText,
        ) ??
        0;

    final percentage =
        (marks / maxMarks) * 100;

    if (percentage >= 90) {
      return "A+";
    }

    if (percentage >= 80) {
      return "A";
    }

    if (percentage >= 70) {
      return "B";
    }

    if (percentage >= 60) {
      return "C";
    }

    if (percentage >= 35) {
      return "D";
    }

    return "F";
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

              Icons.edit_note_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "Select Exam & Class",

            style: TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.w700,

              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Choose exam, class and section\nto start marks entry.",

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

  Future<void> _saveMarks()
  async {

    if (selectedExam == null ||
        selectedClass == null ||
        selectedSection == null) {

      return;
    }

    final studentsSnapshot =
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where(
              'classId',
              isEqualTo:
                  selectedClass![
                      'classId'],
            )
            .where(
              'section',
              isEqualTo:
                  selectedSection,
            )
            .get();

    final subject =
        teacherSubject;

    final examSubjects =
        List<Map<String, dynamic>>.from(

      selectedExam!['subjects'] ??
          [],
    );

    final subjectConfig =
        examSubjects.firstWhere(

      (e) =>
          e['subjectId'] ==
          subject?['subjectId'],

      orElse: () => {},
    );

    final maxMarks =
        subjectConfig['maxMarks'] ??
            100;

    final passMarks =
        subjectConfig['passMarks'] ??
            35;

    for (final doc
        in studentsSnapshot.docs) {

      final student =
          doc.data();

      final studentId =
          doc.id;

      final marksText =
          marksControllers[
                      studentId]
                  ?.text
                  .trim() ??
              '';

      if (marksText.isEmpty) {
        continue;
      }

      final marks =
          double.tryParse(
                marksText,
              ) ??
              0;

      final grade =
          _calculateGrade(
        marksText,
        maxMarks,
      );

      final remarks =
          remarksControllers[
                      studentId]
                  ?.text
                  .trim() ??
              '';

      final existing =
          await FirebaseFirestore
              .instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection(
                'exam_results',
              )
              .where(
                'examId',
                isEqualTo:
                    selectedExamId,
              )
              .where(
                'studentId',
                isEqualTo:
                    studentId,
              )
              .where(
                'subjectId',
                isEqualTo:
                    subject?[
                        'subjectId'],
              )
              .get();

      if (existing.docs.isNotEmpty) {

        await existing.docs.first
            .reference
            .update({

          'marksObtained':
              marks,

          'grade': grade,

          'remarks':
              remarks,

          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        });

      } else {

        await _marksService
            .saveStudentMarks(

          schoolId:
              widget.schoolId,

          data: {

            "examId":
                selectedExamId,

            "examName":
                selectedExam!['name'],

            "studentId":
                studentId,

            "studentName":
                student['name'],

            "classId":
                selectedClass![
                    'classId'],

            "className":
                selectedClass![
                    'className'],

            "section":
                selectedSection,

            "subjectId":
                subject?[
                    'subjectId'],

            "subjectName":
                subject?['name'],

            "teacherId":
                widget.teacherId,

            "marksObtained":
                marks,

            "maxMarks":
                maxMarks,

            "passMarks":
                passMarks,

            "grade": grade,

            "remarks":
                remarks,
          },
        );
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(
        content: Text(
          "Marks saved successfully",
        ),
      ),
    );
  }
}
