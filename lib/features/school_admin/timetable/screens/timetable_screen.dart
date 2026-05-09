import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../academic_setup/services/class_service.dart';
import '../../academic_setup/services/group_timing_service.dart';

import '../services/timetable_service.dart';

class TimetableScreen
    extends StatefulWidget {

  final String schoolId;

  const TimetableScreen({

    super.key,

    required this.schoolId,
  });

  @override
  State<TimetableScreen>
      createState() =>
          _TimetableScreenState();
}

class _TimetableScreenState
    extends State<TimetableScreen> {

  // ── Services ──────────────────────────────────────────────

  final TimetableService _service =
      TimetableService();

  final ClassService _classService =
      ClassService();

  final GroupTimingService
      _timingService =
          GroupTimingService();

  // ── State ─────────────────────────────────────────────────

  String? selectedGroup;

  String? selectedClassId;

  String? selectedClassName;

  String? selectedSection;

  final List<String> weekDays = [

    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Timetable",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        backgroundColor:
            const Color(0xff5B5FEF),

        onPressed: () {

          if (selectedClassId == null ||
              selectedSection == null) {

            ScaffoldMessenger.of(context)
                .showSnackBar(

              const SnackBar(
                content: Text(
                  "Select class and section",
                ),
              ),
            );

            return;
          }

          _showAddPeriodSheet();
        },

        icon: const Icon(Icons.add),

        label: const Text(
          "Add Period",
        ),
      ),

      body: Column(

        children: [

          _topSelectors(),

          Expanded(
            child: _timetableView(),
          ),
        ],
      ),
    );
  }

  // ── Step 7 — Top selectors ────────────────────────────────

  Widget _topSelectors() {

    return StreamBuilder<QuerySnapshot>(

      stream:
          _classService.getClasses(
        widget.schoolId,
      ),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {

          return const SizedBox();
        }

        final docs =
            snapshot.data!.docs;

        final filteredClasses =
            selectedGroup == null
                ? []
                : docs.where((e) {

                    final data =
                        e.data()
                            as Map<String,
                                dynamic>;

                    return data['group'] ==
                        selectedGroup;

                  }).toList();

        List<String> sections = [];

        if (selectedClassId != null) {

          final classDoc =
              filteredClasses.firstWhere(
            (e) => e.id == selectedClassId,
          );

          final classData =
              classDoc.data()
                  as Map<String, dynamic>;

          sections =
              List<String>.from(
            classData['sections'] ?? [],
          );
        }

        return Container(

          color: Colors.white,

          padding:
              const EdgeInsets.all(16),

          child: Column(

            children: [

              DropdownButtonFormField<String>(

                value: selectedGroup,

                decoration:
                    _dropdownDecoration(
                  "Academic Group",
                ),

                items: [

                  "Nursery",
                  "Primary",
                  "Middle School",
                  "High School",
                  "College",

                ].map((group) {

                  return DropdownMenuItem(

                    value: group,

                    child: Text(group),
                  );

                }).toList(),

                onChanged: (v) {

                  setState(() {

                    selectedGroup = v;

                    selectedClassId = null;

                    selectedSection = null;
                  });
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(

                value: selectedClassId,

                decoration:
                    _dropdownDecoration(
                  "Class",
                ),

                items:
                    filteredClasses.map(
                  (doc) {

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

                  },
                ).toList(),

                onChanged: (v) {

                  final classDoc =
                      filteredClasses
                          .firstWhere(
                    (e) => e.id == v,
                  );

                  final data =
                      classDoc.data()
                          as Map<String,
                              dynamic>;

                  setState(() {

                    selectedClassId = v;

                    selectedClassName =
                        data['name'];

                    selectedSection =
                        null;
                  });
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(

                value: selectedSection,

                decoration:
                    _dropdownDecoration(
                  "Section",
                ),

                items: sections.map(
                  (section) {

                    return DropdownMenuItem(

                      value: section,

                      child: Text(
                        section,
                      ),
                    );

                  },
                ).toList(),

                onChanged: (v) {

                  setState(() {

                    selectedSection = v;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 8 — Dropdown decoration ─────────────────────────

  InputDecoration _dropdownDecoration(
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
    );
  }

  // ── Step 10 — Timetable view ──────────────────────────────

  Widget _timetableView() {

    if (selectedClassId == null ||
        selectedSection == null) {

      return _emptySelectionState();
    }

    return StreamBuilder<QuerySnapshot>(

      stream:
          _service.getTimetable(
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
            snapshot.data!.docs.where(
          (doc) {

            final data =
                doc.data()
                    as Map<String,
                        dynamic>;

            return data['classId'] ==
                    selectedClassId &&
                data['section'] ==
                    selectedSection;
          },
        ).toList();

        if (docs.isEmpty) {

          return _emptyTimetableState();
        }

        return ListView.builder(

          padding:
              const EdgeInsets.all(16),

          itemCount: weekDays.length,

          itemBuilder:
              (context, index) {

            final day =
                weekDays[index];

            final dayDocs =
                docs.where((doc) {

              final data =
                  doc.data()
                      as Map<String,
                          dynamic>;

              return data['day'] ==
                  day;

            }).toList();

            if (dayDocs.isEmpty) {

              return const SizedBox();
            }

            dayDocs.sort((a, b) {

              final aData =
                  a.data()
                      as Map<String,
                          dynamic>;

              final bData =
                  b.data()
                      as Map<String,
                          dynamic>;

              return aData['period']
                  .compareTo(
                bData['period'],
              );
            });

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

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Container(

                    padding:
                        const EdgeInsets.all(
                      18,
                    ),

                    decoration:
                        const BoxDecoration(

                      color:
                          Color(0xffEEF2FF),

                      borderRadius:
                          BorderRadius.vertical(
                        top:
                            Radius.circular(
                          24,
                        ),
                      ),
                    ),

                    child: Row(

                      children: [

                        const Icon(

                          Icons.calendar_today,

                          size: 18,

                          color: Color(
                            0xff5B5FEF,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Text(

                          day,

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
                      ],
                    ),
                  ),

                  ...dayDocs.map((doc) {

                    final data =
                        doc.data()
                            as Map<String,
                                dynamic>;

                    return Container(

                      padding:
                          const EdgeInsets
                              .all(18),

                      decoration:
                          BoxDecoration(

                        border: Border(

                          bottom: BorderSide(
                            color: Colors
                                .grey
                                .shade100,
                          ),
                        ),
                      ),

                      child: Row(

                        children: [

                          Container(

                            height: 50,
                            width: 50,

                            decoration:
                                BoxDecoration(

                              color:
                                  const Color(
                                0xffF5F3FF,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),

                            child: Center(

                              child: Text(

                                data['period'],

                                style:
                                    const TextStyle(

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

                                  data['subjectName'] ??
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
                                  height: 5,
                                ),

                                Text(

                                  data['teacherName'] ??
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

                          PopupMenuButton(

                            itemBuilder:
                                (context) => [

                              PopupMenuItem(

                                onTap: () {

                                  Future.delayed(
                                    Duration.zero,

                                    () {

                                      _service
                                          .deletePeriod(

                                        schoolId:
                                            widget
                                                .schoolId,

                                        docId:
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

                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Step 11 — Empty states ────────────────────────────────

  Widget _emptySelectionState() {

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

              Icons.schedule_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "Select Class & Section",

            style: TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.w700,

              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Choose academic group, class\nand section to view timetable.",

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

  Widget _emptyTimetableState() {

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

              Icons.calendar_month_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "No Timetable Added",

            style: TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.w700,

              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Add periods to build timetable\nfor this section.",

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

  // ── Step 9 — Add period sheet ─────────────────────────────

  void _showAddPeriodSheet() {

    String selectedDay = "Monday";

    String? selectedPeriod;

    Map<String, dynamic>? selectedTeacher;

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

                      "Add Timetable Period",

                      style: TextStyle(

                        fontSize: 22,

                        fontWeight:
                            FontWeight.w700,

                        color:
                            Color(0xff111827),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(

                      "$selectedClassName • Section $selectedSection",

                      style: TextStyle(

                        fontSize: 13,

                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 28),

                    DropdownButtonFormField<String>(

                      value: selectedDay,

                      decoration:
                          _dropdownDecoration(
                        "Day",
                      ),

                      items:
                          weekDays.map((day) {

                  return DropdownMenuItem<String>(
                          setSheetState(() {
                            selectedDay = v;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(

                      value: selectedPeriod,

                      decoration:
                          _dropdownDecoration(
                        "Period",
                      ),

                      items: [

                        "P1",
                        "P2",
                        "P3",
                        "P4",
                        "P5",
                        "P6",
                        "P7",
                        "P8",

                      ].map((period) {

                  return DropdownMenuItem<String>(
                              .instance
                              .collection(
                                'schools',
                              )
                              .doc(
                                widget.schoolId,
                              )
                              .collection(
                                'teachers',
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

                        final teacherDocs =
                            snapshot.data!.docs
                                .where((doc) {

                          final data =
                              doc.data()
                                  as Map<String,
                                      dynamic>;

                          final assignments =
                              List<Map<String,
                                  dynamic>>.from(

                            data[
                                    'assignedClasses'] ??
                                [],
                          );

                          return assignments.any(
                            (assignment) {

                              final classMatch =
                                  assignment[
                                          'classId'] ==
                                      selectedClassId;

                              final sectionMatch =
                                  List<String>.from(
                                assignment[
                                        'sections'] ??
                                    [],
                              ).contains(
                                selectedSection,
                              );

                              return classMatch &&
                                  sectionMatch;
                            },
                          );

                        }).toList();

                        return DropdownButtonFormField<
                            Map<String, dynamic>>(

                          value:
                              selectedTeacher,

                          decoration:
                              _dropdownDecoration(
                            "Teacher",
                          ),

                          items:
                              teacherDocs.map(
                            (doc) {

                              final data =
                                  doc.data()
                                      as Map<String,
                                          dynamic>;

                              final subject =
                                  data['subject'];

                              final value = {

                                "teacherId":
                                    doc.id,

                                "teacherName":
                                    data['name'],

                                "subject":
                                    subject,
                              };

                        return DropdownMenuItem<
                            Map<String, dynamic>>(

                          value: value,

                                child: Text(

                                  "${data['name']} • ${subject?['name'] ?? ''}",
                                ),
                              );

                            },
                          ).toList(),

                          onChanged: (v) {

                            setSheetState(() {
                              selectedTeacher =
                                  v;
                            });
                          },
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

                          if (selectedPeriod ==
                                  null ||
                              selectedTeacher ==
                                  null) {

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(

                              const SnackBar(
                                content: Text(
                                  "Fill all fields",
                                ),
                              ),
                            );

                            return;
                          }

                          await _service
                              .savePeriod(

                            schoolId:
                                widget.schoolId,

                            data: {

                              "group":
                                  selectedGroup,

                              "classId":
                                  selectedClassId,

                              "className":
                                  selectedClassName,

                              "section":
                                  selectedSection,

                              "day":
                                  selectedDay,

                              "period":
                                  selectedPeriod,

                              "teacherId":
                                  selectedTeacher![
                                      'teacherId'],

                              "teacherName":
                                  selectedTeacher![
                                      'teacherName'],

                              "subjectId":
                                  selectedTeacher![
                                          'subject']
                                      ['subjectId'],

                              "subjectName":
                                  selectedTeacher![
                                          'subject']
                                      ['name'],
                            },
                          );

                          if (!mounted) return;

                          Navigator.pop(context);
                        },

                        child: const Text(

                          "Save Period",

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
}
