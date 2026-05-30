import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class QuickAttendanceScreen
    extends StatefulWidget {

  final String schoolId;

  final String teacherId;

  final Map<String, dynamic>
      teacherData;

  const QuickAttendanceScreen({

    super.key,

    required this.schoolId,

    required this.teacherId,

    required this.teacherData,
  });

  @override
  State<QuickAttendanceScreen>
      createState() =>
          _QuickAttendanceScreenState();
}

class _QuickAttendanceScreenState
    extends State<QuickAttendanceScreen> {

  final AttendanceService _service =
      AttendanceService();

  String? classId;

  String? section;

  bool isHoliday = false;

  bool loading = true;
  bool isSunday = false;

  bool alreadySaved = false;

double todayPercentage = 0;

  final Map<String, String>
      attendanceMap = {};
List<QueryDocumentSnapshot>
    studentDocs = [];



  @override
  void initState() {

    super.initState();

isSunday =
    DateTime.now().weekday ==
    DateTime.sunday;


    final classTeacherOf =
        widget.teacherData[
            'classTeacherOf'];






    if (classTeacherOf != null) {

      classId =
          classTeacherOf[
              'classId'];

      section =
          classTeacherOf[
              'sectionId'];
    }

    _loadTodayAttendance();
  }



Future<void>
    _loadTodayAttendance() async {

if (DateTime.now().weekday ==
    DateTime.sunday) {

  setState(() {

    isHoliday = true;
    loading = false;
  });

  return;
}



  final dateKey =
      "${DateTime.now().year}-"
      "${DateTime.now().month.toString().padLeft(2, '0')}-"
      "${DateTime.now().day.toString().padLeft(2, '0')}";

  final docId =
      "${classId}_$section";

  final doc =
      await FirebaseFirestore
          .instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(dateKey)
          .collection('classes')
          .doc(docId)
          .get();

  if (doc.exists) {

    final data = doc.data()!;

    alreadySaved = true;

    isHoliday =
        data['isHoliday'] ??
            false;

    final students =
        Map<String, String>.from(
      data['students'] ?? {},
    );

    attendanceMap.clear();

    attendanceMap.addAll(
      students,
    );
_updatePercentage();



    final present =
        data['presentCount'] ?? 0;

    final total =
        data['totalStudents'] ?? 0;

    if (total > 0) {

      todayPercentage =
          (present / total) * 100;
    }
  }

  setState(() {

    loading = false;
  });
}

  @override
  Widget build(BuildContext context) {

    if (loading) {

      return const Scaffold(

        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

if (isSunday) {

  return Scaffold(

    appBar: AppBar(
      title: const Text(
        "Quick Attendance",
      ),
    ),

    body: const Center(

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(
            Icons.weekend,
            size: 80,
            color: Colors.orange,
          ),

          SizedBox(height: 16),

          Text(
            "Attendance Disabled",
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Today is Sunday",
          ),
        ],
      ),
    ),
  );
}



    if (classId == null ||
        section == null) {

      return Scaffold(

        appBar: AppBar(
          title: const Text(
            "Quick Attendance",
          ),
        ),

        body: const Center(

          child: Text(

            "You are not assigned\nas class teacher.",

            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        backgroundColor:
            Colors.white,

        elevation: 0,

        title: Text(
          "Class $classId - $section",
        ),
      ),

      bottomNavigationBar:
          _saveButton(),

      body: Column(

        children: [

          _topCard(),

          _summaryCard(),

          _quickActions(),

          Expanded(
            child:
                _studentsList(),
          ),
        ],
      ),
    );
  }

  Widget _topCard() {

    final now = DateTime.now();

    return Container(

      margin:
          const EdgeInsets.all(
        16,
      ),

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

      child: Row(

        children: [

          const Icon(

            Icons.calendar_month,

            color: Colors.white,

            size: 42,
          ),

          const SizedBox(width: 16),

          Expanded(

            child: 
            
            Row(

  mainAxisAlignment:
      MainAxisAlignment
          .spaceBetween,

  children: [

    Column(

      crossAxisAlignment:
          CrossAxisAlignment
              .start,

      children: [

        Text(

          "Class $classId - $section",

          style:
              const TextStyle(

            color:
                Colors.white,

            fontSize: 20,

            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(

          "${now.day}/${now.month}/${now.year}",

          style:
              const TextStyle(

            color:
                Colors.white70,

            fontSize: 14,
          ),
        ),
      ],
    ),

    Container(

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),

      decoration: BoxDecoration(

        color:
            Colors.white24,

        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),

      child: Text(

        "${todayPercentage.toStringAsFixed(0)}% Today",

        style: const TextStyle(

          color: Colors.white,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    ),
  ],
),
          ),
        ],
      ),
    );
  }


  Widget _summaryCard() {

    int present = 0;

    int absent = 0;





    attendanceMap.forEach(
      (key, value) {

        if (value == 'P') {
          present++;
        }

        if (value == 'A') {
          absent++;
        }
      },
    );







    return Container(

      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
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
      ),

      child: Row(

        mainAxisAlignment:
            MainAxisAlignment
                .spaceAround,

        children: [

          _summaryItem(
            "Present",
            present,
            Colors.green,
          ),

          _summaryItem(
            "Absent",
            absent,
            Colors.red,
          ),

          _summaryItem(
            "Total",
            attendanceMap.length,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int value,
    Color color,
  ) {

    return Column(

      children: [

        Text(

          value.toString(),

          style: TextStyle(

            fontSize: 24,

            fontWeight:
                FontWeight.bold,

            color: color,
          ),
        ),

        const SizedBox(height: 6),

        Text(title),
      ],
    );
  }

  Widget _quickActions() {

    return Padding(

      padding:
          const EdgeInsets.all(
        16,
      ),

      child: Row(

        children: [

          Expanded(

            child: ElevatedButton(

              onPressed:
                  _presentAll,

              child: const Text(
                "Present All",
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(

            child: ElevatedButton(

              onPressed:
                  _absentAll,

              child: const Text(
                "Absent All",
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(

            child: ElevatedButton(

              onPressed:
                  _holidayAll,

              child: const Text(
                "Holiday",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentsList() {

    if (isHoliday) {

      return const Center(

        child: Text(

          "Holiday Marked",

          style: TextStyle(

            fontSize: 22,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore
          .instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')

          .where(
            'classId',
            isEqualTo: classId,
          )

          .where(
            'section',
            isEqualTo: section,
          )

          .snapshots(),

     
     
     
     
     builder: (
  context,
  snapshot,
) {

  if (snapshot.hasError) {

    return Center(
      child: Text(
        snapshot.error.toString(),
      ),
    );
  }


if (!snapshot.hasData) {

  return const Center(
    child:
        CircularProgressIndicator(),
  );
}



  final docs =
      snapshot.data!.docs;


docs.sort((a, b) {

  final aName =
      (a['name'] ?? '')
          .toString();

  final bName =
      (b['name'] ?? '')
          .toString();

  return aName.compareTo(
      bName);
});


studentDocs = docs;



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

            final studentId =
                doc.id;

            attendanceMap
                .putIfAbsent(
              studentId,
              () => 'P',
            );

            final status =
                attendanceMap[
                    studentId];

            return Container(

              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),

              padding:
                  const EdgeInsets.all(
                16,
              ),

              decoration:
                  BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              child: Row(

                children: [




            CircleAvatar(

  radius: 24,

  backgroundColor:
      Colors.grey.shade200,

  backgroundImage:

      data['photoUrl'] != null &&
              data['photoUrl']
                  .toString()
                  .isNotEmpty

          ? NetworkImage(
              data['photoUrl'],
            )

          : null,

  child:

      data['photoUrl'] == null ||

              data['photoUrl']
                  .toString()
                  .isEmpty

          ? Text(

              (data['name'] ?? '')
                  .toString()
                  .substring(0, 1),
            )

          : null,
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
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          data['admissionNo'] ??
                              '',
                        ),
                      ],
                    ),
                  ),

                  _statusButton(
                    title: "P",
                    selected:
                        status == 'P',
                    color:
                        Colors.green,
                    onTap: () {

                      setState(() {

                        attendanceMap[
                                studentId] =
                            'P';
                             isHoliday = false;
_updatePercentage();


                      });
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _statusButton(
                    title: "A",
                    selected:
                        status == 'A',
                    color:
                        Colors.red,
                    onTap: () {

                      setState(() {

                        attendanceMap[
                                studentId] =
                            'A';
 isHoliday = false;

    _updatePercentage();


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

  Widget _statusButton({

    required String title,

    required bool selected,

    required Color color,

    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        height: 44,
        width: 44,

        decoration: BoxDecoration(

          color: selected
              ? color
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border: Border.all(
            color: color,
          ),
        ),

        child: Center(

          child: Text(

            title,

            style: TextStyle(

              fontWeight:
                  FontWeight.bold,

              color: selected
                  ? Colors.white
                  : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {

    return SafeArea(

      child: Padding(

        padding:
            const EdgeInsets.all(
          16,
        ),

        child: SizedBox(

          height: 58,

          child: ElevatedButton(

            onPressed:
                _saveAttendance,

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

            child: const Text(

              "SAVE ATTENDANCE",

              style: TextStyle(

                fontSize: 16,

                fontWeight:
                    FontWeight.bold,

                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }


void _presentAll() {

  setState(() {

    for (final doc
        in studentDocs) {

      attendanceMap[
          doc.id] = 'P';
    }

    isHoliday = false;

    _updatePercentage();
  });
}





void _absentAll() {

  setState(() {

    for (final doc
        in studentDocs) {

      attendanceMap[
          doc.id] = 'A';
    }

    isHoliday = false;

    _updatePercentage();
  });
}



void _holidayAll() {

  setState(() {

    for (final doc
        in studentDocs) {

      attendanceMap[
          doc.id] = 'H';
    }

    isHoliday = true;

    todayPercentage = 0;
  });
}




void _updatePercentage() {

  int present = 0;

  attendanceMap.forEach(
    (key, value) {

      if (value == 'P') {
        present++;
      }
    },
  );

  todayPercentage =
      attendanceMap.isEmpty

          ? 0

          : (present /
                  attendanceMap.length) *
              100;
}




  Future<void>
      _saveAttendance()
      
      
           
      
      
       async {


if (DateTime.now().weekday ==
    DateTime.sunday) {

  return;
}


    final exists =
        await _service
            .attendanceExists(
              

      schoolId:
          widget.schoolId,

      classId: classId!,

      section: section!,

      date: DateTime.now(),
    );

    
    bool updated = false;

if (exists) {

  updated = true;
}










    int present = 0;

    int absent = 0;

    attendanceMap.forEach(
      (key, value) {

        if (value == 'P') {
          present++;
        }

        if (value == 'A') {
          absent++;
        }
      },
    );

if (isHoliday) {

  present = 0;

  absent = 0;
}


todayPercentage =
    attendanceMap.isEmpty

        ? 0

        : (present /
                attendanceMap.length) *
            100;



    final attendance =
        AttendanceModel(

      schoolId:
          widget.schoolId,

      classId: classId!,

      section: section!,

      teacherId:
          widget.teacherId,

      date:
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",

      isHoliday:
          isHoliday,

      students:
          attendanceMap,

      totalStudents:
          attendanceMap.length,

      presentCount:
          present,

      absentCount:
          absent,
    );

    await _service
        .saveAttendance(
      attendance: attendance,
    );

    if (!mounted) return;

   ScaffoldMessenger.of(context)
    .showSnackBar(

  SnackBar(

    backgroundColor:
        Colors.green,

    behavior:
        SnackBarBehavior.floating,

    content: Text(

      updated

          ? "Attendance updated successfully"

          : "Attendance saved successfully",

      style: const TextStyle(
        color: Colors.white,
      ),
    ),
  ),

);
  }
}