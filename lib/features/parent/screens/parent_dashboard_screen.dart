import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'parent_announcements_screen.dart';
import 'parent_attendance_screen.dart';
import 'parent_homework_screen.dart';
import 'parent_marks_analytics_screen.dart';
import '../../student/screens/report_card_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String schoolId;
  final String parentId;
  final Map<String, dynamic> parentData;

  const ParentDashboardScreen({
    super.key,
    required this.schoolId,
    required this.parentId,
    required this.parentData,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final List<dynamic> studentIds = widget.parentData['studentIds'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Parent Dashboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff111827),
              ),
            ),
            Text(
              widget.parentData['name'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: studentIds.isEmpty
          ? _emptyState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('students')
                  .where(
                    FieldPath.documentId,
                    whereIn: studentIds,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs;

                if (students.isEmpty) {
                  return _emptyState();
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...students.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _studentCard(data, doc.id);
                    }).toList(),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentAnnouncementsScreen(
                              schoolId: widget.schoolId,
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
                                      color: Color(0xff111827),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "School notices & updates",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _studentCard(Map<String, dynamic> student, String studentId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xffEEF2FF),
                backgroundImage: student['photoUrl'] != null &&
                        student['photoUrl'].toString().isNotEmpty
                    ? NetworkImage(student['photoUrl'])
                    : null,
                child: student['photoUrl'] == null ||
                        student['photoUrl'].toString().isEmpty
                    ? Text(
                        (student['name'] ?? 'S').toString().substring(0, 1),
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
                      student['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${student['className']} • Section ${student['section']}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentAttendanceScreen(
                          schoolId: widget.schoolId,
                          studentId: studentId,
                          studentData: student,
                        ),
                      ),
                    );
                  },
                  child: _quickTile(
                    icon: Icons.check_circle,
                    title: "Attendance",
                    color: const Color(0xffDCFCE7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentMarksAnalyticsScreen(
                          schoolId: widget.schoolId,
                          studentId: studentId,
                          studentData: student,
                        ),
                      ),
                    );
                  },
                  child: _quickTile(
                    icon: Icons.assignment,
                    title: "Marks",
                    color: const Color(0xffDBEAFE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentHomeworkScreen(
                          schoolId: widget.schoolId,
                          studentId: studentId,
                          studentData: student,
                        ),
                      ),
                    );
                  },
                  child: _quickTile(
                    icon: Icons.menu_book,
                    title: "Homework",
                    color: const Color(0xffFEF3C7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportCardScreen(
                          schoolId: widget.schoolId,
                          studentId: studentId,
                        ),
                      ),
                    );
                  },
                  child: _quickTile(
                    icon: Icons.picture_as_pdf,
                    title: "Report Card",
                    color: const Color(0xffF3E8FF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xffEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Students Linked",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Student accounts linked to this\nparent will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
