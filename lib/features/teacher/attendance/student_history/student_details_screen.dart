import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/core/helpers/student_helper.dart';
import 'package:school_app/features/teacher/attendance/student_history/student_live_analytics_service.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentDetailsScreen
    extends ConsumerStatefulWidget {

  final Map<String, dynamic> student;

  const StudentDetailsScreen({
    super.key,
    required this.student,
  });

  @override
  ConsumerState<StudentDetailsScreen>
      createState() =>
          _StudentDetailsScreenState();
}

class _StudentDetailsScreenState
    extends ConsumerState<StudentDetailsScreen> {

  Map<DateTime, String>
      attendanceMap = {};

  DateTime focusedDay =
      DateTime.now();

  DateTime selectedDay =
      DateTime.now();

  Map<String, dynamic>
      analytics = {

    'percentage': 0,

    'present': 0,

    'absent': 0,
  };

  bool loading = true;

  @override
  void initState() {

    super.initState();

    loadAnalytics();
  }

  Future<void>
      loadAnalytics() async {

    try {

      final school =
          await ref.read(
        currentSchoolProvider.future,
      );

      final schoolId =
          school.id;

      final studentId =
          StudentHelper.admissionNo(
        widget.student,
      );

      final result =
          await StudentLiveAnalyticsService()
              .getStudentAnalytics(

        schoolId: schoolId,

        studentId: studentId,

        classId:
            widget.student['classId'],

        section:
            widget.student['section'],
      );

      analytics = result;

      await loadAttendanceCalendar(
        schoolId,
      );

      setState(() {

        loading = false;
      });

    } catch (e) {

      print(
        'ERROR => $e',
      );
    }
  }

  Future<void>
      loadAttendanceCalendar(
    String schoolId,
  ) async {

    final studentId =
        widget.student['admissionNo'];

    final classId =
        widget.student['classId'];

    final section =
        widget.student['section'];

    final attendanceSnapshot =

        await FirebaseFirestore
            .instance

            .collection('schools')

            .doc(schoolId)

            .collection('attendance')

            .get();

    Map<DateTime, String>
        temp = {};

    for (final dateDoc
        in attendanceSnapshot.docs) {

      final classDoc =
          await dateDoc.reference

              .collection('classes')

              .doc(
                '${classId}_$section',
              )

              .get();

      if (!classDoc.exists) {
        continue;
      }

      final data =
          classDoc.data();

      if (data == null) {
        continue;
      }

      final students =
          (data['students']
                  ?? {})
              as Map;

      final value =
          students[studentId];

      if (value == null) {
        continue;
      }

      final date =
          DateTime.parse(
        dateDoc.id,
      );

      temp[
          DateTime(
        date.year,
        date.month,
        date.day,
      )] =
          value.toString();
    }

    setState(() {

      attendanceMap = temp;
    });
  }

  Widget legend(
    Color color,
    String text,
  ) {

    return Row(

      children: [

        Container(

          width: 14,

          height: 14,

          decoration: BoxDecoration(

            color: color,

            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 6),

        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final student =
        widget.student;

    final double percentage =
        (analytics['percentage']
                as num)
            .toDouble();

    final int present =
        (analytics['present']
                as num)
            .toInt();

    final int absent =
        (analytics['absent']
                as num)
            .toInt();

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Student Details",
        ),
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : SingleChildScrollView(

              padding:
                  const EdgeInsets.all(
                16,
              ),

              child: Column(

                children: [

                  Container(

                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    decoration:
                        BoxDecoration(

                      color:
                          Colors.deepPurple,

                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),

                    child: Column(

                      children: [

                        CircleAvatar(

                          radius: 42,

                          backgroundColor:
                              Colors.white,

                          backgroundImage:

                              StudentHelper
                                      .hasPhoto(
                                          student)

                                  ? NetworkImage(

                                      StudentHelper
                                          .photo(
                                              student),
                                    )

                                  : null,

                          child:

                              StudentHelper
                                      .hasPhoto(
                                          student)

                                  ? null

                                  : Text(

                                      StudentHelper
                                          .initial(
                                              student),

                                      style:
                                          const TextStyle(

                                        fontSize: 28,

                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Text(

                          StudentHelper.name(
                            student,
                          ),

                          style:
                              const TextStyle(

                            color:
                                Colors.white,

                            fontSize: 24,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(

                          StudentHelper
                              .admissionNo(
                                  student),

                          style:
                              const TextStyle(

                            color:
                                Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(

                    children: [

                      Expanded(

                        child: _statCard(

                          "Attendance",

                          "${percentage.toStringAsFixed(0)}%",

                          Colors.green,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(

                        child: _statCard(

                          "Present",

                          present.toString(),

                          Colors.blue,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(

                        child: _statCard(

                          "Absent",

                          absent.toString(),

                          Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Container(

                    padding:
                        const EdgeInsets.all(
                      12,
                    ),

                    decoration:
                        BoxDecoration(

                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: Column(

                      children: [

                        TableCalendar(

headerStyle: const HeaderStyle(
  formatButtonVisible: false,
  titleCentered: true,
),

calendarStyle: const CalendarStyle(
  selectedDecoration:
      BoxDecoration(
    color: Colors.transparent,
    shape: BoxShape.circle,
  ),
  todayDecoration:
      BoxDecoration(
    color: Colors.transparent,
    shape: BoxShape.circle,
  ),
  todayTextStyle:
      TextStyle(
    color: Colors.black,
  ),
),









                          focusedDay:
                              focusedDay,

                          firstDay:
                              DateTime(2025),

                          lastDay:
                              DateTime(2030),

                          selectedDayPredicate:
                              (day) {

                            return isSameDay(
                              selectedDay,
                              day,
                            );
                          },

                          onDaySelected:
                              (
                            selected,
                            focused,
                          ) {

                            setState(() {

                              selectedDay =
                                  selected;

                              focusedDay =
                                  focused;
                            });
                          },

                         calendarBuilders:
    CalendarBuilders(

selectedBuilder:
    (context, day, focused) {

  final normalized =
      DateTime(
    day.year,
    day.month,
    day.day,
  );

  final value =
      attendanceMap[
          normalized];

  Color? color;

  if (value == 'P') {

    color = Colors.green;

  } else if (value == 'A') {

    color = Colors.red;
  }

  color ??= Colors.grey;

  return Container(

    margin:
        const EdgeInsets.all(6),

    decoration:
        BoxDecoration(

      color: color,

      shape: BoxShape.circle,
    ),

    child: Center(

      child: Text(

        '${day.day}',

        style:
            const TextStyle(

          color: Colors.white,
        ),
      ),
    ),
  );
},





  defaultBuilder:
      (context, day, focused) {

    final normalized =
        DateTime(
      day.year,
      day.month,
      day.day,
    );

    final value =
        attendanceMap[
            normalized];

    Color? color;

    if (value == 'P') {

      color =
          Colors.green;

    } else if (
        value == 'A') {

      color =
          Colors.red;
    }

    if (color == null) {
      return null;
    }

    return Container(

      margin:
          const EdgeInsets.all(
        6,
      ),

      decoration:
          BoxDecoration(

        color: color,

        shape:
            BoxShape.circle,
      ),

      child: Center(

        child: Text(

          '${day.day}',

          style:
              const TextStyle(

            color:
                Colors.white,
          ),
        ),
      ),
    );
  },

  todayBuilder:
      (context, day, focused) {

    final normalized =
        DateTime(
      day.year,
      day.month,
      day.day,
    );

    final value =
        attendanceMap[
            normalized];

    Color? color;

    if (value == 'P') {

      color =
          Colors.green;

    } else if (
        value == 'A') {

      color =
          Colors.red;
    }

    if (color == null) {

      return Center(

        child: Text(
          '${day.day}',
        ),
      );
    }

    return Container(

      margin:
          const EdgeInsets.all(
        6,
      ),

      decoration:
          BoxDecoration(

        color: color,

        shape:
            BoxShape.circle,
      ),

      child: Center(

        child: Text(

          '${day.day}',

          style:
              const TextStyle(

            color:
                Colors.white,
          ),
        ),
      ),
    );
  },
),
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(

                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            legend(
                              Colors.green,
                              'Present',
                            ),

                            const SizedBox(
                              width: 16,
                            ),

                            legend(
                              Colors.red,
                              'Absent',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(

    String title,

    String value,

    Color color,
  ) {

    return Container(

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(

        color:
            color.withOpacity(
                0.1),

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Column(

        children: [

          Text(

            value,

            style: TextStyle(

              color: color,

              fontSize: 24,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(title),
        ],
      ),
    );
  }
}