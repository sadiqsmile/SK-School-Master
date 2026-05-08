import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../school_admin/timetable/services/timetable_service.dart';

class TeacherTimetableScreen
    extends StatefulWidget {

  final String schoolId;

  final String teacherId;

  const TeacherTimetableScreen({

    super.key,

    required this.schoolId,

    required this.teacherId,
  });

  @override
  State<TeacherTimetableScreen>
      createState() =>
          _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState
    extends State<TeacherTimetableScreen> {

  // ── Services ──────────────────────────────────────────────

  final TimetableService _service =
      TimetableService();

  // ── State ─────────────────────────────────────────────────

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
          "My Timetable",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      body:
          StreamBuilder<QuerySnapshot>(

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

              return data['teacherId'] ==
                  widget.teacherId;
            },
          ).toList();

          if (docs.isEmpty) {

            return _emptyState();
          }

          return ListView.builder(

            padding:
                const EdgeInsets.all(16),

            itemCount:
                weekDays.length,

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
                          const EdgeInsets
                              .all(18),

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

                            bottom:
                                BorderSide(
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

                                    color:
                                        Color(
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

                                      color:
                                          Color(
                                        0xff111827,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(

                                    "${data['className']} • Section ${data['section']}",

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
      ),
    );
  }

  // ── Step 6 — Empty state ──────────────────────────────────

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

              Icons.schedule_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "No Timetable Assigned",

            style: TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.w700,

              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Your timetable will appear here\nonce assigned by school admin.",

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
}
