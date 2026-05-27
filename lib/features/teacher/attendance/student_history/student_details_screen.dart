import 'package:flutter/material.dart';
import 'package:school_app/features/teacher/attendance/student_history/student_live_analytics_service.dart';
import 'package:school_app/core/helpers/student_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/providers/current_school_provider.dart';


class StudentDetailsScreen
  extends ConsumerStatefulWidget {

  final Map<String, dynamic>
      student;

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
          currentSchoolProvider
              .future,
        );

    final schoolId =
        school.id;

    print(
      'SCHOOL ID => $schoolId',
    );

    final studentId =
        StudentHelper
            .admissionNo(
                widget.student);

    print(
      'STUDENT ID => $studentId',
    );

print(
  'CLASS ID => ${widget.student['classId']}',
);

print(
  'SECTION => ${widget.student['section']}',
);



final result =
    await StudentLiveAnalyticsService()
        .getStudentAnalytics(

  schoolId:
      schoolId,

  studentId:
      studentId,

  classId:
      widget.student[
          'classId'],

  section:
      widget.student[
          'section'],
);

    print(
      'RESULT => $result',
    );

    setState(() {
      analytics = result;
      loading = false;
    });

  } catch (e) {
    print(
      'ERROR => $e',
    );
  }
}





  @override
  Widget build(BuildContext context) {

    final student =
        widget.student;

final double percentage =

    (analytics[
            'percentage']
        as num)

    .toDouble();
            

final int present =

    (analytics[
            'present']
        as num)

    .toInt();
final int absent =

    (analytics[
            'absent']
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

      body: SingleChildScrollView(

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

                    StudentHelper.name(student),

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

              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                24,
              ),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),

              child: const Column(

                children: [

                  Icon(
                    Icons.calendar_month,
                    size: 52,
                    color:
                        Colors.deepPurple,
                  ),

                  SizedBox(
                    height: 16,
                  ),

                  Text(

                    "Attendance Calendar Coming Next",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
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