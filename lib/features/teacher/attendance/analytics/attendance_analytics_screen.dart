import 'package:flutter/material.dart';
import 'attendance_analytics_service.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceAnalyticsScreen
    extends StatefulWidget {

  final String schoolId;

  final String classId;

  final String section;

  const AttendanceAnalyticsScreen({

    super.key,

    required this.schoolId,

    required this.classId,

    required this.section,
  });

  @override
  State<AttendanceAnalyticsScreen>
      createState() =>
          _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState
    extends State<AttendanceAnalyticsScreen> {

  final AttendanceAnalyticsService
      _service =
          AttendanceAnalyticsService();

DateTime focusedDay =
    DateTime.now();

DateTime? selectedDay;


  Map<String, dynamic>?
      analytics;

  bool loading = true;

  @override
  void initState() {

    super.initState();

    _loadAnalytics();
  }

  Future<void>
      _loadAnalytics() async {

    final now = DateTime.now();

    final result =
        await _service
            .monthlyAnalytics(

      schoolId:
          widget.schoolId,

      classId:
          widget.classId,

      section:
          widget.section,

      year: now.year,

      month: now.month,
    );

    setState(() {

      analytics = result;

      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Attendance Analytics",
        ),
      ),

      body:

          loading

              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )

              : ListView(

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  children: [

                    _topAnalyticsCard(),

                    const SizedBox(
                      height: 20,
                    ),

                    _calendarPlaceholder(),

                    const SizedBox(
                      height: 20,
                    ),

                    _dailySummaryPlaceholder(),
                  ],
                ),
    );
  }

  Widget _topAnalyticsCard() {

    return Container(

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(

        color:
            const Color(0xff5B5FEF),

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(

            "Class ${widget.classId} - ${widget.section}",

            style:
                const TextStyle(

              color:
                  Colors.white,

              fontSize: 22,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(

            "Monthly Attendance",

            style: TextStyle(

              color:
                  Colors.white70,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(

            "${(analytics?['percentage'] ?? 0).toStringAsFixed(0)}%",

            style:
                const TextStyle(

              color:
                  Colors.white,

              fontSize: 38,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Row(

            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              _statTile(

                "Working Days",

                "${analytics?['workingDays'] ?? 0}",
              ),

              _statTile(

                "Class Strength",

               "${analytics?['classStrength'] ?? 0}",
              ),

              _statTile(

                "Holiday",

               "${analytics?['holidayDays'] ?? 0}",
              ),
            ],
          ),
        ],
      ),
    );
  }


//-----------------------------------------------

  Widget _statTile(
    String title,
    String value,
  ) {

    return Column(

      children: [

        Text(

          value,

          style:
              const TextStyle(

            color:
                Colors.white,

            fontSize: 22,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(

          title,

          style:
              const TextStyle(

            color:
                Colors.white70,
          ),
        ),
      ],
    );
  }

//------------------------------------------------------------------------
Widget _calendarPlaceholder() {

  final calendar =
      analytics?['calendar']
          as Map<String, dynamic>?;

  return Container(

    padding:
        const EdgeInsets.all(
      16,
    ),

    decoration: BoxDecoration(

      color: Colors.white,

      borderRadius:
          BorderRadius.circular(
        24,
      ),
    ),

    child: TableCalendar(

      firstDay:
          DateTime.utc(
        2025,
        1,
        1,
      ),

      lastDay:
          DateTime.utc(
        2035,
        12,
        31,
      ),

      focusedDay:
          focusedDay,

      calendarFormat:
          CalendarFormat.month,

      availableCalendarFormats:
          const {

        CalendarFormat.month:
            'Month',
      },

      calendarStyle:
          const CalendarStyle(

        outsideDaysVisible:
            false,
      ),



      onDaySelected:
          (
        selected,
        focused,
      ) {

        _openDayDetails(
          selected,
        );
      },

      onPageChanged:
          (
        focusedDayValue,
      ) async {

        focusedDay =
            focusedDayValue;

        final result =
            await _service
                .monthlyAnalytics(

          schoolId:
              widget.schoolId,

          classId:
              widget.classId,

          section:
              widget.section,

          year:
              focusedDay.year,

          month:
              focusedDay.month,
        );

        setState(() {

          analytics =
              result;
        });
      },

      calendarBuilders:
          CalendarBuilders(
        todayBuilder:
            (
          context,
          day,
          focused,
        ) {
          final key =
              "${day.year}-"
              "${day.month.toString().padLeft(2, '0')}-"
              "${day.day.toString().padLeft(2, '0')}";

          final dayData =
              calendar?[key];

          if (dayData == null) {
            return Center(
              child: Text(
                "${day.day}",
              ),
            );
          }

          final holiday =
              dayData['holiday']
                  ?? false;

          final percentage =
              dayData['percentage']
                  ?? 0;

          Color color;

          if (holiday) {
            color = Colors.blue;
          } else if (percentage >= 90) {
            color = Colors.green;
          } else if (percentage >= 75) {
            color = Colors.orange;
          } else {
            color = Colors.red;
          }

          return Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${day.day}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        defaultBuilder:
            (
          context,
          day,
          focused,
        ) {
          final key =
              "${day.year}-"
              "${day.month.toString().padLeft(2, '0')}-"
              "${day.day.toString().padLeft(2, '0')}";

          final dayData =
              calendar?[key];

          if (dayData == null) {
            return Center(
              child: Text(
                "${day.day}",
              ),
            );
          }

          final holiday =
              dayData['holiday']
                  ?? false;

          final percentage =
              dayData['percentage']
                  ?? 0;

          Color color;

          if (holiday) {
            color = Colors.blue;
          } else if (percentage >= 90) {
            color = Colors.green;
          } else if (percentage >= 75) {
            color = Colors.orange;
          } else {
            color = Colors.red;
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

                "${day.day}",

                style:
                    const TextStyle(

                  color:
                      Colors.white,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
//------------------------------------------------------------------------


void _openDayDetails(
    DateTime day) {

  final key =
      "${day.year}-"
      "${day.month.toString().padLeft(2, '0')}-"
      "${day.day.toString().padLeft(2, '0')}";

  final calendar =
      analytics?['calendar']
          as Map<String, dynamic>?;

  final dayData =
      calendar?[key];

  if (dayData == null) {
    return;
  }

  final holiday =
      dayData['holiday']
          ?? false;

  final percentage =
      dayData['percentage']
          ?? 0;

  final present =
      dayData['present']
          ?? 0;

  final absent =
      dayData['absent']
          ?? 0;

  showModalBottomSheet(

    context: context,

    builder: (_) {

      return Container(

        padding:
            const EdgeInsets.all(
          24,
        ),

        child: Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            Text(

              key,

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

            Text(

              holiday

                  ? "Holiday"

                  : "${percentage.toStringAsFixed(0)}% Attendance",

              style:
                  const TextStyle(

                fontSize: 22,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            if (!holiday)
              Row(

                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceEvenly,

                children: [

                  _popupStat(
                    "Present",
                    present.toString(),
                    Colors.green,
                  ),

                  _popupStat(
                    "Absent",
                    absent.toString(),
                    Colors.red,
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

Widget _popupStat(

  String title,

  String value,

  Color color,
) {

  return Column(

    children: [

      Text(

        value,

        style: TextStyle(

          color: color,

          fontSize: 26,

          fontWeight:
              FontWeight.bold,
        ),
      ),

      const SizedBox(
        height: 4,
      ),

      Text(title),
    ],
  );
}

Widget _dailySummaryPlaceholder() {

  final totalPresent =
      analytics?[
              'totalPresent']
          ?? 0;

  final totalAbsent =
      analytics?[
              'totalAbsent']
          ?? 0;

  return Container(

    padding:
        const EdgeInsets.all(
      20,
    ),

    decoration: BoxDecoration(

      color: Colors.white,

      borderRadius:
          BorderRadius.circular(
        24,
      ),
    ),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Text(

          "Monthly Summary",

          style: TextStyle(

            fontSize: 20,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Row(

          children: [

            Expanded(

              child: _summaryCard(

                "Total Present",

                totalPresent
                    .toString(),

                Colors.green,
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(

              child: _summaryCard(

                "Total Absent",

                totalAbsent
                    .toString(),

                Colors.red,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}




Widget _summaryCard(

  String title,

  String value,

  Color color,
) {

  return Container(

    padding:
        const EdgeInsets.all(
      20,
    ),

    decoration: BoxDecoration(

      color:
          color.withOpacity(
              0.08),

      borderRadius:
          BorderRadius.circular(
        20,
      ),
    ),

    child: Column(

      children: [

        Text(

          value,

          style: TextStyle(

            color: color,

            fontSize: 28,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(

          title,

          textAlign:
              TextAlign.center,
        ),
      ],
    ),
  );
}

    }







