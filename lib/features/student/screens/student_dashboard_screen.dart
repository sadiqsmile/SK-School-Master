import 'package:flutter/material.dart';

import '../../parent/screens/parent_announcements_screen.dart';
import '../../parent/screens/parent_attendance_screen.dart';
import '../../parent/screens/parent_homework_screen.dart';
import '../../parent/screens/parent_marks_analytics_screen.dart';
import '../../student/screens/report_card_screen.dart';
// import 'student_timetable_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  final String schoolId;
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDashboardScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Student Dashboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff111827),
              ),
            ),
            Text(
              studentData['name'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xffEEF2FF),
                  backgroundImage: studentData['photoUrl'] != null &&
                          studentData['photoUrl'].toString().isNotEmpty
                      ? NetworkImage(studentData['photoUrl'])
                      : null,
                  child: studentData['photoUrl'] == null ||
                          studentData['photoUrl'].toString().isEmpty
                      ? Text(
                          (studentData['name'] ?? 'S')
                              .toString()
                              .substring(0, 1),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff5B5FEF),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentData['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${studentData['className']} • Section ${studentData['section']}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.08,
            children: [
              _dashboardTile(
                context: context,
                title: "Attendance",
                icon: Icons.check_circle,
                color: const Color(0xffDCFCE7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentAttendanceScreen(
                        schoolId: schoolId,
                        studentId: studentId,
                        studentData: studentData,
                      ),
                    ),
                  );
                },
              ),
              _dashboardTile(
                context: context,
                title: "Homework",
                icon: Icons.menu_book,
                color: const Color(0xffFEF3C7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentHomeworkScreen(
                        schoolId: schoolId,
                        studentId: studentId,
                        studentData: studentData,
                      ),
                    ),
                  );
                },
              ),
              _dashboardTile(
                context: context,
                title: "Marks",
                icon: Icons.analytics,
                color: const Color(0xffDBEAFE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentMarksAnalyticsScreen(
                        schoolId: schoolId,
                        studentId: studentId,
                        studentData: studentData,
                      ),
                    ),
                  );
                },
              ),
              _dashboardTile(
                context: context,
                title: "Report Card",
                icon: Icons.picture_as_pdf,
                color: const Color(0xffF3E8FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportCardScreen(
                        schoolId: schoolId,
                        studentId: studentId,
                      ),
                    ),
                  );
                },
              ),
              _dashboardTile(
                context: context,
                title: "Timetable",
                icon: Icons.schedule,
                color: const Color(0xffEEF2FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentTimetableScreen(
                        schoolId: schoolId,
                        classId: studentData['classId'],
                        section: studentData['section'],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParentAnnouncementsScreen(
                    schoolId: schoolId,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xffEEF2FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: Color(0xff5B5FEF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Announcements",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text("School notices & updates"),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
