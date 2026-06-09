import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




class AttendanceGroupScreen
    extends StatefulWidget {

  final String group;
  final String schoolId;


const AttendanceGroupScreen({
  super.key,
  required this.group,
  required this.schoolId,
});

  @override
  State<AttendanceGroupScreen>
      createState() =>
          _AttendanceGroupScreenState();
}

class _AttendanceGroupScreenState
    extends State<
        AttendanceGroupScreen> {

final today =
    DateTime.now()
        .toIso8601String()
        .split('T')[0];


  String? selectedClass;
String? selectedSection;



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(
  widget.group,
),
      ),


body: SingleChildScrollView(

  padding: const EdgeInsets.all(16),

  child: Column(

    children: [

      Container(

        width: double.infinity,

        padding:
            const EdgeInsets.all(20),

        decoration: BoxDecoration(

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          gradient:
              const LinearGradient(

            colors: [

              Color(0xFF4F46E5),

              Color(0xFF7C3AED),
            ],
          ),
        ),

        child: const Column(

          children: [

            Text(

              'Overall Attendance',

              style: TextStyle(

                color: Colors.white70,

                fontSize: 16,
              ),
            ),

            SizedBox(
              height: 10,
            ),

            Text(

              '0%',

              style: TextStyle(

                color: Colors.white,

                fontSize: 42,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(
        height: 16,
      ),

      Row(

        children: [

          Expanded(

            child: _statCard(

              'Present Today',

              '0',

              Colors.green,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(

            child: _statCard(

              'Absent Today',

              '0',

              Colors.red,
            ),
          ),
        ],
      ),

      const SizedBox(
        height: 24,
      ),

    FutureBuilder(

  future: FirebaseFirestore.instance

      .collection('schools')

   .doc(
  widget.schoolId,
)

      .collection('classes')

    .where(
  'group',
  isEqualTo:

      widget.group ==
              'Primary Section'
          ? 'Primary'

          : widget.group ==
                  'Middle School'
              ? 'Middle'

              : widget.group,
)
      

     .get(),

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


docs.sort((a, b) {

  final classOrder = {
    'LKG': 1,
    'UKG': 2,
    'Class 1': 3,
    'Class 2': 4,
    'Class 3': 5,
    'Class 4': 6,
    'Class 5': 7,
    'Class 6': 8,
    'Class 7': 9,
    'Class 8': 10,
    'Class 9': 11,
    'Class 10': 12,
    'I-PU': 13,
    'II-PU': 14,
  };

  final nameA =
      a['name'].toString();

  final nameB =
      b['name'].toString();

  final orderA =
      classOrder[nameA] ?? 999;

  final orderB =
      classOrder[nameB] ?? 999;

  return orderA.compareTo(orderB);
});



    return 
   Wrap(

  spacing: 12,

  runSpacing: 12,

  children: docs.map((doc) {

    final className =
        doc['name'].toString();

    final selected =
        selectedClass ==
            className;

    return InkWell(

      borderRadius:
          BorderRadius.circular(
        16,
      ),

      onTap: () {

        setState(() {

          selectedClass =
              className;
        });
      },

      child: Container(

        width: 110,

        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),

        decoration: BoxDecoration(

          color: selected

              ? const Color(
                  0xFF6366F1,
                )

              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          boxShadow: [

            BoxShadow(

              color: Colors.black
                  .withOpacity(
                0.05,
              ),

              blurRadius: 10,
            ),
          ],
        ),

        child: Center(

          child: Text(

            className,

            style: TextStyle(

              color: selected
                  ? Colors.white
                  : Colors.black87,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );

  }).toList(),
);

    
  },),

    

if (selectedClass != null) ...[

  const SizedBox(height: 24),

  Container(

    width: double.infinity,

    padding: const EdgeInsets.all(20),

    decoration: BoxDecoration(

      color: Colors.white,

      borderRadius:
          BorderRadius.circular(20),

      boxShadow: [

        BoxShadow(

          color: Colors.black
              .withOpacity(0.05),

          blurRadius: 10,
        ),
      ],
    ),

    child: Column(

      children: [

        Text(

          selectedClass!,

          style: const TextStyle(

            fontSize: 20,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          "Attendance Today",
        ),

        const SizedBox(height: 12),

     if (selectedSection != null)

FutureBuilder<DocumentSnapshot>(

  future: FirebaseFirestore.instance

      .collection('schools')

      .doc(widget.schoolId)

      .collection('attendance')

      .doc(today)

      .collection('classes')

      .doc(

  "${selectedClass!
      .replaceAll('Class ', '')}_${selectedSection!}",
)

      .get(),

  builder: (
    context,
    snapshot,
  ) {


//-------------------
int present = 0;
int absent = 0;
int totalStudents = 0;

if (snapshot.hasData &&
    snapshot.data!.exists) {

  final data =
      snapshot.data!.data()
          as Map<String, dynamic>;

  present =
      data['presentCount'] ?? 0;

  absent =
      data['absentCount'] ?? 0;

  totalStudents =
      data['totalStudents'] ?? 0;
}





//--------------------







final total =
    totalStudents;

    final percent =
        total == 0

            ? 0

            : ((present /
                        total) *
                    100)
                .round();

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(

        children: [

          Text(

            selectedClass!,

            style:
                const TextStyle(

              fontSize: 20,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(

            '$percent%',

            style:
                const TextStyle(

              fontSize: 46,

              fontWeight:
                  FontWeight.bold,

              color: Color(
                0xFF6366F1,
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Row(

            children: [

              Expanded(

                child: _statCard(

                  'Present',

                  present.toString(),

                  Colors.green,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(

                child: _statCard(

                  'Absent',

                  absent.toString(),

                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
),
      
      
  const SizedBox(height: 20),

const Align(

  alignment: Alignment.centerLeft,

  child: Text(

    "Sections",

    style: TextStyle(

      fontSize: 18,

      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 12),

FutureBuilder<QuerySnapshot>(

  future: FirebaseFirestore.instance

      .collection('schools')

      .doc(widget.schoolId)

      .collection('classes')

      .where(
        'name',
        isEqualTo: selectedClass,
      )

      .limit(1)

      .get(),

  builder: (
    context,
    snapshot,
  ) {

    if (!snapshot.hasData) {

      return const CircularProgressIndicator();
    }

    if (snapshot.data!.docs.isEmpty) {

      return const Text(
        'No Sections Found',
      );
    }

    final data =
        snapshot.data!.docs.first.data()
            as Map<String, dynamic>;

    final sections =
        List<String>.from(
      data['sections'] ?? [],
    );

    return Wrap(

      spacing: 12,

      runSpacing: 12,

      children:
          sections.map((section) {

        return ChoiceChip(

          label: Text(section),

          selected:
              selectedSection ==
                  section,

          onSelected: (_) {

            setState(() {

              selectedSection =
                  section;
            });
          },
        );

      }).toList(),
    );
  },
),
      
      
      
      
      
      
      
      
      
      
      
      
      ],
    ),
  ),
]







    
    ],
  ),
),
    );
  }
}











Widget _statCard(

  String title,

  String value,

  Color color,
) {

  return Container(

    padding:
        const EdgeInsets.all(16),

    decoration: BoxDecoration(

      color:
          color.withOpacity(
        0.1,
      ),

      borderRadius:
          BorderRadius.circular(
        16,
      ),
    ),

    child: Column(

      children: [

        Text(
          title,
        ),

        const SizedBox(
          height: 8,
        ),

        Text(

          value,

          style: TextStyle(

            color: color,

            fontSize: 26,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}