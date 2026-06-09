import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditAttendanceScreen extends StatefulWidget {

  final String schoolId;
  final String classId;
  final String sectionId;

  const EditAttendanceScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.sectionId,
  });

  @override
  State<EditAttendanceScreen> createState() =>
      _EditAttendanceScreenState();
}

class _EditAttendanceScreenState
    extends State<EditAttendanceScreen> {


DateTime selectedDate = DateTime.now();


  bool loading = false;


  Map<String, dynamic> attendanceData = {};
Map<String, Map<String, dynamic>> studentsData = {};


Future<void> loadStudentNames() async {

  final snapshot =
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .get();

 studentsData.clear();

for (final doc in snapshot.docs) {

  final data = doc.data();

  final studentId = doc.id;

  studentsData[studentId] = {

    'name': data['name'] ?? '',
    'photoUrl': data['photoUrl'] ?? '',
  };
}

  setState(() {});
}






  String get classKey =>
      "${widget.classId}_${widget.sectionId}";

 String get dateKey =>
    DateFormat('yyyy-MM-dd')
        .format(selectedDate);



        String get displayDate =>
    DateFormat('dd/MM/yyyy')
        .format(selectedDate);


        

  Future<void> pickDate() async {

    final picked = await showDatePicker(

      context: context,

      initialDate: selectedDate,

      firstDate: DateTime(2025),

      lastDate: DateTime.now(),
    );

    if (picked != null) {

      setState(() {
        selectedDate = picked;
      });

      loadAttendance();
    }
  }




  Future<void> loadAttendance() async {

    setState(() {
      loading = true;
    });

    attendanceData.clear();

final snapshot =
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(dateKey)
        .collection('classes')
        .doc(classKey)
        .get();

  

if (snapshot.exists) {

  final data = snapshot.data()!;

  final students =
      Map<String, dynamic>.from(
    data['students'] ?? {},
  );

  attendanceData = students;
}



    setState(() {
      loading = false;
    });
  }

  Future<void> updateAttendance(
  String studentId,
  String newStatus,
) async {

  await FirebaseFirestore.instance

      .collection('schools')

      .doc(widget.schoolId)

      .collection('attendance')

      .doc(dateKey)

      .collection('classes')

      .doc(classKey)

      .update({

    'students.$studentId':
    newStatus == 'present'
        ? 'P'
        : newStatus == 'absent'
            ? 'A'
            : 'L',

    'editedAt': Timestamp.now(),
  });

  ScaffoldMessenger.of(context).showSnackBar(

    const SnackBar(
      content: Text(
        'Attendance Updated',
      ),
    ),
  );
}




Future<void> markHoliday() async {

  final Map<String, dynamic>
      holidayData = {};

  attendanceData.forEach(
    (key, value) {
      holidayData[key] = 'L';
    },
  );

  await FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('attendance')
      .doc(dateKey)
      .collection('classes')
      .doc(classKey)
      .update({

    'students': holidayData,

    'isHoliday': true,

    'editedAt': Timestamp.now(),
  });

  setState(() {
    attendanceData = holidayData;
  });

  ScaffoldMessenger.of(context)
      .showSnackBar(

    const SnackBar(
      content:
          Text('Holiday Applied'),
    ),
  );
}




Widget _statusChip(
  String studentId,
  String value,
  String label,
  Color color,
  String currentStatus,
) {

  final selected =
      currentStatus == value;

  return InkWell(

    onTap: () async {

      setState(() {

        attendanceData[studentId] =
            value == 'present'
                ? 'P'
                : value == 'absent'
                    ? 'A'
                    : 'L';
      });

      await updateAttendance(
        studentId,
        value,
      );
    },

    child: Container(

      width: 30,
height: 30,

      alignment: Alignment.center,

      decoration: BoxDecoration(

        color: selected
            ? color
            : color.withOpacity(0.15),

        borderRadius:
    BorderRadius.circular(15),
      ),

      child: Text(

        label,

        style: TextStyle(
          color:
              selected
                  ? Colors.white
                  : color,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    ),
  );
}




  @override
  void initState() {
    super.initState();
    loadStudentNames();
    loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
  print('widget.classId = [34m${widget.classId}[0m');
  print('widget.sectionId = [34m${widget.sectionId}[0m');

    
    
    final sortedKeys = attendanceData.keys.toList();

sortedKeys.sort((a, b) {

 final nameA =
    studentsData[a]?['name'] ?? '';

final nameB =
    studentsData[b]?['name'] ?? '';




  return nameA.compareTo(nameB);
});
    
    
    return Scaffold(

      appBar: AppBar(
        title:
            const Text('Edit Attendance'),
      ),

      body: Column(

        children: [

          const SizedBox(height: 10),


Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
  ),

  child: Row(

    children: [

      Expanded(

        child: OutlinedButton(

          onPressed: pickDate,

          child: Text(
            displayDate,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(width: 10),

      ElevatedButton.icon(

        icon: const Icon(
          Icons.event_busy,
          size: 18,
        ),

        label: const Text(
          'Mark Holiday',
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),

        onPressed: () async {

          final confirm =
              await showDialog<bool>(

            context: context,

            builder: (context) =>
                AlertDialog(

              title: const Text(
                'Holiday',
              ),

              content: const Text(
                'Mark entire class as Holiday?',
              ),

              actions: [

                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        false,
                      ),
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        true,
                      ),
                  child:
                      const Text('Yes'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await markHoliday();
          }
        },
      ),
    ],
  ),
),




          const SizedBox(height: 10),

          if (loading)
            const Expanded(
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),

          if (!loading)

            Expanded(

              child: attendanceData.isEmpty

                  ? const Center(
                      child: Text(
                        'No Attendance Found',
                      ),
                    )
            





                  : ListView.builder(

                      itemCount:
                          attendanceData.length,




                      itemBuilder:
                          (context, index) {

                        final studentId =
    sortedKeys[index];

                     String status =
    attendanceData[studentId]
        .toString()
        .toUpperCase();

if (status == 'P') {
  status = 'present';
} else if (status == 'A') {
  status = 'absent';
} else if (status == 'L') {
  status = 'leave';
}


return Card(
  margin: const EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 4,
),

  child: ListTile(

    leading: SizedBox(
      width: 85,
      child: Row(
        children: [

        Container(
  width: 24,
  height: 24,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1),
    shape: BoxShape.circle,
  ),
  child: Text(
    '${index + 1}',
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
  ),
),



          const SizedBox(width: 8),

          CircleAvatar(
            radius: 18,
            backgroundImage:
                (studentsData[studentId]?['photoUrl'] ?? '')
                        .toString()
                        .isNotEmpty
                    ? NetworkImage(
                        studentsData[studentId]!['photoUrl'],
                      )
                    : null,

            child:
                (studentsData[studentId]?['photoUrl'] ?? '')
                        .toString()
                        .isEmpty
                    ? Text(
                        (studentsData[studentId]?['name'] ?? '?')
                            .toString()
                            .substring(0, 1),
                      )
                    : null,
          ),
        ],
      ),
    ),

    title: Text(
      studentsData[studentId]?['name'] ??
          studentId,

      style: const TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
),
    ),


subtitle: Text(
  studentId,
  style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 12,
  ),
),


    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        _statusChip(
          studentId,
          'absent',
          'A',
          Colors.red,
          status,
        ),

        const SizedBox(width: 4),

        _statusChip(
          studentId,
          'present',
          'P',
          Colors.green,
          status,
        ),

    

   
      
      
      
      
      
      
      ],
    ),
  ),
);

                          },
                  ),
            ),
        ],
      ),
    );
  }
}
