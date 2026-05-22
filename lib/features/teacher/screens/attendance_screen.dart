import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_app/core/widgets/profile_avatar.dart';

import '../../attendance/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String teacherId;
  final Map<String, dynamic> teacherData;

  const AttendanceScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.teacherData,
  });

  @override
  State<AttendanceScreen> createState() =>
      _AttendanceScreenState();
}

class _AttendanceScreenState
    extends State<AttendanceScreen> {

  final AttendanceService _service =
      AttendanceService();

  String? selectedClassId;
  String? selectedSection;

  final Map<String, String>
      attendanceMap = {};

  List<Map<String, dynamic>>
      get assignedClasses {

    return List<Map<String, dynamic>>.from(
      widget.teacherData[
              'assignedClasses'] ??
          [],
    );
  }

 @override
void initState() {

  super.initState();

  final classTeacherOf =
      widget.teacherData[
          'classTeacherOf'];

  if (classTeacherOf != null) {

    selectedClassId =
        classTeacherOf[
            'classId'];

    selectedSection =
        classTeacherOf[
            'sectionId'];
  }
}




  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title:
            const Text("Attendance"),

        backgroundColor:
            Colors.white,

        elevation: 0,
      ),

      floatingActionButton:
          selectedClassId != null &&
                  selectedSection != null
              ? FloatingActionButton
                  .extended(

                  backgroundColor:
                      const Color(
                    0xff5B5FEF,
                  ),

                  onPressed:
                      _saveAttendance,

                  icon: const Icon(
                    Icons.save,
                  ),

                  label:
                      const Text(
                    "Save",
                  ),
                )
              : null,

      body: Column(
        children: [

          _topSelectors(),

          Expanded(
            child:
                _studentsList(),
          ),
        ],
      ),
    );
  }

  Widget _topSelectors() {

    return Container(

      color: Colors.white,

      padding:
          const EdgeInsets.all(
        16,
      ),

      child: Column(
        children: [

          DropdownButtonFormField<
              String>(

            value: selectedClassId,

            decoration:
                _inputDecoration(
              "Select Class",
            ),

            items:
                assignedClasses.map(
              (assignment) {

                return DropdownMenuItem<
                    String>(

                  value: assignment[
                      'className'],

                  child: Text(
                    assignment[
                        'className'],
                  ),
                );
              },
            ).toList(),

            onChanged: (v) {

              setState(() {

                selectedClassId =
                    v;

                selectedSection =
                    null;
              });
            },
          ),

          const SizedBox(
            height: 14,
          ),




if (selectedClassId != null)

  Builder(
    builder: (context) {

      Map<String, dynamic>? classData;

      try {

        classData =
            assignedClasses.firstWhere(
          (e) =>
              e['className'] ==
              selectedClassId,
        );

      } catch (e) {

        classData = null;
      }

      final sections =
          classData != null
              ? List<String>.from(
                  classData['sections'] ??
                      [],
                )
              : <String>[];

      return DropdownButtonFormField<
          String>(

        value: selectedSection,

        decoration:
            _inputDecoration(
          "Select Section",
        ),

        items: sections.map(
          (section) {

            return DropdownMenuItem<
                String>(

              value: section,

              child:
                  Text(section),
            );
          },
        ).toList(),

        onChanged: (v) {

          setState(() {

            selectedSection = v;
          });
        },
      );
    },
  ),
        ],
      ),
    );
  }








  Widget _studentsList() {

    if (selectedClassId == null ||
        selectedSection == null) {

      return _emptyState();
    }

    return StreamBuilder<
        QuerySnapshot>(

      stream: FirebaseFirestore
          .instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')


.where(
  'classId',
  isEqualTo: selectedClassId,
)

.where(
  'section',
  isEqualTo: selectedSection,
)

          .snapshots(),

      builder: (
        context,
        snapshot,
      ) {

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

        return ListView.builder(

          padding:
              const EdgeInsets.all(
            16,
          ),

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

            attendanceMap
                .putIfAbsent(
              studentId,
              () => "Present",
            );

            final currentStatus =
                attendanceMap[
                    studentId];

            return Container(

              margin:
                  const EdgeInsets.only(
                bottom: 14,
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
                  22,
                ),

                border: Border.all(
                  color: Colors
                      .grey
                      .shade100,
                ),
              ),

              child: Row(
                children: [

                  ProfileAvatar(

                    name: (data[
                                'name'] ??
                            '')
                        .toString(),

                    imageUrl: data[
                            'photoUrl']
                        ?.toString(),

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

                          data['admissionNo'] ??
                              '',

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

                  _attendanceButton(

                    title: "P",

                    color: const Color(
                      0xffDCFCE7,
                    ),

                    textColor:
                        const Color(
                      0xff166534,
                    ),

                    isSelected:
                        currentStatus ==
                            "Present",

                    onTap: () {

                      setState(() {

                        attendanceMap[
                                studentId] =
                            "Present";
                      });
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _attendanceButton(

                    title: "A",

                    color: const Color(
                      0xffFEE2E2,
                    ),

                    textColor:
                        const Color(
                      0xff991B1B,
                    ),

                    isSelected:
                        currentStatus ==
                            "Absent",

                    onTap: () {

                      setState(() {

                        attendanceMap[
                                studentId] =
                            "Absent";
                      });
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _attendanceButton(

                    title: "L",

                    color: const Color(
                      0xffFEF3C7,
                    ),

                    textColor:
                        const Color(
                      0xff92400E,
                    ),

                    isSelected:
                        currentStatus ==
                            "Leave",

                    onTap: () {

                      setState(() {

                        attendanceMap[
                                studentId] =
                            "Leave";
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _attendanceButton({

    required String title,

    required Color color,

    required Color textColor,

    required bool isSelected,

    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: AnimatedContainer(

        duration:
            const Duration(
          milliseconds: 180,
        ),

        height: 42,
        width: 42,

        decoration: BoxDecoration(

          color: isSelected
              ? color
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border: Border.all(

            color: isSelected
                ? color
                : Colors.grey
                    .shade300,

            width: 1.5,
          ),
        ),

        child: Center(

          child: Text(

            title,

            style: TextStyle(

              fontWeight:
                  FontWeight.w700,

              color: isSelected
                  ? textColor
                  : Colors.grey,
            ),
          ),
        ),
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

            decoration:
                const BoxDecoration(

              color:
                  Color(0xffEEF2FF),

              shape:
                  BoxShape.circle,
            ),

            child: const Icon(

              Icons
                  .check_circle_outline,

              size: 42,

              color:
                  Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(

            "Select Class & Section",

            style: TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.w700,

              color:
                  Color(0xff374151),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(

            "Choose class and section\nto mark attendance.",

            textAlign:
                TextAlign.center,

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

  InputDecoration
      _inputDecoration(
    String label,
  ) {

    return InputDecoration(

      labelText: label,

      filled: true,

      fillColor:
          const Color(0xffF8FAFC),

      border:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        borderSide:
            BorderSide.none,
      ),
    );
  }

  void _saveAttendance() {}
}