import 'package:flutter/material.dart';

import 'attendance_group_screen.dart';

class AttendanceReportsHomeScreen
    extends StatelessWidget {

  final String schoolId;

  const AttendanceReportsHomeScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(

backgroundColor:
    const Color(0xFFF5F7FB),



      appBar: AppBar(
        title: const Text(
          'Attendance Reports',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
    
    


crossAxisCount:
    MediaQuery.of(context)
                .size
                .width >
            1200
        ? 4
        : MediaQuery.of(context)
                    .size
                    .width >
                700
            ? 3
            : 2,





childAspectRatio: 1.15,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,

          children: [

            _groupCard(
              context,
               'Primary Section',
              Icons.school,
            ),

            _groupCard(
              context,
              'Middle School',
              Icons.menu_book,
            ),

            _groupCard(
              context,
              'High School',
              Icons.groups,
            ),

            _groupCard(
              context,
              'College',
              Icons.account_balance,
            ),
          ],
        ),
      ),
    );
  }


Widget _groupCard(
  BuildContext context,
  String group,
  IconData icon,
) {

  Color startColor;
  Color endColor;

  switch (group) {

    case 'Primary Section':
      startColor = const Color(0xFF4338CA);
endColor = const Color(0xFF7C3AED);
      break;

    case 'Middle School':
      startColor = const Color(0xFF0284C7);
endColor = const Color(0xFF06B6D4);
      break;

    case 'High School':
      startColor = const Color(0xFFEA580C);
      endColor = const Color(0xFFF97316);
      break;

    default:
      startColor = const Color(0xFF16A34A);
endColor = const Color(0xFF22C55E);
  }

  return InkWell(

    borderRadius:
        BorderRadius.circular(18),

    onTap: () {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (_) =>
             AttendanceGroupScreen(
  group: group,
  schoolId: schoolId,
)
        ),
      );
    },

    child: Container(

      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(24),

        gradient: LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            startColor,
            endColor,
          ],
        ),

        boxShadow: [

          BoxShadow(

            color:
                startColor.withOpacity(
              0.35,
            ),

           blurRadius: 25,
spreadRadius: 1,

            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

    

     child: Padding(
  padding: const EdgeInsets.all(8),

    child: Column(

  mainAxisAlignment:
      MainAxisAlignment.center,

  crossAxisAlignment:
      CrossAxisAlignment.center,

          children: [


//---change----
Container(

  padding:
      const EdgeInsets.all(10),

  decoration: BoxDecoration(

    color: Colors.white.withOpacity(
      0.10,
    ),

    borderRadius:
        BorderRadius.circular(
      14,
    ),
  ),

  child: Icon(

    icon,

    color: Colors.white,

    size: 26,
  ),
),

const SizedBox(
  height: 12,
),

Text(

  group,

  textAlign:
      TextAlign.center,

  style: const TextStyle(

    color: Colors.white,

    fontSize: 16,

    fontWeight:
        FontWeight.bold,
  ),
),





          ],
        ),
      ),
    ),
  );
}

}