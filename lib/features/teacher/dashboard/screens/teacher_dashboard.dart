import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ ADD THIS IMPORT
import 'package:go_router/go_router.dart';
import 'package:school_app/features/teacher/screens/teacher_profile_screen.dart';

import 'package:school_app/features/teacher/screens/analytics_dashboard_screen.dart';
import 'package:school_app/features/teacher/screens/attendance_screen.dart';
import 'package:school_app/features/teacher/screens/attendance_calendar_screen.dart';
import 'package:school_app/features/teacher/screens/student_history_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String teacherName = "";
  String email = "";
  String schoolId = "";
  String className = "";
  String section = "";

  int present = 0;
  int absent = 0;

  @override
  void initState() {
    super.initState();
    loadTeacherData();
  }

  Future<void> loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    email = user.email ?? "";

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) return;

    schoolId = userData['schoolId'] ?? "";
    final teacherId = userData['teacherId'];

    final teacherDoc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(teacherId)
        .get();

    final data = teacherDoc.data();
    if (data != null) {
      teacherName = data['name'] ?? "";

      final keys = List<String>.from(data['assignmentKeys'] ?? []);

      if (keys.isNotEmpty) {
        final key = keys.first;
        final parts = key.split('_');
        if (parts.length == 2) {
          className = parts[0].replaceAll("Class ", "").trim();
          section = parts[1].trim();
        }
      }
    }

    await loadTodayAttendance();
    setState(() {});
  }

  Future<void> loadTodayAttendance() async {
    if (schoolId.isEmpty || className.isEmpty) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final docId = "${className}_${section}_$today";

    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(docId)
        .get();

    if (!doc.exists) {
      present = 0;
      absent = 0;
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final students = Map<String, dynamic>.from(data['students'] ?? {});

    present = students.values.where((e) => e == 'P').length;
    absent = students.values.where((e) => e == 'A').length;
  }

  /// 🔥 UPDATED PROFILE HEADER (CLICKABLE)
  Widget profileHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 🔥 IMPORTANT FIX
      onTap: () {
        print("Profile tapped"); // debug

        // ✅ GoRouter navigation
        context.push('/teacher/profile');
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget todayCard() {
    int total = present + absent;
    double percent = total == 0 ? 0 : (present / total) * 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "Today Attendance",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0 ? "No Data" : "${percent.toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("P: $present", style: const TextStyle(color: Colors.green)),
              Text("A: $absent", style: const TextStyle(color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  Widget actionButton(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Dashboard")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            profileHeader(),
            todayCard(),
            const SizedBox(height: 12),

            Row(
              children: [
                actionButton("Attendance", Icons.check, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceScreen(
                        schoolId: schoolId,
                        className: className,
                        section: section,
                      ),
                    ),
                  );
                }),
                actionButton("Calendar", Icons.calendar_month, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceCalendarScreen(
                        schoolId: schoolId,
                        className: className,
                        section: section,
                      ),
                    ),
                  );
                }),
              ],
            ),

            Row(
              children: [
                actionButton("Analytics", Icons.analytics, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsDashboardScreen(
                        schoolId: schoolId,
                        className: className,
                        section: section,
                      ),
                    ),
                  );
                }),
                actionButton("Students", Icons.people, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentHistoryScreen(
                        schoolId: schoolId,
                        className: className,
                        section: section,
                      ),
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}